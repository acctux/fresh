#!/usr/bin/env bash

setup_ssh_agent() {
    [[ -f "$HOME/.ssh/id_ed25519" ]] || { log WARNING "SSH key missing."; return 1; }
    chmod 700 "$HOME/.ssh"
    chmod 600 "$HOME/.ssh/id_ed25519"
    chmod 644 "$HOME/.ssh/id_ed25519.pub"
    if ! pgrep -u "$USER" ssh-agent > /dev/null; then
        eval "$(ssh-agent -s)" >/dev/null
    fi
    ssh-add "$HOME/.ssh/id_ed25519" || log WARNING "Failed to add SSH key."
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
    read -rs -p "Enter GPG passphrase: " passphrase
    echo
    local decrypted
    decrypted=$(echo "$passphrase" | gpg --batch --yes --passphrase-fd 0 --decrypt "$GPG_KEYFILE" 2>/dev/null) ||
        { log ERROR "Failed to decrypt GPG key."; return 1; }
    local fingerprint
    fingerprint=$(echo "$decrypted" | gpg --import-options show-only --import - 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}')
    [[ -z "$fingerprint" ]] && { log ERROR "Could not extract fingerprint."; return 1; }
    if ! gpg --list-keys "$fingerprint" &>/dev/null; then
        echo "$decrypted" | gpg --import -
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
