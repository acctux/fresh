readonly CHAOTIC_KEY_ID="3056513887B78AEB"

write_chaotic_pacman() {
    if ! grep -q '\[chaotic-aur\]' /etc/pacman.conf; then
        echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
        log INFO "Chaotic AUR repo added to pacman.conf."
    fi
}

init_chaotic_aur() {
        log INFO "Installing Chaotic AUR keyring and mirrorlist..."
        sudo pacman -U --needed \
            https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst \
            https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst
}

chaotic_repo() {
    if ! sudo pacman-key --list-keys "$CHAOTIC_KEY_ID" &>/dev/null; then
	    sudo pacman-key --recv-key "$CHAOTIC_KEY_ID" --keyserver keyserver.ubuntu.com
	    sudo pacman-key --lsign-key "$CHAOTIC_KEY_ID"
	    init_chaotic_aur
	    write_chaotic_pacman
	    sudo pacman -Sy    
	    log INFO "Chaotic key installed."
    else
	    log INFO "Chaotic key already installed."
	    return 0
    fi
}
