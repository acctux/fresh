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
    validate_disk "$DISK"

    yes_no_prompt "WARNING: All data on $DISK will be destroyed. Continue?" || fatal "Installation cancelled by user"
}

get_btrfs_layout() {
    if yes_no_prompt "Use the default Btrfs subvolume layout?"; then
        info "Using default Btrfs layout"
    else
        warning "Custom Btrfs layouts are not implemented in this script. Falling back to default layout."
    fi

    if yes_no_prompt "Use default Btrfs mount options (compress=zstd,noatime)?"; then
        info "Using default mount options"
    else
        if ! read -rp "Enter Btrfs mount options (e.g. compress=lzo,noatime): " BTRFS_MOUNT_OPTIONS; then
            fatal "Input aborted"
        fi
        success "Btrfs mount options set to: $BTRFS_MOUNT_OPTIONS"
    fi
}

get_bootloader_selection() {
    BOOTLOADER=$(select_from_menu) \
        "Select bootloader:" \
        "grub (traditional)" "systemd-boot (simple UEFI)" "refind (graphical)" \
    )
    case "$BOOTLOADER" in
        grub*)        BOOTLOADER="grub" ;;
        systemd-boot*) BOOTLOADER="systemd-boot" ;;
        refind*)      BOOTLOADER="refind" ;;
    esac
    success "Selected bootloader: $BOOTLOADER"

    if [[ "$BOOTLOADER" == "systemd-boot" ]]; then
        if ! read -rp "Enter bootloader timeout in seconds [default 3]: " timeout; then
            fatal "Input aborted"
        fi
        if [[ -n "$timeout" && "$timeout" =~ ^[0-9]+$ ]]; then
            BOOTLOADER_TIMEOUT="$timeout"
            success "Bootloader timeout set to $BOOTLOADER_TIMEOUT seconds"
        else
            info "Using default timeout of 3 seconds"
        fi
    fi
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
    wipefs -af "$DISK"
    sgdisk --zap-all "$DISK"

    # GPT with 2048-sector alignment (1 MiB)
    sgdisk -a 2048 -o "$DISK"

    # EFI System Partition (FAT32, mounted at /boot or /boot/efi)
    sgdisk -n 1:2048:+${EFI_SIZE} -t 1:ef00 -c 1:"EFIBOOT" "$DISK"

    # Btrfs ROOT partition
    sgdisk -n 2:0:0 -t 2:8300 -c 2:"$drive_name" "$DISK"

    # Inform the kernel
    partprobe "$DISK"
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

    if [[ "$FILESYSTEM_TYPE" == "btrfs" ]]; then
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
    fi
    success "Filesystems mounted successfully"
}
