#!/bin/bash

readonly LOG_FILE="/tmp/noah.log"

readonly USERNAME="nick"
readonly HOSTNAME="arch"
readonly EFI_SIZE="512M"

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
select_from_menu() {
  # Generic menu selection helper
  local prompt="$1"
  shift
  local options=("$@")
  local num="${#options[@]}"
  local choice
  while true; do
    info "$prompt" >&2
    for i in "${!options[@]}"; do
      printf '%d) %s\n' "$((i + 1))" "${options[i]}" >&2
    done
    if ! read -rp "Select an option (1-${num}): " choice; then
      fatal "Input aborted"
    fi
    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= num)); then
      echo "${options[$((choice - 1))]}"
      return 0
    fi
    warning "Invalid choice. Please select a number between 1 and ${num}." >&2
  done
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
  validate_disk "$DISK"
}

partition_prefix() {
  local disk="$1"
  if [[ "$disk" =~ (nvme|mmcblk|loop) ]]; then
    echo "${disk}p"
  else
    echo "$disk"
  fi
}

create_partitions() {
  info "Creating partitions on $DISK"
  wipefs -af "$DISK"
  sgdisk --zap-all "$DISK" >/dev/null
  sgdisk -n 1:0:+${EFI_SIZE} -t 1:ef00 "$DISK" # EFI partition
  sgdisk -n 2:0:0 -t 2:8300 "$DISK"            # Root partition (Btrfs)
  until [[ -b "$efi_partition" && -b "$root_partition" ]]; do
    sleep 1
    partprobe "$DISK"
  done
  success "Partitions created successfully"
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
  BTRFS_MOUNT_OPTIONS="compress=zstd,noatime"
  info "Mounting filesystems"
  local prefix
  prefix=$(partition_prefix "$DISK")

  local efi_partition="${prefix}1"
  local root_partition="${prefix}2"

  mount "$root_partition" /mnt
  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@home
  btrfs subvolume create /mnt/@log
  btrfs subvolume create /mnt/@pkg
  umount /mnt

  mount -o subvol=@,$BTRFS_MOUNT_OPTIONS "$root_partition" /mnt
  mkdir -p /mnt/home /mnt/var/log /mnt/var/cache/pacman/pkg
  mount -o subvol=@home,$BTRFS_MOUNT_OPTIONS "$root_partition" /mnt/home
  mount -o subvol=@log,$BTRFS_MOUNT_OPTIONS "$root_partition" /mnt/var/log
  mount -o subvol=@pkg,$BTRFS_MOUNT_OPTIONS "$root_partition" /mnt/var/cache/pacman/pkg

  mkdir -p /mnt/boot
  mount "$efi_partition" /mnt/boot
  success "Filesystems mounted successfully"
}
