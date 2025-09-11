# Setup User Settings
ICON_DIR="$HOME/.local/share/icons/WhiteSur-grey-dark"

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
    log INFO "Configuring user settings..."
    xdg-user-dirs-update
    sed -i '/^XDG_PUBLICSHARE_DIR=/d' "$HOME/.config/user-dirs.dirs"
    grep -q '^XDG_LIT_DIR=' "$HOME/.config/user-dirs.dirs" ||
        echo 'XDG_LIT_DIR="$HOME/Lit"' >>"$HOME/.config/user-dirs.dirs"
    mkdir -p "$HOME/Games"
    echo -e "[Desktop Entry]\nIcon=folder-games" >"$HOME/Games/.directory"
    xdg-user-dirs-update
}

refresh_caches() {
    command -v kbuildsycoca6 &>/dev/null && XDG_MENU_PREFIX=arch- kbuildsycoca6 ||
        log WARNING "Failed to update KDE menu cache."
}

change_shell() {
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    [[ "$current_shell" != "/bin/zsh" ]] && chsh -s /bin/zsh && log INFO "Shell set to zsh."
}

install_whitesur_icons() {
    [[ -d "$ICON_DIR" ]] && { log INFO "Icon theme already installed."; return; }

    log INFO "Installing icon theme..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    git clone "$ICON_REPO" "$tmp_dir" || { log ERROR "Failed to clone icon repository."; return 1; }
    (
        cd "$tmp_dir"
        ./install.sh -t grey
    )
    rm -rf "$tmp_dir" "$HOME/.local/share/icons/WhiteSur-grey-light"
}

change_icon_color() {
    if command -v fd &>/dev/null && command -v sd &>/dev/null; then
        log INFO "Replacing icon colors with fd and sd..."
        fd -e svg --exclude '*/scalable/*' . "$ICON_DIR" | sd --string-mode "dedede" "d3dae3"
    else
        log INFO "Replacing icon colors with find and sed..."
        find "$ICON_DIR" -type f -name "*.svg" ! -path "*/scalable/*" -exec \
            sed -i 's/dedede/d3dae3/g' {} +
    fi
    rm -f "$HOME/.local/share/icons/WhiteSur-grey/apps/scalable/preferences-system.svg" || true
}

user_setup() {
    sudo sed -i 's/timeout 3/timeout 1/' /boot/loader/loader.conf
    ensure_root_label
    setup_folders
    refresh_caches
    change_shell
    install_whitesur_icons
    change_icon_color
}
