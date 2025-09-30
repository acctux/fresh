

# Copy keys to home directory.
copy_key_files() {
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

set_correct_permissions() {
    ensure_owner "$KEY_DIR" "$USER"
    ensure_mode "$KEY_DIR" 700

    # Fix each key file
    for key_file in "${KEY_FILES[@]}"; do
        local full_path="$KEY_DIR/$key_file"

        if [[ ! -f "$full_path" ]]; then
            log ERROR "$key_file not found. Rerun script."
            continue
        fi

        ensure_owner "$full_path" "$USER"
        ensure_mode "$full_path" 600
    done
}

# ─────────────────── Wrapper ─────────────────── #
# Wrapped in () instead of {} to make it a subshell and run unmount_partition
# not only on failure
mnt_cp_keys() (
    trap 'error_trap $LINENO $BASH_COMMAND' ERR
    existing_keys
    make_choice
    validate_choice || make_choice
    validate_partition || make_choice

    trap unmount_partition EXIT
    mount_choice || exit 1 && log ERROR "Failed to mount selection."
    copy_key_files

    log INFO "Keys copied."
)
