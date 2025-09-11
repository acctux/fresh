#Environment setting
set_correct_permissions() {
    # check for progress marker file
    if [[ -f "$KEY_DIR/keys_permissions_set" ]]; then
        log INFO "Permissions already set. Skipping."
        return 0
    fi

    chown "$USER:$USER" "$KEY_DIR" 2>/dev/null || true
    chmod 700 "$KEY_DIR"

    for key_file in "${KEY_FILES[@]}"; do
            if [[ ! -f "$KEY_DIR/$key_file" ]]; then
                log ERROR "$key_file not found. Rerun script."
            else
                chown "$USER":"$USER" "$KEY_DIR/$key_file"
                chmod 600 "$KEY_DIR/$key_file"
            fi
    done

    # Create progress marker file
    touch "$KEY_DIR/keys_permissions_set"
}

# cat needs to be exactly as written in destination (don't indent)
create_ssh_config() {
    mkdir -p "$KEY_DIR"
    if [[ ! -f "$KEY_DIR/config" ]]; then
        cat << EOF > "$KEY_DIR/config"
Host *
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519
EOF
        chmod 600 "$KEY_DIR/config"
    else
        log INFO "SSH config already set. Skipping."
    fi
}

# Key import
setup_ssh_agent() {
    local ssh_key="$KEY_DIR/id_ed25519"

    [[ -f "$ssh_key" ]] || { log WARNING "SSH key missing."; return 1; }

    # Start keychain and source the generated env vars
    keychain --quiet --eval "$ssh_key" >/dev/null

    # Source keychain environment variables
    if [[ -f "$HOME/.keychain/$(hostname)-sh" ]]; then
        source "$HOME/.keychain/$(hostname)-sh"
    elif [[ -f "$HOME/.keychain/$(hostname)-bash" ]]; then
        source "$HOME/.keychain/$(hostname)-bash"
    else
        log WARNING "Keychain environment not found. Agent may not work."
        return 1
    fi

    # Add the key if not already loaded
    if ! ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -y -P '' -f "$ssh_key" | awk '{print $2}')" 2>/dev/null; then
        ssh-add "$ssh_key" || { log WARNING "Failed to add SSH key."; return 1; }
    fi
}

import_gpg_key() {
    [[ -f "$GPG_KEYFILE" ]] || { log WARNING "No GPG key file at $GPG_KEYFILE."; return 1; }

    local fingerprint
    fingerprint=$(gpg --import-options show-only --import --with-colons "$GPG_KEYFILE" 2>/dev/null |
                  awk -F: '/^fpr:/ { print $10; exit }') ||
        { log ERROR "Could not extract fingerprint."; return 1; }

    [[ -z "$fingerprint" ]] && { log ERROR "Fingerprint not found."; return 1; }

    if ! gpg --list-keys "$fingerprint" &>/dev/null; then
        gpg --import "$GPG_KEYFILE" || { log ERROR "Failed to import GPG key."; return 1; }
        echo "${fingerprint}:6:" | gpg --import-ownertrust
        log INFO "Imported GPG key $fingerprint."
    else
        log INFO "GPG key $fingerprint already exists."
    fi
}

import_personal_keys() {
    set_correct_permissions
    create_ssh_config
    setup_ssh_agent
    clone_git_repos
    import_gpg_key
}
