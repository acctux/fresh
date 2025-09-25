readonly CHAOTIC_KEY_ID="3056513887B78AEB"

write_chaotic_pacman() {
    if ! grep -q '\[chaotic-aur\]' /etc/pacman.conf; then
        echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
        log INFO "Chaotic AUR repo added to pacman.conf.""
    fi
}

chaotic_key_installed() {
    if sudo pacman-key --list-keys "$CHAOTIC_KEY_ID" &>/dev/null; then
        log INFO "Chaotic Key installed."
    fi
}

init_chaotic_aur() {
        log INFO "Installing Chaotic AUR keyring and mirrorlist..."
        sudo pacman -U --needed \
            https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst \
            https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst
}

chaotic_repo() {
    write_chaotic_pacman
    if ! chaotic_key_installed; then
        sudo pacman-key --add "$HOME/Lit/dotfiles/.ssh/chaotic.gpg"
        sudo pacman-key --lsign-key "$CHAOTIC_KEY_ID"
        sign_chaotic_key
        init_chaotic_aur
        sudo pacman -Sy
    fi
}
