readonly CHAOTIC_KEY_ID="3056513887B78AEB"

sign_chaotic_key() {
    sudo pacman-key --lsign-key "$CHAOTIC_KEY_ID"
    return 0
}

chaotic_key_installed() {
    if sudo pacman-key --list-keys "$CHAOTIC_KEY_ID" &>/dev/null; then
        log INFO "Chaotic Key installed."
        return 0
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
            sign_chaotic_key
        fi
    done
    return 1
}

chaotic_key_from_github() (
    local key_url="https://raw.githubusercontent.com/chaotic-aur/keyring/master/chaotic.gpg"
    local tmpfile
    tmpfile=$(mktemp /tmp/chaotic_gpg.XXXXXX)

    trap rm -f "$tmpfile" EXIT
    curl -fLo "$tmpfile" "$key_url"
    sudo pacman-key --add "$tmpfile"
    sign_chaotic_key
)

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
    chaotic_key
    chaotic_key_from_github
    init_chaotic_aur
    write_chaotic_pacman
    sudo pacman -Sy
}
