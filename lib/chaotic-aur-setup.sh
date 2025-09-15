readonly CHAOTIC_KEY_ID="3056513887B78AEB"

sign_chaotic_key() {
    log INFO "Locally signing Chaotic AUR key..."
    sudo pacman-key --lsign-key "$CHAOTIC_KEY_ID" || {
        log ERROR "Failed to sign Chaotic AUR key."
        return 1
    }
    return 0
}

chaotic_key_installed() {
    if sudo pacman-key --list-keys "$CHAOTIC_KEY_ID" &>/dev/null; then
        if gpg --homedir /etc/pacman.d/gnupg --list-sigs "$CHAOTIC_KEY_ID" 2>/dev/null | grep -q "^\s*sig\s*L"; then
            log INFO "Chaotic AUR GPG key is installed and locally signed."
            return 0
        else
            log INFO "Chaotic AUR GPG key is installed but not locally signed. Attempting to sign..."
            sign_chaotic_key || return 1
            return 0
        fi
    else
        log INFO "Chaotic AUR GPG key not found."
        return 1
    fi
}

chaotic_key() {
    log INFO "Attempting to retrieve Chaotic AUR key from keyservers..."
    local keyservers=(
        keyserver.ubuntu.com
        pgp.mit.edu
    )

    for ks in "${keyservers[@]}"; do
        log INFO "Trying keyserver: $ks"
        if sudo pacman-key --recv-key "$CHAOTIC_KEY_ID" --keyserver "$ks"; then
            log INFO "Successfully retrieved key from $ks"
            sign_chaotic_key || return 1
            return 0
        fi
    done
    return 1
}

chaotic_key_from_github() {
    log INFO "Attempting to download Chaotic AUR key from GitHub..."
    local key_url="https://raw.githubusercontent.com/chaotic-aur/keyring/master/chaotic.gpg"
    local tmpfile

    tmpfile=$(mktemp /tmp/chaotic_gpg.XXXXXX) || {
        log ERROR "Failed to create temporary file."
        return 1
    }

    if curl -fLo "$tmpfile" "$key_url"; then
        log INFO "Downloaded key to $tmpfile"
    else
        log ERROR "Failed to download Chaotic GPG key from GitHub."
        rm -f "$tmpfile"
        return 1
    fi

    log INFO "Adding key to pacman keyring..."
    sudo pacman-key --add "$tmpfile" || {
        log ERROR "pacman-key --add failed."
        rm -f "$tmpfile"
        return 1
    }

    sign_chaotic_key || {
        rm -f "$tmpfile"
        return 1
    }

    log INFO "Key installed and signed."
    rm -f "$tmpfile"
    return 0
}

init_chaotic_aur() {
    if ! pacman -Qs chaotic-keyring > /dev/null || ! pacman -Qs chaotic-mirrorlist > /dev/null; then
        log INFO "Installing Chaotic AUR keyring and mirrorlist..."
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

write_chaotic_pacman() {
    if ! grep -q '\[chaotic-aur\]' /etc/pacman.conf; then
        echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
        log INFO "Chaotic AUR repo added to pacman.conf."
    else
        log INFO "Chaotic AUR repo already configured."
    fi
    sudo pacman -Sy --noconfirm || { log ERROR "Failed to sync pacman databases."; return 1; }
}

chaotic_aur_setup() {
    if ! chaotic_key_installed; then
        chaotic_key || chaotic_key_from_github
    fi
    init_chaotic_aur
    write_chaotic_pacman
}
