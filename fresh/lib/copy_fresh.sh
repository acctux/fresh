copy_fresh_to_new_home() {
    info "Copying Fresh to new install."
    cp -r "~/fresh" "/mnt/home/$USERNAME"
    chown -R $USERNAME:$USERNAME /mnt/home/$USERNAME/fresh
    chmod 700 /mnt/home/$USERNAME/fresh
    find /mnt/home/$USERNAME/fresh -type f -exec chmod 600 {} \;
}
