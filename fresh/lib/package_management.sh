#######################################
# System installation functions
#######################################
install_base_system() {
    info "Installing base system (minimal)"
    pacman -Sy --noconfirm
    pacstrap "$MOUNT_POINT" "${LINUX_PAC[@]}"
    success "Base system installed successfully"
    pacstrap "$MOUNT_POINT" "${BASE_PAC[@]}"
    success "Base system installed successfully"
}

chaotic_repo() {
    local chaotic_key_id="3056513887B78AEB"

    info "Adding Chaotic AUR GPG key."

    arch-chroot "$MOUNT_POINT" pacman-key --init
    arch-chroot "$MOUNT_POINT" pacman-key --recv-key "$chaotic_key_id" --keyserver keyserver.ubuntu.com
    arch-chroot "$MOUNT_POINT" pacman-key --lsign-key "$chaotic_key_id"

    info "Installing Chaotic AUR keyring and mirrorlist in chroot..."
    arch-chroot "$MOUNT_POINT" pacman -U --noconfirm --needed \
        https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst \
        https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst

    success "Chaotic AUR repository initialized."
}

configure_pacman() {
    info "Configuring pacman"
    local pacman_conf="$MOUNT_POINT/etc/pacman.conf"

    # Uncomment [multilib], set ParallelDownloads = 10,
    #  Append [chaotic-aur] repo
    sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' "$pacman_conf"
    sed -i 's/^ParallelDownloads *= *.*/ParallelDownloads = 10/' "$pacman_conf"
    echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> "$pacman_conf"

    arch-chroot "$MOUNT_POINT" pacman -Sy --noconfirm
    success "Pacman configured successfully"
}

install_additional_packages() {
    info "Installing additional packages"
    arch-chroot "$MOUNT_POINT" pacman -S --noconfirm "${FRESH_PAC[@]}"
    success "Additional packages installed successfully"
}
