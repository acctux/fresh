#Environment setting
set_correct_permissions() {
    local .ssh="$HOME/.ssh"

    # check for progress marker file
    if [[ -f "$ssh/keys_permissions_set" ]]; then
        log INFO "Permissions already set. Skipping."
        return 0
    fi

    chown "$USER:$USER" "$ssh" 2>/dev/null || true
    chmod 700 "$ssh"

    for key_file in "${KEY_FILES[@]}"; do
            if [[ ! -f "$ssh/$key_file" ]]; then
                log ERROR "$key_file not found. Rerun script."
            else
                chown "$USER":"$USER" "$ssh/$key_file"
                chmod 600 "$ssh/$key_file"
            fi
    done

    # Create progress marker file
    touch "$ssh/keys_permissions_set"
}

# cat needs to be exactly as written in destination (don't indent)
create_ssh_config() {
    mkdir -p "$HOME/.ssh"
    if [[ ! -f "$HOME/.ssh/config" ]]; then
        cat << EOF > "$HOME/.ssh/config"
Host *
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519
EOF
        chmod 600 "$HOME/.ssh/config"
    fi
}

# Key import
setup_ssh_agent() {
    [[ -f "$HOME/.ssh/id_ed25519" ]] || { log WARNING "SSH key missing."; return 1; }

    if ! pgrep -u "$USER" ssh-agent > /dev/null; then
        eval "$(keychain --quiet --eval id_ed25519)" >/dev/null
        export SSH_AUTH_SOCK
        export SSH_AGENT_PID
    fi

    if ! ssh-add -l | grep -q "$(ssh-keygen -y -P '' -f "$HOME/.ssh/id_ed25519" | awk '{print $2}')"; then
        ssh-add "$HOME/.ssh/id_ed25519" || { log WARNING "Failed to add SSH key."; return 1; }
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
