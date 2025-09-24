readonly BOOKMARKS="$HOME/.local/bin/bookmarks"
readonly GIT_LIT="$HOME/Lit"

declare -A CUSTOM_FOLDERS=(
    ["$HOME/Games"]="folder-games"
    ["$GIT_LIT"]="folder-github"
    ["$BOOKMARKS"]="folder-favorites"
)

REMOVE_XDG_DIRS=(
    "XDG_PUBLICSHARE_DIR"
    "XDG_DOCUMENTS_DIR"
    "XDG_DESKTOP_DIR"
)

# Custom XDG entries to add (format: KEY="VALUE")
CUSTOM_XDG_ENTRIES=(
    'XDG_LIT_DIR="$HOME/Lit"'
)

create_custom_folders() {
    for folder in "${!CUSTOM_FOLDERS[@]}"; do
        mkdir -p "$folder"
        echo -e "[Desktop Entry]\nIcon=${CUSTOM_FOLDERS[$folder]}" > "$folder/.directory"
    done
}

custom_xdg_folders () {
    # Add missing custom XDG entries
    for entry in "${CUSTOM_XDG_ENTRIES[@]}"; do
        local key="${entry%%=*}"
        if ! grep -q "^$key=" "$HOME/.config/user-dirs.dirs"; then
            echo "$entry" >>"$HOME/.config/user-dirs.dirs"
        fi
    done
}

remove_user_dirs() {
    log INFO "Updating XDG user directories..."

    # Remove unwanted XDG dirs
    for xdg_var in "${REMOVE_XDG_DIRS[@]}"; do
        rm -rf "$xdg_var"
        sed -i "/^$xdg_var=/d" "$HOME/.config/user-dirs.dirs"
    done
}

setup_folders() {
    local user_folder_flag="$HOME/.cache/user_folders.done"

    if [ -f "$user_folder_flag" ]; then
        log INFO "Folder setup already completed, skipping..."
        return
    fi
    xdg-user-dirs-update
    log INFO "Configuring user folders..."
    create_custom_folders
    configure_user_dirs
    xdg-user-dirs-update
    touch "$user_folder_flag"
}
