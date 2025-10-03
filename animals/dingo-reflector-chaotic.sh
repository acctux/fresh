#######################################
# UPDATING TEXT FILES
#######################################

update_reflector() {
    mirrorlist="/etc/pacman.d/mirrorlist"
    arch-chroot "$MOUNT_POINT" reflector \
  		--country $COUNTRY_CODE \
		--protocol https \
		--completion-percent 100 \
		--latest 20 \
		--sort rate \
		--threads 8 \
		--download-timeout 3 \
		--save $mirrorlist
}

update_reflector_conf() {
    mirrorlist="/etc/pacman.d/mirrorlist"
    info "Writing reflector configuration."
	cat > "$MOUNT_POINT"/etc/xdg/reflector/reflector.conf <<- EOF
--country $COUNTRY_CODE \
--protocol https \
--completion-percent 100 \
--latest 20 \
--sort rate \
--threads 8 \
--download-timeout 3 \
--save $mirrorlist
EOF
    echo "Reflector configuration updated successfully"
}

update_wifi_regdom() {
    local regdom_cfg=""$MOUNT_POINT"/etc/modprobe.d/cfg80211.conf"
    if [[ -f "$regdom_cfg" ]]; then
        if grep -q '^options\s\+cfg80211\s\+ieee80211_regdom=".*"' "$regdom_cfg"; then
            # Replace the line
            sed -i "s/^options\s\+cfg80211\s\+ieee80211_regdom=\".*\"/options cfg80211 ieee80211_regdom=$COUNTRY_CODE/" "$regdom_cfg"
        else
            # Append
            echo "options cfg80211 ieee80211_regdom=$COUNTRY_CODE" >> "$regdom_cfg"
        fi
    else
        # File doesn't exist: create it
        echo "options cfg80211 ieee80211_regdom=$COUNTRY_CODE" > "$regdom_cfg"
    fi
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

edit_pacman_conf() {
    local pacman_conf="$MOUNT_POINT/etc/pacman.conf"

    # Add chaotic-aur repo if not present
    if ! grep -q '\[chaotic-aur\]' "$pacman_conf"; then
        echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | tee -a "$pacman_conf"
        log INFO "Chaotic AUR repo added to pacman.conf."
    fi

    # Update ParallelDownloads and handle Color/ILoveCandy in one sed pass
    sed -i -e 's/^ParallelDownloads *=.*/ParallelDownloads = 10/' \
        -e '/^#?\s*Color\s*$/ { s/^#//; a ILoveCandy; }' "$pacman_conf"
}

dingo() {
    update_reflector
    update_reflector_conf
    chaotic_repo
    edit_pacman_conf
}
