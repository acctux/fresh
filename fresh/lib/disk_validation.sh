#######################################
# Prompt helpers
#######################################

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

validate_disk_size() {
    local disk_bytes efi_bytes swap_bytes root_min bytes_required
    disk_bytes=$(lsblk -b -dn -o SIZE "$DISK")
    efi_bytes=$(numfmt --from=iec "$EFI_SIZE")
    swap_bytes=$(numfmt --from=iec "$SWAP_SIZE")
    root_min=$((1 * 1024 * 1024 * 1024))
    bytes_required=$((efi_bytes + swap_bytes + root_min))
    if (( disk_bytes < bytes_required )); then
        fatal "Disk size $(numfmt --to=iec $disk_bytes) is smaller than required $(numfmt --to=iec $bytes_required)"
    fi
    success "Disk has sufficient capacity: $(numfmt --to=iec $disk_bytes)"
}
