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
    local disk_bytes efi_bytes root_min bytes_required

    disk_bytes=$(lsblk -b -dn -o SIZE "$DISK")
    efi_bytes=$(numfmt --from=iec "$EFI_SIZE")
    root_min=$((8 * 1024 * 1024 * 1024))  # 8 GiB for root

    bytes_required=$((efi_bytes + root_min))

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
    wipefs -af "$DISK"
    sgdisk --zap-all "$DISK" >/dev/null
    sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK}
    sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK}
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK}
    partprobe "$DISK"
    sleep 2
    success "Partitions created successfully"
}

format_partitions() {
    info "Formatting partitions"
    local prefix
    prefix=$(partition_prefix "$DISK")

    local efi_partition="${prefix}1"
    local swap_partition="${prefix}2"
    local root_partition="${prefix}3"

    SWAP_PARTITION="$swap_partition"

    mkfs.fat -F32 "$efi_partition"
    mkswap "$swap_partition"
    swapon "$swap_partition"
    mkfs.btrfs -f "$root_partition"
    success "Partitions formatted successfully"
}

mount_filesystems() {
    info "Mounting filesystems"
    local prefix
    prefix=$(partition_prefix "$DISK")

    local btrfs_opts="compress=lzo,noatime"
    local efi_partition="${prefix}1"
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
    info "Unmounting boot."
    if mountpoint -q "$MOUNT_POINT/boot"; then
        umount "$MOUNT_POINT/boot" || true
    fi
    for sub in home var/log var/cache/pacman/pkg; do
        if mountpoint -q "$MOUNT_POINT/$sub"; then
            umount "$MOUNT_POINT/$sub" || true
        fi
    done
    if mountpoint -q "$MOUNT_POINT"; then
        umount "$MOUNT_POINT" || true
    fi
    if [[ -n "$SWAP_PARTITION" ]]; then
        swapoff "$SWAP_PARTITION" || true
    fi
}

aardvark() {

    trap 'error_trap $LINENO $BASH_COMMAND' ERR
    get_disk_selection
    info "Installation summary:"
    printf 'Disk: %s\nEFI size: %s\nSwap size: %s\nHostname: %s\nUsername: %s\nTimezone: %s\n\n' \
        "$DISK" "$EFI_SIZE" "$SWAP_SIZE" "$HOSTNAME" "$USERNAME" "$TIMEZONE"

    yes_no_prompt "Proceed with installation?" || fatal "Installation cancelled by user"
    create_partitions
    format_partitions
    mount_filesystems
}
aardvark
