is_chaotic_key_installed() {
    if sudo pacman-key --list-keys "$CHAOTIC_KEY_ID" &>/dev/null; then
        # Check if the key is locally signed using GPG
        if gpg --homedir /etc/pacman.d/gnupg --list-sigs "$CHAOTIC_KEY_ID" 2>/dev/null | grep -q "^\s*sig\s*L"; then
            echo "Chaotic AUR GPG key is installed and locally signed."
            return 0
        else
            echo "Chaotic AUR GPG key is installed but not locally signed."
            return 1
        fi
    else
        echo "Chaotic AUR GPG key not found."
        return 1
    fi
}

setup_chaotic_keys() {
    log INFO "Chaotic AUR key not found. Retrieving key..."
    local keyservers=(
        keyserver.ubuntu.com
        pgp.mit.edu
    )
    for ks in "${keyservers[@]}"; do
        log INFO "Trying keyserver: $ks"
        if sudo pacman-key --recv-key "$CHAOTIC_KEY_ID" --keyserver "$ks"; then
            log INFO "Successfully retrieved key from $ks"
            break
        fi
    done
    sudo pacman-key --lsign-key "$CHAOTIC_KEY_ID" || {
        log ERROR "Failed to sign Chaotic AUR key."
        return 1
    }
}

install_chaotic_keyring() {
    # Check if packages already installed
    if ! pacman -Qs chaotic-keyring > /dev/null || ! pacman -Qs chaotic-mirrorlist > /dev/null; then
        sudo pacman -U --noconfirm \
        https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst \
        https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst || {
            log ERROR "Failed to install Chaotic AUR packages."
            return 1
        }
    else
        log INFO "Chaotic AUR keyring already installed."
    fi
}

install_chaotic_key_from_github() {
    local key_url="https://raw.githubusercontent.com/chaotic-aur/keyring/master/chaotic.gpg"
    local tmpfile

    tmpfile=$(mktemp /tmp/chaotic_gpg.XXXXXX) || return 1

    echo "Downloading Chaotic GPG key from GitHub..."
    if curl -fLo "$tmpfile" "$key_url"; then
        echo "Downloaded key to $tmpfile"
    else
        echo "Failed to download Chaotic GPG key"
        rm -f "$tmpfile"
        return 1
    fi

    echo "Adding key to pacman keyring..."
    sudo pacman-key --add "$tmpfile" || {
        echo "pacman-key --add failed"
        rm -f "$tmpfile"
        return 1
    }

    echo "Locally signing the key..."
    sudo pacman-key --lsign-key "$CHAOTIC_KEY_ID" || {
        echo "pacman-key --lsign-key failed"
        rm -f "$tmpfile"
        return 1
    }

    echo "Key installed and signed."
    rm -f "$tmpfile"
    return 0
}

write_chaotic_pacman() {
    if ! grep -q '\[chaotic-aur\]' /etc/pacman.conf; then
        echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
        log INFO "Chaotic AUR repo added to pacman.conf."
    else
        log INFO "Chaotic AUR repo already configured."
    fi
    sudo pacman -Sy --noconfirm || { log ERROR "Failed to sync pacman databases."; return 1; }
}

install_packages() {
    log INFO "Installing packages..."
    sudo pacman -S --needed --noconfirm "${PACMAN[@]}" ||
        { log ERROR "Failed to install Pacman packages."; return 1; }
    command -v tldr &>/dev/null && tldr --update ||
        log WARNING "Failed to update tldr cache."

    if command -v paru &>/dev/null; then
        log INFO "Installing AUR packages with paru..."
        paru -S --needed --noconfirm "${AUR[@]}" ||
            log ERROR "Failed to install AUR packages."
    else
        log WARNING "paru not found; skipping AUR package installation."
    fi
}

chaos_remaining_packages() {
    is_chaotic_key_installed || setup_chaotic_keys
    is_chaotic_key_installed || install_chaotic_key_from_github
    install_chaotic_keyring
    write_chaotic_pacman
    install_packages
}
