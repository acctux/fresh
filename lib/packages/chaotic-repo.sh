readonly CHAOTIC_KEY_ID="3056513887B78AEB"

chaotic_key_installed() {
    if sudo pacman-key --list-keys "$CHAOTIC_KEY_ID" &>/dev/null; then
        log INFO "Chaotic Key installed."
	return
    fi
}

chaotic_key() {
    log INFO "Trying to receive Chaotic key from keyservers"
    if ! sudo pacman-key --recv-key "$CHAOTIC_KEY_ID" --keyserver "keyserver.ubuntu.com"; then
        sudo pacman-key --recv-key "$CHAOTIC_KEY_ID" --keyserver "pgp.mit.edu"
    fi
    log INFO "Successfully retrieved Chaos key from keyservers"
}

chaotic_key_from_github() (
    local tmpfile
    tmpfile=$(mktemp /tmp/chaotic_gpg.XXXXXX)

    curl -fLo "$tmpfile" "https://raw.githubusercontent.com/chaotic-aur/keyring/master/chaotic.gpg"
    sudo pacman-key --add "$tmpfile"
)

sign_chaotic_key() {
    sudo pacman-key --lsign-key "$CHAOTIC_KEY_ID"
    return 0
}

init_chaotic_aur() {
        log INFO "Installing Chaotic AUR keyring and mirrorlist..."
        sudo pacman -U --noconfirm \
            https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst \
            https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst
}

write_chaotic_pacman() {
    if ! grep -q '\[chaotic-aur\]' /etc/pacman.conf; then
        echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
        log INFO "Chaotic AUR repo added to pacman.conf."
    else
        log INFO "Chaotic AUR repo already configured."
    fi
}

chaotic_repo() {
    chaotic_key_installed
    if ! chaotic_key; then
	 chaotic_key_from_github
    fi
    sign_chaotic_key
    init_chaotic_aur
    write_chaotic_pacman
    sudo pacman -Sy
}
