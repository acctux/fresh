bootloader_time() {
    sudo sed -i 's/timeout 3/timeout 1/' /boot/loader/loader.conf
}

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
    mkdir -p "$GIT_LIT"
    echo -e "[Desktop Entry]\nIcon=folder-games" >"$HOME/Games/.directory"
    echo -e "[Desktop Entry]\nIcon=folder-github" >"$GIT_LIT/.directory"
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

add_user_to_groups() {
    local username="$USER"
    local existing_groups
    local target_groups=()

    # Get list of all group names on the system
    mapfile -t existing_groups < <(cut -d: -f1 /etc/group)

    for group in "${USER_GROUPS[@]}"; do
        # Skip commented-out groups
        [[ "$group" =~ ^# ]] && continue

        # Check if the group is in the existing groups list
        if printf '%s\n' "${existing_groups[@]}" | grep -qx "$group"; then
            target_groups+=("$group")
        else
            echo "Group '$group' does not exist, skipping..."
        fi
    done

    if [ "${#target_groups[@]}" -gt 0 ]; then
        echo "Adding user '$username' to groups: ${target_groups[*]}"
        sudo usermod -aG "$(IFS=,; echo "${target_groups[*]}")" "$username"
        echo "Done. You may need to log out and back in for group changes to take effect."
    else
        echo "No valid groups to add."
    fi
}

user_setup() {
    bootloader_time
    ensure_root_label
    setup_folders
    refresh_caches
    change_shell
    add_user_to_groups
}
