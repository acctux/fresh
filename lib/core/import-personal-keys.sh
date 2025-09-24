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

# cat needs to be exactly as written in destination (don't indent)
create_ssh_config() {
    mkdir -p "$KEY_DIR"
    if [[ ! -f "$KEY_DIR/config" ]]; then
        cat << EOF > "$KEY_DIR/config"
Host *
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519
EOF
        ensure_mode "$KEY_DIR/config" 600
    else
        log INFO "SSH config already set. Skipping."
    fi
}

# Key import
setup_ssh_agent() {
    local keychain_env="$HOME/.keychain/$(uname -n)-sh"

    # Start keychain only if SSH agent is not running or socket missing
    if [[ ! -S "${SSH_AUTH_SOCK-}" ]]; then
        keychain --quiet --eval "$SSH_KEY" >/dev/null
        source "$keychain_env"
    fi
}

import_ssh_keys() {
    if ! ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf "$SSH_KEY")"; then
        ssh-add "$SSH_KEY"
        echo "INFO: $SSH_KEY successfully added to agent."
    fi
}

import_gpg_key() {
    local fingerprint
    fingerprint=$(gpg --import-options show-only --import --with-colons "$GPG_KEYFILE" 2>/dev/null |
                  awk -F: '/^fpr:/ { print $10; exit }')

    if ! gpg --list-keys "$fingerprint" &>/dev/null; then
        gpg --import "$GPG_KEYFILE"
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
    import_gpg_key
}
