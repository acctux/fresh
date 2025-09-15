cleanup_files() {
    log INFO "Cleaning up user files..."
    for item in "${CLEANUP_USER_ITEMS[@]}"; do
        if [[ -e "$item" ]]; then
            rm -rf "$item"
            log INFO "Removed: $item"
        else
            log WARNING "Item not found: $item"
        fi
    done

    log INFO "Cleaning up system files (sudo)..."
    for item in "${CLEANUP_SUDO_ITEMS[@]}"; do
        if [[ -e "$item" ]]; then
            sudo rm -rf "$item"
            log INFO "Removed (sudo): $item"
        else
            log WARNING "Item not found (sudo): $item"
        fi
    done
}

hide_apps() {
    echo "Backing up and hiding desktop files to: $BACKUP_DIR"

    mkdir -p "$BACKUP_DIR"

    for FILE in "${HIDE_APP_FILES[@]}"; do
        if [[ -f "$FILE" ]]; then
            if ! grep -q '^NoDisplay=true' "$FILE"; then
                echo "Hiding $(basename "$FILE")..."
                echo -e "\nNoDisplay=true" | sudo tee -a "$FILE" >/dev/null
            else
                echo "$(basename "$FILE") already hidden."
            fi
        else
            echo "$(basename "$FILE") not found."
        fi
    done

    if command -v update-desktop-database >/dev/null 2>&1; then
        echo "Updating desktop database..."
        sudo update-desktop-database /usr/share/applications/
    fi
}

cleanup_and_autorun() {
    cleanup_files
    hide_apps
}
