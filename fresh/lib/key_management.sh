existing_keys() {
    for key_file in "${KEY_FILES[@]}"; do
        if [[ ! -f "$KEY_DIR/$key_file" ]]; then
            log INFO "$KEY_DIR/$key_file not found."
            return 1
        fi
    done
    log info "Keys already found."
    return 0
}

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

set_key_permissions() {
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
