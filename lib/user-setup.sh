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
    if command -v kbuildsycoca6 &>/dev/null; then
        XDG_MENU_PREFIX=arch- kbuildsycoca6 || log WARNING "Failed to update KDE menu cache."
        # prevent script exit on failure
        true
    else
        log WARNING "kbuildsycoca6 not found."
    fi
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
    local src_color="dedede"
    local dst_color="d3dae3"

    if command -v rg &>/dev/null && command -v xmlstarlet &>/dev/null; then
        log INFO "Replacing icon colors with rg and xmlstarlet..."

        rg --files-with-matches "$src_color" "$ICON_DIR" \
            --glob '*.svg' \
            --glob '!*scalable/*' \
        | while IFS= read -r file; do
            xmlstarlet ed -L \
                -u "//@fill[.='$src_color']" -v "$dst_color" \
                -u "//@stroke[.='$src_color']" -v "$dst_color" \
                "$file"
        done

    else
        log INFO "Replacing icon colors with find and sed fallback..."

        find "$ICON_DIR" -type f -name "*.svg" ! -path "*/scalable/*" \
        -exec grep -q "$src_color" {} \; -exec \
            sed -i "s/$src_color/$dst_color/g" {} +
    fi

    rm -f "$HOME/.local/share/icons/WhiteSur-grey/apps/scalable/preferences-system.svg" || true
}

user_setup() {
    ensure_root_label
    setup_folders
    refresh_caches
    change_shell
    install_whitesur_icons
    change_icon_color
}
