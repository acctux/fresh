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
readonly LOG_FILE="/tmp/noah.log"

readonly USERNAME="nick"
readonly HOSTNAME="arch"
readonly EFI_SIZE="512M"

SCRIPT_DIR="$(dirname "$0")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
info() { printf "${BLUE}[INFO]${NC} %s\n" "$*" | tee -a "$LOG_FILE"; }
success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$*" | tee -a "$LOG_FILE"; }
warning() { printf "${YELLOW}[WARNING]${NC} %s\n" "$*" | tee -a "$LOG_FILE"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*" | tee -a "$LOG_FILE"; }

fatal() {
  error "$*"
  exit 1
}

unmount_mounted() {
  info "Unmounting filesystems"
  if mountpoint -q "mnt/boot"; then
    umount "/mnt/boot" || error "Failed to unmount mnt/boot"
  fi
  for sub in home var/log var/cache/pacman/pkg; do
    if mountpoint -q "mnt/$sub"; then
      umount "/mnt/$sub" || error "Failed to unmount /mnt/$sub"
    fi
  done
  if ! umount -R "/mnt"; then
    error "No mount exists or failed."
  fi
  success "Filesystems unmounted successfully"
}

pac_prep() {
  pacman -S --noconfirm --needed pacman-contrib

  sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
  info "Updating reflector mirrors."

  iso=$(curl -4 ifconfig.co/country-iso)
  reflector --country $iso \
    --protocol https \
    --completion-percent 100 \
    --latest 20 \
    --sort rate \
    --threads 8 \
    --download-timeout 3 \
    --save /etc/pacman.d/mirrorlist
}

validate_disk() {
  local disk="$1"
  if [[ ! -b "$disk" ]]; then
    fatal "Disk $disk does not exist or is not a block device"
  fi

  if [[ $(lsblk -dn -o TYPE "$disk") != "disk" ]]; then
    fatal "Target $disk is not a disk device"
  fi

  if lsblk -rno MOUNTPOINT "$disk" | grep -qE '\S'; then
    fatal "Disk $disk has mounted partitions. Please unmount them before proceeding."
  fi

  success "Disk $disk validated"
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

  # Inline menu selection logic
  local prompt="Available disks:"
  local num="${#labels[@]}"
  local choice selection index

  while true; do
    info "$prompt"
    for i in "${!labels[@]}"; do
      printf '%d) %s\n' "$((i + 1))" "${labels[i]}"
    done
    if ! read -rp "Select an option (1-${num}): " choice </dev/tty; then
      fatal "Input aborted"
    fi
    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= num)); then
      selection="${labels[$((choice - 1))]}"
      index=$((choice - 1))
      break
    fi
    warning "Invalid choice. Please select a number between 1 and ${num}."
  done

  DISK="${disks[$index]}"
  info "Selected disk: $DISK (${labels[$index]})"

  validate_disk "$DISK"
}
do_the_disk() {
    mkdir -p /mnt
    sgdisk -Z ${DISK} # zap all on disk
    sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

    # create partitions
    sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # partition 1 (BIOS Boot Partition)
    sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # partition 2 (UEFI Boot Partition)
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # partition 3 (Root), default start, remaining
    if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
        sgdisk -A 1:set:2 ${DISK}
    fi
    partprobe ${DISK} # reread partition table to ensure it is correct
}
setup_btrfs_filesystem () {
    local disk=$1
    local mount_options=$2  # Assumes MOUNT_OPTIONS is passed as a parameter

    # Determine partition names based on disk type (NVMe or not)
    local partition2
    local partition3
    if [[ "${disk}" =~ "nvme" ]]; then
        partition2="${disk}p2"
        partition3="${disk}p3"
    else
        partition2="${disk}2"
        partition3="${disk}3"
    fi

    # Create filesystems
    mkfs.vfat -F32 -n "EFIBOOT" "${partition2}"
    mkfs.btrfs -L ROOT "${partition3}" -f

    # Mount root partition temporarily to create subvolumes
    mount -t btrfs "${partition3}" /mnt

    # Create BTRFS subvolumes
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@var/log
    btrfs subvolume create /mnt/@var/cache/pacman/pkg

    # Unmount root to remount with subvolume
    umount /mnt

    # Mount @ subvolume
    mount -o "${mount_options},subvol=@" "${partition3}" /mnt

    # Create mount point directories
    mkdir -p /mnt/{home,var,tmp,.snapshots}
    mkdir -p /mnt/var/{log,cache/pacman/pkg}

    # Mount other subvolumes
    mount -o "${mount_options},subvol=@home" "${partition3}" /mnt/home
    mount -o "${mount_options},subvol=@var" "${partition3}" /mnt/var
    mount -o "${mount_options},subvol=@var/log" "${partition3}" /mnt/var/log
    mount -o "${mount_options},subvol=@var/cache/pacman/pkg" "${partition3}" /mnt/var/cache/pacman/pkg
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
  unmount_mounted
  timedatectl set-ntp true

  pac_prep
  get_disk_selection
  
  do_the_disk
  setup_btrfs_filesystem
  pacstrap_init

  cp -R $SCRIPT_DIR /mnt/root/fresh
  generate_fstab
  check_bios
  regional_settings
  set_hostname
  configure_bootloader
}
ark
