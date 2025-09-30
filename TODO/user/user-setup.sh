bootloader_time() {
    sudo sed -i 's/timeout 3/timeout 1/' /boot/loader/loader.conf
}
ensure_root_label() {
    local mount_point="/"
    local current_label
    current_label=(blkid -s LABEL -o value "$(findmnt -n -o SOURCE $mount_point)")
    [[ "$current_label" != "$ROOT_LABEL" ]] &&
        sudo btrfs filesystem label "$mount_point" "$ROOT_LABEL" &&
        log INFO "Set root label to $ROOT_LABEL" ||
        log INFO "Root label already set to $ROOT_LABEL"
}

refresh_caches() {
    local cache_update_flag="$HOME/.cache/fresh/refresh_cache.done"

    if [ ! -f "$cache_update_flag" ]; then
        XDG_MENU_PREFIX=arch- kbuildsycoca6
        log INFO "kbuildsycoca6 ran successfully."
    	fc-cache -f
	if command -v tldr &>/dev/null; then
	    tldr --update || true
	fi
    	touch "$cache_update_flag"
    fi
    echo "kbuildsycoca6 already ran, skipping."
}

change_shell() {
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    [[ "$current_shell" != "/bin/zsh" ]] && chsh -s /bin/zsh && log INFO "Shell set to zsh."
}

user_setup() {
    bootloader_time
    ensure_root_label
    refresh_caches
    change_shell
}
