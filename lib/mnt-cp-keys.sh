# ────────── Global variable declaration ─────────── #
device=""
partitions=()
readonly KEYS_MNT="/mnt/keys"

# ─────────────────── Helpers ─────────────────── #
list_and_store_partitions() {
    log INFO "Detecting available partitions..."

    partitions=()
    local index=1

    while read -r line; do
        # Parse using eval
        eval "$line"

        # Check if it's an unmounted partition
        if [[ "$TYPE" == "part" && -z "$MOUNTPOINT" ]]; then
            local dev="/dev/$NAME"
            partitions+=("$dev")

            local mount_status="UNMOUNTED"

            printf "%d) %-10s Size: %-6s FS: %-6s Mounted: %-12s Removable: %s\n" \
                "$index" "$dev" "$SIZE" "$FSTYPE" "$mount_status" "$RM"

            ((index++))
        fi
    done < <(lsblk -P -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT,RM)
}


# ─────────────────── Functions ─────────────────── #
check_existing_files() {
    for key_file in "${KEY_FILES[@]}"; do
        if [[ ! -f "$HOME/.ssh/$key_file" ]]; then
            return 0
        fi
    done

    log INFO "Skipping USB copy: All key files already exist in \$HOME/.ssh"
    return 1
}

mount_partition() {
    # Call list_and_store_partitions to populate partitions and display choices
    list_and_store_partitions

    if [[ ${#partitions[@]} -eq 0 ]]; then
        log ERROR "No partitions available for selection."
        exit 1
    fi

    printf "Select partition where keys can be located in the base directory: "
    read -r choice

    # Validate that choice is a number and within valid range
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#partitions[@]} )); then
        log ERROR "Invalid selection: $choice"
        exit 1
    fi

    # Set global device variable based on user selection
    device="${partitions[choice-1]}"
    # Validate that the selected device exists and is a block device
    if [[ -z "$device" || ! -b "$device" ]]; then
        log ERROR "Invalid or missing device: $device"
        exit 1
    fi

    sudo mkdir -p "$KEYS_MNT"

    # Attempt to mount the device; errors will exit the script due to 'set -e'
    sudo mount "$device" "$KEYS_MNT"
    log INFO "Mounted $device to $KEYS_MNT"
}

# Copy expected files (.ssh directory and wifi.sh) from mounted USB to user's home directory.
copy_key_files() {
    # Confirm mount point directory exists
    if [[ ! -d "$KEYS_MNT" ]]; then
        log ERROR "Mount point $KEYS_MNT not found"
        return 1
    fi

    log INFO "Copying files from USB..."
    mkdir -p "$HOME/.ssh"
    # Copy .ssh directory if present
    for key_file in "${KEY_FILES[@]}"; do
        if [[ ! -f "$HOME/.ssh/$key_file" ]]; then
            cp "$KEYS_MNT/.ssh/$key_file" "$HOME/.ssh"
        fi
    done
}

# Unmount USB partition and clean up mount directory.
unmount_partition() {
    # Only attempt unmount if mount point is active
    if mountpoint -q "$KEYS_MNT"; then
        sudo umount "$KEYS_MNT"
        log INFO "Unmounted USB from $KEYS_MNT"
    fi

    # Remove the mount directory; ignore errors if it does not exist
    sudo rmdir "$KEYS_MNT" 2>/dev/null || true
}

# ─────────────────── Wrapper ─────────────────── #
mnt_cp_keys() {
    check_existing_files
    mount_partition
    copy_key_files
    unmount_partition
}
