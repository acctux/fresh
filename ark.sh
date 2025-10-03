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
#
check_git() {
  if [[ ! -d ~/fresh ]]; then
    pacman -Sy archlinux-keyring
    pacman -S --needed git
    git clone https://github.com/acctux/fresh.git ~/fresh
  fi
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

pac_prep() {
  iso=$(curl -4 ifconfig.co/country-iso)

  pacman -S --noconfirm archlinux-keyring # update keyrings to prevent package install failures
  pacman -S --noconfirm --needed pacman-contrib

  sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
  info "Updating reflector mirrors."
  reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
}

make_mnt_dir() {
  echo "making mount directory"
  mkdir /mnt &>/dev/null || true
  echo "mount directory created"
}

create_partitions() {
  # Disk prep
  sgdisk -Z ${DISK}         # Zap all on disk
  sgdisk -a 2048 -o ${DISK} # New GPT disk with 2048 alignment

  # Create partitions
  sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK}  # BIOS Boot Partition
  sgdisk -n 2::+600M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # UEFI Boot Partition
  sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK}       # Root Partition, remaining space
  if [[ ! -d "/sys/firmware/efi" ]]; then                                # Check for BIOS system
    sgdisk -A 1:set:2 ${DISK}
  fi
  # Reread partition table
  partprobe ${DISK}
}

mount_filesystems() {
  if [[ "${DISK}" =~ "nvme" ]]; then
    partition2=${DISK}p2
    partition3=${DISK}p3
  else
    partition2=${DISK}2
    partition3=${DISK}3
  fi

  mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
  mkfs.btrfs -L ROOT ${partition3} -f
  mount -t btrfs ${partition3} /mnt

  # Create btrfs subvolumes
  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@home
  btrfs subvolume create /mnt/@var
  btrfs subvolume create /mnt/@tmp
  btrfs subvolume create /mnt/@.snapshots

  # Set up btrfs subvolumes and mount
  umount /mnt
  mount -o ${MOUNT_OPTIONS},subvol=@ ${partition3} /mnt
  mkdir -p /mnt/{home,var,tmp,.snapshots}

  # Mount btrfs subvolumes
  mount -o ${MOUNT_OPTIONS},subvol=@home ${partition3} /mnt/home
  mount -o ${MOUNT_OPTIONS},subvol=@tmp ${partition3} /mnt/tmp
  mount -o ${MOUNT_OPTIONS},subvol=@var ${partition3} /mnt/var
  mount -o ${MOUNT_OPTIONS},subvol=@.snapshots ${partition3} /mnt/.snapshots

  # Mount EFI partition
  mkdir -p /mnt/boot/efi
  mount -t vfat -L EFIBOOT /mnt/boot/efi
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
  check_git

  get_disk_selection

  timedatectl set-ntp true

  pac_prep
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
