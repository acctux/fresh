# ───────────────── Global Variables ───────────────── #
DEVICE=""
PARTITIONS=()
#KEYS_MNT=$(mktemp -d)

# ─────────────────── Helpers ─────────────────── #
list_and_store_PARTITIONS() {
    log INFO "Detecting available PARTITIONS..."

    # Reset PARTITIONS=()
    PARTITIONS=()
    local index=1

    while read -r line; do
        # Parse using eval
        eval "$line"

        # Check if it's an unmounted partition
        if [[ "$TYPE" == "part" && -z "$MOUNTPOINT" ]]; then
            local dev="/dev/$NAME"
            PARTITIONS+=("$dev")

            local mount_status="UNMOUNTED"

            printf "%d) %-10s Size: %-6s FS: %-6s Mounted: %-12s Removable: %s\n" \
                "$index" "$dev" "$SIZE" "$FSTYPE" "$mount_status" "$RM"

            ((index++))
        fi
    done < <(lsblk -P -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT,RM)
}

# ─────────────────── Functions ─────────────────── #
existing_keys() {
    for key_file in "${KEY_FILES[@]}"; do
        if [[ ! -f "$KEY_DIR/$key_file" ]]; then
            log INFO "$KEY_DIR/$key_file not found."
            return 1
        fi
    done

    return 0
}

mount_partition() {
    while true; do
        list_and_store_PARTITIONS

        if [[ ${#PARTITIONS[@]} -gt 0 ]]; then
            break  # Partitions found, exit loop
        fi

        echo "No partitions detected. Please insert your device and press Enter to retry..."
        read -r  # Wait for user to press Enter
    done

    printf "Select partition where keys can be located in the base directory: "
    read -r choice

    # Validate that choice is a number and within valid range
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#PARTITIONS[@]} )); then
        log ERROR "Invalid selection: $choice"
        exit 1
    fi

    DEVICE="${PARTITIONS[choice-1]}"
    if [[ -z "$DEVICE" || ! -b "$DEVICE" ]]; then
        log ERROR "Invalid or missing DEVICE: $DEVICE"
        exit 1
    fi

    sudo mkdir -p "$KEYS_MNT"
    sudo mount "$DEVICE" "$KEYS_MNT"
    log INFO "Mounted $DEVICE to $KEYS_MNT"
}

# Copy keys to home directory.
copy_key_files() {
    # Confirm mount point directory exists
    if [[ ! -d "$KEYS_MNT" ]]; then
        log ERROR "Mount point $KEYS_MNT not found"
        return 1
    fi

    log INFO "Copying files from USB..."
    mkdir -p "$KEY_DIR"
    # Copy .ssh directory if present
    for key_file in "${KEY_FILES[@]}"; do
        if [[ ! -f "$KEY_DIR/$key_file" ]]; then
            cp "$KEYS_MNT/.ssh/$key_file" "$KEY_DIR"
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
# Wrapped in () instead of {} to make it a subshell and run unmount_partition
# not only on failure
mnt_cp_keys() (
    if ! existing_keys; then
        trap unmount_partition EXIT  # Now this runs when the subshell ends

        mount_partition || exit 1
        copy_key_files || exit 1

        echo "Running key and wifi setup because both Wi-Fi and key files are missing."
    else
        echo "All requirements met. Skipping external sourcing setup."
    fi
)
