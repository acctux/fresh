readonly ICON_REPO="https://www.github.com/vinceliuice/WhiteSur-icon-theme.git"
readonly ICON_DIR="$HOME/.local/share/icons/WhiteSur-grey-dark"

install_whitesur_icons() {
    [[ -d "$ICON_DIR" ]] && { log INFO "Icon theme already installed."; return; }

    log INFO "Installing icon theme..."
    local tmp_dir
    tmp_dir=$(mktemp -d) || { log ERROR "Failed to create temporary directory."; return 1; }
    git clone "$ICON_REPO" "$tmp_dir" || { log ERROR "Failed to clone icon repository."; rm -rf "$tmp_dir"; return 1; }
    (
        cd "$tmp_dir" || { log ERROR "Failed to change to temporary directory."; rm -rf "$tmp_dir"; return 1; }
        ./install.sh -t grey
    )
    rm -rf "$tmp_dir" "$HOME/.local/share/icons/WhiteSur-grey-light"
}

change_icon_color() {
    local src_color="#dedede"
    local dst_color="#d3dae3"

    if check_cmd rg sd parallel; then
        log INFO "Replacing icon colors using parallel in batches..."

        rg --files-with-matches "$src_color" "$ICON_DIR" \
            --glob '*.svg' --glob '!*scalable/*' \
        | parallel --pipe --round-robin -j$(nproc) '
            while IFS= read -r file; do
                sd "'"$src_color"'" "'"$dst_color"'" "$file"
            done
        '
    else
        log INFO "Fallback: replacing icon colors with grep and sed..."

        find "$ICON_DIR" -type f -name "*.svg" ! -path "*/scalable/*" \
            -exec grep -q "$src_color" {} \; \
            -exec sed -i "s/$src_color/$dst_color/g" {} +
    fi
    log INFO "Icon color changed."
    rm -f "$HOME/.local/share/icons/WhiteSur-grey/apps/scalable/preferences-system.svg" || true
}

install_icons() {
    install_whitesur_icons
    change_icon_color
}
