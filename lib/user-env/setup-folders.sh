create_custom_folders() {
    for folder in "${!CUSTOM_FOLDERS[@]}"; do
        mkdir -p "$folder"
        echo -e "[Desktop Entry]\nIcon=${CUSTOM_FOLDERS[$folder]}" > "$folder/.directory"
    done
}

remove_xdg_dirs() {
    for xdg_var in "${REMOVE_XDG_DIRS[@]}"; do
        rm -rf "$xdg_var"
        sed -i "/^$xdg_var=/d" "$HOME/.config/user-dirs.dirs"
    done
}

add_xdg_dirs () {
    # Add missing custom XDG entries
    for entry in "${CUSTOM_XDG_ENTRIES[@]}"; do
        local key="${entry%%=*}"
        if ! grep -q "^$key=" "$HOME/.config/user-dirs.dirs"; then
            echo "$entry" >>"$HOME/.config/user-dirs.dirs"
        fi
    done
}

setup_folders() {
    local folder_flag="$HOME/.cache/fresh/user_folders.done"

    if [ -f "$folder_flag" ]; then
        log INFO "Folder setup already completed, skipping..."
        return
    fi
    log INFO "Creating folders on disk."
    create_custom_folders
    log INFO "Configuring XDG folders."
    xdg-user-dirs-update
    remove_xdg_dirs
    add_xdg_dirs
    xdg-user-dirs-update

    touch "$folder_flag"
}
