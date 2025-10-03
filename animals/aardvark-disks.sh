# readonly LOG_FILE="/tmp/noah.log"

# readonly USERNAME="nick"
# readonly HOSTNAME="arch"
# readonly EFI_SIZE="512M"
# readonly MOUNT_POINT="/mnt"
# readonly TIMEZONE="US/Eastern"
# LOCALE="en_US.UTF-8"


# #######################################
# # Logging helpers
# #######################################
# RED='\033[0;31m'
# GREEN='\033[0;32m'
# YELLOW='\033[1;33m'
# BLUE='\033[0;34m'
# NC='\033[0m' # No Color
# info()    { printf "${BLUE}[INFO]${NC} %s\n"    "$*" | tee -a "$LOG_FILE"; }
# success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$*" | tee -a "$LOG_FILE"; }
# warning() { printf "${YELLOW}[WARNING]${NC} %s\n" "$*" | tee -a "$LOG_FILE"; }
# error()   { printf "${RED}[ERROR]${NC} %s\n"   "$*" | tee -a "$LOG_FILE"; }

# fatal() {
#     error "$*"
#     exit 1
# }

# error_trap() {
#     local exit_code=$?
#     local line="$1"
#     local cmd="$2"
#     error "Command '${cmd}' failed at line ${line} with exit code ${exit_code}"
#     exit "$exit_code"
# }


# yes_no_prompt() {
#     # Ask a yes/no question until the user enters y or n
#     local prompt="$1"
#     local reply
#     while true; do
#         if ! read -rp "$prompt [y/n]: " reply; then
#             fatal "Input aborted"
#         fi
#         case "$reply" in
#             [Yy]) return 0 ;;
#             [Nn]) return 1 ;;
#         esac
#         warning "Please answer 'y' or 'n'."
#     done
# }

# select_from_menu() {
#     # Generic menu selection helper
#     local prompt="$1"
#     shift
#     local options=("$@")
#     local num="${#options[@]}"
#     local choice
#     while true; do
#         info "$prompt" >&2
#         for i in "${!options[@]}"; do
#             printf '%d) %s\n' "$((i+1))" "${options[i]}" >&2
#         done
#         if ! read -rp "Select an option (1-${num}): " choice; then
#             fatal "Input aborted"
#         fi
#         if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= num )); then
#             echo "${options[$((choice-1))]}"
#             return 0
#         fi
#         warning "Invalid choice. Please select a number between 1 and ${num}." >&2
#     done
# }

#######################################
# User input functions
#######################################
get_disk_selection() {
    info "Detecting available disks..."
    local disks=()
    local labels=()

    while IFS= read -r line; do
        line="${line% disk}"
        local name size model
        name=$(awk '{print $1}' <<< "$line")
        size=$(awk '{print $2}' <<< "$line")
        model=$(cut -d' ' -f3- <<< "$line")
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
    check_disk_size "$DISK"

    yes_no_prompt "WARNING: All data on $DISK will be destroyed. Continue?" || fatal "Installation cancelled by user"
}

check_disk_size() {
    local disk_bytes efi_bytes bios_bytes root_min bytes_required

    disk_bytes=$(lsblk -b -dn -o SIZE "$DISK")
    efi_bytes=$(numfmt --from=iec "$EFI_SIZE")
    bios_bytes=$((1 * 1024 * 1024))  # 1 MiB for BIOS boot
    root_min=$((8 * 1024 * 1024 * 1024))  # 8 GiB for root

    bytes_required=$((efi_bytes + bios_bytes + root_min))

    if (( disk_bytes < bytes_required )); then
        error "Disk size $(numfmt --to=iec "$disk_bytes") is smaller than required $(numfmt --to=iec "$bytes_required")"
        exit 1
    fi

    success "Disk has sufficient capacity: $(numfmt --to=iec "$disk_bytes")"
}

#######################################
# Disk management functions
#######################################
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
    # umount -A --recursive /mnt # make sure everything is unmounted before we start
    # disk prep
    sgdisk -Z ${DISK} # zap all on disk
    sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

    # create partitions
    sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # partition 1 (BIOS Boot Partition)
    sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # partition 2 (UEFI Boot Partition)
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # partition 3 (Root), default start, remaining
    if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
        sgdisk -A 1:set:2 ${DISK}
    fi
    partprobe ${DISK}
}

format_partitions() {
    info "Formatting partitions"
    local prefix
    prefix=$(partition_prefix "$DISK")

    local bios_partition="${prefix}1"
    local efi_partition="${prefix}2"
    local root_partition="${prefix}3"

    mkfs.fat -F32 "$efi_partition"
    mkfs.btrfs -f "$root_partition"
    success "Partitions formatted successfully"
}

mount_filesystems() {
    info "Mounting filesystems"
    local prefix
    prefix=$(partition_prefix "$DISK")

    local btrfs_opts="compress=zstd,noatime"
    local efi_partition="${prefix}2"
    local root_partition="${prefix}3"

    mount "$root_partition" "$MOUNT_POINT"
    mkdir -p "$MOUNT_POINT/boot"
    mount "$efi_partition" "$MOUNT_POINT/boot"

    btrfs subvolume create "$MOUNT_POINT/@"
    btrfs subvolume create "$MOUNT_POINT/@home"
    btrfs subvolume create "$MOUNT_POINT/@log"
    btrfs subvolume create "$MOUNT_POINT/@pkg"
    umount "$MOUNT_POINT/boot"
    umount "$MOUNT_POINT"
    mount -o subvol=@,$btrfs_opts "$root_partition" "$MOUNT_POINT"
    mkdir -p "$MOUNT_POINT/home" "$MOUNT_POINT/var/log" "$MOUNT_POINT/var/cache/pacman/pkg"
    mount -o subvol=@home,$btrfs_opts "$root_partition" "$MOUNT_POINT/home"
    mount -o subvol=@log,$btrfs_opts "$root_partition" "$MOUNT_POINT/var/log"
    mount -o subvol=@pkg,$btrfs_opts "$root_partition" "$MOUNT_POINT/var/cache/pacman/pkg"
    mkdir -p "$MOUNT_POINT/boot"
    mount "$efi_partition" "$MOUNT_POINT/boot"
    success "Filesystems mounted successfully"
}

#######################################
# Cleanup
#######################################
unmount_mounted() {
    info "Unmounting filesystems"
    if mountpoint -q "$MOUNT_POINT/boot"; then
        umount "$MOUNT_POINT/boot" || error "Failed to unmount $MOUNT_POINT/boot"
    fi
    for sub in home var/log var/cache/pacman/pkg; do
        if mountpoint -q "$MOUNT_POINT/$sub"; then
            umount "$MOUNT_POINT/$sub" || error "Failed to unmount $MOUNT_POINT/$sub"
        fi
    done
    if mountpoint -q "$MOUNT_POINT"; then
        umount "$MOUNT_POINT" || error "Failed to unmount $MOUNT_POINT"
    fi
    success "Filesystems unmounted successfully"
}

aardvark() {
    unmount_mounted
    trap 'error_trap $LINENO $BASH_COMMAND' ERR
    get_disk_selection
    info "Installation summary:"
    printf 'Disk: %s\nEFI size: %s\nHostname: %s\nUsername: %s\nTimezone: %s\n\n' \
        "$DISK" "$EFI_SIZE" "$HOSTNAME" "$USERNAME" "$TIMEZONE"

    yes_no_prompt "Proceed with installation?" || fatal "Installation cancelled by user"
    create_partitions
    format_partitions
    mount_filesystems
}
