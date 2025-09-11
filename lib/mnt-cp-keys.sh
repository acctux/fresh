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
saved_wifi_connection() {
    # List all saved connections with type wifi (802-11-wireless)
    if nmcli connection show | grep -q "802-11-wireless"; then
        return 0  # Found at least one Wi-Fi connection saved
    fi
}

existing_keys() {
    for key_file in "${KEY_FILES[@]}"; do
        if [[ ! -f "$KEY_DIR/$key_file" ]]; then
            return 1  # Missing file → files do NOT all exist
        fi
    done

    return 0  # All files exist
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

read_wifi_credentials() {
    if [[ ! -f "$WIFI_CREDENTIALS" ]]; then
        log WARNING "Wi-Fi WIFI_CREDENTIALS file not found on USB."
        return 1
    fi

    log INFO "Reading Wi-Fi credentials into memory..."
    # shellcheck disable=SC1090

    if [[ -f "$WIFI_CREDENTIALS" ]]; then
        while IFS='=' read -r key value; do
            case "$key" in
                DEFAULT_WIFI_SSID) DEFAULT_WIFI_SSID="$value" ;;
                DEFAULT_WIFI_PASS) DEFAULT_WIFI_PASS="$value" ;;
            esac
        done < "$WIFI_CREDENTIALS"
    fi

    # Validate required variables are now in memory
    if [[ -z "${DEFAULT_WIFI_SSID:-}" || -z "${DEFAULT_WIFI_PASS:-}" ]]; then
        log ERROR "Wi-Fi SSID or password not set in $WIFI_CREDENTIALS."
        return 1
    fi

    log INFO "Wi-Fi credentials loaded into memory."
    return 0
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
mnt_cp_keys() {
    if ! has_saved_wifi_connection && ! existing_files; then
        mount_partition
        read_wifi_credentials
        copy_key_files
        unmount_partition
        echo "Running key and wifi setup because both Wi-Fi and key files are missing."
    else
        echo "All requirements met. Skipping external sourcing setup."
    fi
}
