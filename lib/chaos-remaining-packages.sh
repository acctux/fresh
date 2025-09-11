setup_chaotic_keys() {
    log INFO "Setting up Chaotic AUR repository..."
    local key_id="3056513887B78AEB"

    # Check if the key is already installed
    if sudo pacman-key --list-keys "$key_id" &>/dev/null; then
        log INFO "Chaotic AUR key is already installed. Skipping key retrieval."
    else
        log INFO "Chaotic AUR key not found. Retrieving key..."
        local keyservers=(
            keyserver.ubuntu.com
            pgp.mit.edu
        )

        for ks in "${keyservers[@]}"; do
            log INFO "Trying keyserver: $ks"
            if sudo pacman-key --recv-key "$key_id" --keyserver "$ks"; then
                log INFO "Successfully retrieved key from $ks"
                break
            fi
        done
    fi

    if ! sudo pacman-key --list-keys | grep -q "$key_id"; then
        sudo pacman-key --lsign-key "$key_id" || {
            log ERROR "Failed to sign Chaotic AUR key."
            return 1
        }
    else
        log INFO "Chaotic AUR key already signed."
    fi
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

paru_chaotic_fallback() {
    if ! command -v paru &>/dev/null; then
        sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/paru.git /tmp/paru
        cd /tmp/paru || return 1
        makepkg -si --noconfirm
        cd - >/dev/null || return 1
        rm -rf /tmp/paru
    fi
    # Install keyring and mirrorlist from AUR
    paru -S --noconfirm chaotic-keyring chaotic-mirrorlist || {
        echo "Failed to install keyring and mirrorlist from AUR."
        return 1
    }
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
    setup_chaotic_keys || paru_chaotic_fallback
    install_chaotic_keyring || paru_chaotic_fallback
    write_chaotic_pacman || true

    install_packages
}
