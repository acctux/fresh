set_correct_permissions() {
    # Ensure directory exists
    [[ -d "$KEY_DIR" ]] || {
        log ERROR "Directory $KEY_DIR does not exist."
        return 1
    }

    # Fix directory ownership and permissions
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
    local ssh_key="$KEY_DIR/id_ed25519"
    local host="${HOSTNAME:-$(uname -n)}"
    local keychain_env="$HOME/.keychain/${host}-sh"

    # Check if key file exists
    if [[ ! -f "$ssh_key" ]]; then
        echo "WARNING: SSH key missing: $ssh_key"
        return 1
    fi

    # Start keychain only if SSH agent is not running or socket missing
    if [[ -z "${SSH_AUTH_SOCK-}" || -z "${SSH_AGENT_PID-}" || ! -S "${SSH_AUTH_SOCK-}" ]]; then
        keychain --quiet --eval "$ssh_key" >/dev/null
        if [[ -f "$keychain_env" ]]; then
            source "$keychain_env"
        else
            echo "WARNING: Keychain environment not found for host '$host'."
            return 1
        fi
    fi

    # Check if key is loaded by fingerprint
    if ! ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf "$ssh_key" | awk '{print $2}')"; then
        ssh-add "$ssh_key" || { echo "WARNING: Failed to add SSH key."; return 1; }
    fi

    echo "INFO: SSH key successfully added to agent."
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
    import_gpg_key
}
