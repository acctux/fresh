ensure_root_label() {
    local mount_point="/"
    local current_label
    current_label=$(blkid -s LABEL -o value "$(findmnt -n -o SOURCE "$mount_point")" 2>/dev/null || echo "")
    [[ "$current_label" != "$ROOT_LABEL" ]] &&
        sudo btrfs filesystem label "$mount_point" "$ROOT_LABEL" &&
        log INFO "Set root label to $ROOT_LABEL" ||
        log INFO "Root label already set to $ROOT_LABEL"
}

setup_folders() {
    local user_folder_flag="$HOME/.cache/user_folders.done"

    if [ -f "$user_folder_flag" ]; then
        log INFO "Folder setup already completed, skipping..."
        return
    fi

    log INFO "Configuring user settings..."
    xdg-user-dirs-update
    sed -i '/^XDG_PUBLICSHARE_DIR=/d' "$HOME/.config/user-dirs.dirs"
    grep -q '^XDG_LIT_DIR=' "$HOME/.config/user-dirs.dirs" ||
        echo 'XDG_LIT_DIR="$HOME/Lit"' >>"$HOME/.config/user-dirs.dirs"
    mkdir -p "$HOME/Games"
    echo -e "[Desktop Entry]\nIcon=folder-games" >"$HOME/Games/.directory"
    xdg-user-dirs-update

    touch "$user_folder_flag"
}

refresh_caches() {
    local cache_update_flag="$HOME/.cache/refresh_cache.done"

    if [ ! -f "$cache_update_flag" ]; then
        if XDG_MENU_PREFIX=arch- kbuildsycoca6; then
            echo "kbuildsycoca6 ran successfully."
        else
            echo "kbuildsycoca6 failed." >&2
            exit 1
        fi
    else
        echo "kbuildsycoca6 already ran, skipping."
    fi
    # don't replace with check_cmd, not critical
    if command -v tldr &>/dev/null; then
        tldr --update || log WARNING "Failed to update tldr cache."
    fi

    fc-cache -f || log WARNING "Failed to update font cache."
    touch "$cache_update_flag"
}

change_shell() {
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    [[ "$current_shell" != "/bin/zsh" ]] && chsh -s /bin/zsh && log INFO "Shell set to zsh."
}

user_setup() {
    ensure_root_label
    setup_folders
    refresh_caches
    change_shell
}
