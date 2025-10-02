copy_fresh_to_new_home() {
    info "Copying Fresh to new install."
    cp -r "~/fresh" "/mnt/home/$USERNAME"
    chown -R $USERNAME:$USERNAME /mnt/home/$USERNAME/fresh
    chmod 700 /mnt/home/$USERNAME/fresh
    find /mnt/home/$USERNAME/fresh -type f -exec chmod 600 {} \;
}

set_key_permissions() {
    ensure_owner "$KEY_DIR" "$USERNAME"
    ensure_mode "$KEY_DIR" 700

    # Fix each key file
    for key_file in "${KEY_FILES[@]}"; do
        local full_path="$KEY_DIR/$key_file"

        if [[ ! -f "$full_path" ]]; then
            log ERROR "$key_file not found. Rerun script."
            continue
        fi

        ensure_owner "$full_path" "$USERNAME"
        ensure_mode "$full_path" 600
    done
}
