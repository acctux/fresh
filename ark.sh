#!/bin/bash

# -------------------------------------------------------------------------

# ███╗   ██╗  ██████╗   █████╗  ██╗  ██╗  ██████╗     █████╗  ██████╗   ██████╗ ██╗  ██╗
# ████╗  ██║ ██╔═══██╗ ██╔══██╗ ██║  ██║ ██╔════╝    ██╔══██╗ ██╔══██╗ ██╔════╝ ██║  ██║
# ██╔██╗ ██║ ██║   ██║ ███████║ ███████║ ╚█████╗     ███████║ ██████╔╝ ██║      ███████║
# ██║╚██╗██║ ██║   ██║ ██╔══██║ ██╔══██║  ╚═══██╗    ██╔══██║ ██╔══██╗ ██║      ██╔══██║
# ██║ ╚████║ ╚██████╔╝ ██║  ██║ ██║  ██║ ██████╔╝    ██║  ██║ ██║  ██║ ╚██████╗ ██║  ██║
# ╚═╝  ╚═══╝  ╚═════╝  ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝  ╚═╝ ╚═╝  ╚═╝  ╚═════╝ ╚═╝  ╚═╝

# -------------------------------------------------------------------------
# The one-opinion opinionated automated Arch Linux Installer
# -------------------------------------------------------------------------

pac_prep() {
  pacman -Sy --noconfirm archlinux-keyring
  iso=$(curl -4 ifconfig.co/country-iso)

  pacman -S --noconfirm --needed pacman-contrib

  sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
  info "Updating reflector mirrors."
  reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
}

get_disk_selection() {
  info "Detecting available disks..."
  local disks=()
  local labels=()

  while IFS= read -r line; do
    line="${line% disk}"
    local name size model
    name=$(awk '{print $1}' <<<"$line")
    size=$(awk '{print $2}' <<<"$line")
    model=$(cut -d' ' -f3- <<<"$line")
    if [[ -b "/dev/$name" ]]; then
      disks+=("/dev/$name")
      labels+=("$name ($size) - $model")
    fi
  done < <(lsblk -dn -o NAME,SIZE,MODEL,TYPE | grep 'disk$')

  if [[ ${#disks[@]} -eq 0 ]]; then
    fatal "No suitable disks found"
  fi

  local selection
  selection=$(select_from_menu "Available disks:" "${labels[@]}")
  local index
  for i in "${!labels[@]}"; do
    if [[ "${labels[i]}" == "$selection" ]]; then
      index="$i"
      break
    fi
  done
  DISK="${disks[$index]}"
  info "Selected disk: $DISK (${labels[$index]})"
}

make_mnt_dir() {
  echo "making mount directory"
  mkdir /mnt &>/dev/null || true
  echo "mount directory created"
}

create_partitions() {
  # - EFI_SIZE: 600M for UEFI (300–600M recommended) 1M for GRUB on BIOS systems.
  : "${EFI_SIZE:=500M}" "${BIOS_BOOT_SIZE:=1M}"
  [[ -b "$DISK" ]] || {
    echo "Error: Invalid disk $DISK"
    return 1
  }
  # - sgdisk -Z clears GPT/MBR; sufficient for 2024+ systems.
  sgdisk -Z "$DISK" || {
    echo "Error: Failed to wipe $DISK"
    return 1
  }
  # Logic: Initialize GPT with 2048-sector alignment for SSD/NVMe performance.
  # - 1 MiB alignment is standard in 2024+ for modern storage.
  sgdisk -a 2048 -o "$DISK" || {
    echo "Error: Failed to set GPT"
    return 1
  }
  # Logic: Create partitions dynamically, starting with partition 1.
  local part=1
  # - 1M, type ef02, named BIOSBOOT; sets legacy boot attribute for GRUB.
  if [[ ! -d "/sys/firmware/efi" ]]; then
    sgdisk -n $part::+"$BIOS_BOOT_SIZE" --typecode=$part:ef02 --change-name=$part:'BIOSBOOT' "$DISK" || {
      echo "Error: Failed to create BIOS boot partition"
      return 1
    }
    sgdisk -A $part:set:2 "$DISK" || {
      echo "Error: Failed to set BIOS boot attribute"
      return 1
    }
    ((part++))
  fi
  # Logic: Create EFI partition for UEFI systems (standard in 2024+).
  # - 600M (or user-defined), type ef00, named EFIBOOT for bootloader.
  sgdisk -n $part::+"$EFI_SIZE" --typecode=$part:ef00 --change-name=$part:'EFIBOOT' "$DISK" || {
    echo "Error: Failed to create EFI partition"
    return 1
  }
  ((part++))
  # Logic: Create root partition with all remaining space.
  sgdisk -n $part::-0 --typecode=$part:8300 --change-name=$part:'ROOT' "$DISK" || {
    echo "Error: Failed to create root partition"
    return 1
  }
  # - partprobe ensures partitions are recognized for formatting.
  partprobe "$DISK" || {
    echo "Error: Failed to update partition table"
    return 1
  }
  echo "Partitions created successfully"
}

partition_prefix() {
  local disk="$1"
  if [[ "$disk" =~ (nvme|mmcblk|loop) ]]; then
    echo "${disk}p"
  else
    echo "$disk"
  fi
}

format_partitions() {
  info "Formatting partitions"
  local prefix
  prefix=$(partition_prefix "$DISK")
  local efi_partition="${prefix}1"
  local root_partition="${prefix}2"
  mkfs.fat -F32 "$efi_partition"
  mkfs.btrfs -f "$root_partition"
  success "Partitions formatted successfully"
}

mount_filesystems() {
  info "Mounting filesystems"
  local prefix
  prefix=$(partition_prefix "$DISK")

  local efi_partition="${prefix}1"
  local root_partition="${prefix}2"

  mount "$root_partition" /mnt
  mkdir -p /mnt/boot
  mount "$efi_partition" /mnt/boot

  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@home
  btrfs subvolume create /mnt/@log
  btrfs subvolume create /mnt/@pkg

  umount /mnt/boot
  umount /mnt

  mount -o subvol=@,$MOUNT_OPTIONS "$root_partition" /mnt

  mkdir -p /mnt/home /mnt/var/log /mnt/var/cache/pacman/pkg
  mount -o subvol=@home,$MOUNT_OPTIONS "$root_partition" /mnt/home
  mount -o subvol=@log,$MOUNT_OPTIONS "$root_partition" /mnt/var/log
  mount -o subvol=@pkg,$MOUNT_OPTIONS "$root_partition" /mnt/var/cache/pacman/pkg

  mkdir -p /mnt/boot
  mount "$efi_partition" /mnt/boot
  success "Filesystems mounted successfully"
}

verify_mount() {
  if ! grep -qs '/mnt' /proc/mounts; then
    echo "Drive is not mounted, cannot continue"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now
  fi
}

pacstrap_init() {
  pacstrap /mnt \
    amd-ucode \
    base \
    base-devel \
    btrfs-progs \
    linux \
    reflector \
    linux-firmware \
    neovim-lspconfig
  echo "keyserver hkp://keyserver.ubuntu.com" >>/mnt/etc/pacman.d/gnupg/gpg.conf
  cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
}

generate_fstab() {
  genfstab -L /mnt >>/mnt/etc/fstab
  echo "
    Generated /etc/fstab:
    "
  cat /mnt/etc/fstab
}

check_bios() {
  if [[ ! -d "/sys/firmware/efi" ]]; then
    grub-install --boot-directory=/mnt/boot ${DISK}
  else
    pacstrap /mnt efibootmgr --noconfirm --needed
  fi
}

regional_settings() {
  # Timezone & LOCALE
  ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
  hwclock --systohc
  echo "$LOCALE UTF-8" >>"/mnt/etc/locale.gen"
  arch-chroot "/mnt" locale-gen
  echo "LANG=$LOCALE" >"/mnt/etc/locale.conf"
}

set_hostname() {
  # Hostname & hosts file
  echo "$HOSTNAME" >"/mnt/etc/hostname"
  cat >"/mnt/etc/hosts" <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF
  success "System configuration completed"
}

configure_bootloader() {
  info "Configuring systemd boot"
  local prefix
  prefix=$(partition_prefix "$DISK")
  local root_uuid
  root_uuid=$(blkid -s UUID -o value "${prefix}3")

  arch-chroot "/mnt" bootctl --path=/boot install
  cat >"/mnt/boot/loader/loader.conf" <<EOF
default arch.conf
timeout 1
EOF
  cat >"/mnt/boot/loader/entries/arch.conf" <<EOF
title   Arch Linux
linux   /vmlinuz-linux
EOF

  echo "initrd /$CPU_MAN-ucode.img" >>"/mnt/boot/loader/entries/arch.conf"
  echo "initrd /initramfs-linux.img" >>"/mnt/boot/loader/entries/arch.conf"
  echo "options root=UUID=$root_uuid rw rootflags=subvol=@" >>"/mnt/boot/loader/entries/arch.conf"
  success "Systemd-boot configured."
}

ark() {
  timedatectl set-ntp true

  pac_prep
  get_disk_selection
  make_mnt_dir
  create_partitions
  mount_filesystems
  verify_mount
  pacstrap_init

  cp -R ${SCRIPT_DIR} /mnt/root/fresh

  generate_fstab
  check_bios
  regional_settings
  set_hostname
  configure_bootloader
}
