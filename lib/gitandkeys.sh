#!/usr/bin/env bash

setup_ssh_agent() {
    [[ -f "$HOME/.ssh/id_ed25519" ]] || { log WARNING "SSH key missing."; return 1; }
    chmod 700 "$HOME/.ssh"
    chmod 600 "$HOME/.ssh/id_ed25519"
    chmod 644 "$HOME/.ssh/id_ed25519.pub"

    if ! pgrep -u "$USER" ssh-agent > /dev/null; then
        eval "$(ssh-agent -s)" >/dev/null
        export SSH_AUTH_SOCK
        export SSH_AGENT_PID
    fi

    if ! ssh-add -l | grep -q "$(ssh-keygen -y -P '' -f "$HOME/.ssh/id_ed25519" | awk '{print $2}')"; then
        ssh-add "$HOME/.ssh/id_ed25519" || { log WARNING "Failed to add SSH key."; return 1; }
    fi
}

clone_git_repos() {
    mkdir -p "$GIT_LIT"
    cd "$GIT_LIT"
    for repo in "${GIT_REPOS[@]}"; do
        [[ -d "$repo" ]] && { log INFO "$repo already exists."; continue; }
        git clone "git@github.com:$GIT_USER/$repo.git" && log INFO "Cloned $repo." ||
            log ERROR "Failed to clone $repo."
    done
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

git_and_keys() {
    setup_ssh_agent
    clone_git_repos
    import_gpg_key
}
