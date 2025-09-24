# ───────────────── Global Variables ───────────────── #
PARTITIONS=()
KEYS_MNT=$(mktemp -d)

# ─────────────────── Helpers ─────────────────── #
existing_keys() {
    for key_file in "${KEY_FILES[@]}"; do
        if [[ ! -f "$KEY_DIR/$key_file" ]]; then
            log INFO "$KEY_DIR/$key_file not found."
            return 1
        fi
    done
}

list_and_store_partitions() {
    log INFO "Detecting available PARTITIONS..."
    # Reset PARTITIONS=()
    PARTITIONS=()
    local index=1

    while read -r line; do
        # Parse using eval
        eval "$line"

        # Check if it's an unmounted partition
        if [[ "$TYPE" == "part" ]]; then
            local dev="/dev/$NAME"
            PARTITIONS+=("$dev")

            printf "%d) %-10s Size: %-6s FS: %-6s Removable: %s\n" \
                "$index" "$dev" "$SIZE" "$FSTYPE" "$RM"

            ((index++))
        fi
    done < <(lsblk -P -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT,RM)
}

# ─────────────────── Functions ─────────────────── #
mount_partition() {
    local choice device

    while true; do
        list_and_store_partitions

        if [[ ${#PARTITIONS[@]} -eq 0 ]]; then
            printf "No unmounted partitions detected. Press Enter to retry..."
            read -r
            continue
        fi

        printf "Select a partition (1-%d): " "${#PARTITIONS[@]}"
        read -r choice

        # Validate input and attempt mount in a single if/else block
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice > 0 && choice <= ${#PARTITIONS[@]} )); then
            device="${PARTITIONS[choice-1]}"
            if sudo mkdir -p "$KEYS_MNT" && sudo mount "$device" "$KEYS_MNT"; then
                log INFO "Mounted $device to $KEYS_MNT"
                break
            else
                log ERROR "Failed to mount $device."
                printf "Mount failed. Press Enter to try again..."
            fi
        else
            log ERROR "Invalid selection: $choice"
            printf "Invalid selection. Press Enter to try again..."
        fi
        read -r
    done
}

# Copy keys to home directory.
copy_key_files() {
    log INFO "Copying files from USB..."
    mkdir -p "$KEY_DIR"
    for key_file in "${KEY_FILES[@]}"; do
        if [[ ! -f "$KEY_DIR/$key_file" ]]; then
            cp "$KEYS_MNT/.ssh/$key_file" "$KEY_DIR"
        fi
    done
}

# Unmount USB partition and clean up mount directory.
unmount_partition() {
    if mountpoint -q "$KEYS_MNT"; then
        sudo umount "$KEYS_MNT"
        log INFO "Unmounted USB from $KEYS_MNT"
    fi
    sudo rmdir "$KEYS_MNT" 2>/dev/null || true
}

# ─────────────────── Wrapper ─────────────────── #
# Wrapped in () instead of {} to make it a subshell and run unmount_partition
# not only on failure
mnt_cp_keys() (
    if ! existing_keys; then
        trap unmount_partition EXIT
        mount_partition || exit 1
        copy_key_files || exit 1
    else
        echo "All requirements met. Skipping external sourcing setup."
    fi
)
