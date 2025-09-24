readonly ICON_DIR="$HOME/.local/share/icons/WhiteSur-grey-dark"

install_whitesur_icons() {
    log INFO "Installing icon theme..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    git clone "$ICON_REPO" "$tmp_dir"
    (
        cd "$tmp_dir"
        ./install.sh -t grey
    )
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
}

install_icons() {
    if [[ ! -d "$ICON_DIR" ]]; then
        install_whitesur_icons
        rm -rf "$tmp_dir" "$HOME/.local/share/icons/WhiteSur-grey-light"
        change_icon_color
        log INFO "Icon color changed."
        rm -f "$HOME/.local/share/icons/WhiteSur-grey/apps/scalable/preferences-system.svg" || true
    else
        log INFO "WhiteSur icons already installed. Skipping."
    fi
}
