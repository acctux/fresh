# ───────────────── Global Variables ───────────────── #
DEVICE=""
CHOICE=""
PARTITIONS=()
KEYS_MNT=$(mktemp -d)

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

make_choice() {
    while true; do
        list_and_store_PARTITIONS

        if [[ ${#PARTITIONS[@]} -gt 0 ]]; then
            break  # Partitions found, exit loop
        fi

        echo "No partitions detected. Please insert your device and press Enter to retry..."
        read -r  # Wait for user to press Enter
    done

    printf "Select partition where keys can be located in the base directory: "
    read -r CHOICE
}

validate_choice() {
    # Validate that 'CHOICE' is a positive integer and within the valid range of PARTITIONS array
    if [[ ! "$CHOICE" =~ ^[0-9]+$ ]]; then
        # Check if 'CHOICE' is not a valid number (contains non-digits)
        log ERROR "Invalid selection: '$CHOICE' is not a valid number"
        exit 1
    elif (( CHOICE < 1 || CHOICE > ${#PARTITIONS[@]} )); then
        # Check if 'CHOICE' is outside the valid range (less than 1 or greater than the number of partitions)
        log ERROR "Invalid selection: '$CHOICE' is out of range (1 to ${#PARTITIONS[@]})"
        exit 1
    fi
    DEVICE="${PARTITIONS[CHOICE-1]}"
}

validate_partition() {
    # check if zero "-z" or not a block device
    if [[ -z "$DEVICE" || ! -b "$DEVICE" ]]; then
        log ERROR "Invalid or missing DEVICE: $DEVICE"
        exit 1
    fi
}

mount_CHOICE() {
    sudo mkdir -p "$KEYS_MNT"
    sudo mount "$DEVICE" "$KEYS_MNT"
    log INFO "Mounted $DEVICE to $KEYS_MNT"
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
        make_choice
        validate_choice || make_choice
        validate_partition || make_choice

        trap unmount_partition EXIT
        mount_choice || exit 1 && log ERROR "Failed to mount selection."
        copy_key_files

        log INFO "Keys copied."
    else
        log INFO "All requirements met. Skipping external sourcing setup."
    fi
)
