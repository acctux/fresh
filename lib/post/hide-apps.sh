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
