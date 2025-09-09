#!/usr/bin/env bash

BACKUP_DIR="$HOME/appbackup"

HIDE_APP_FILES=(
    "/usr/share/applications/steam.desktop"
    "/usr/share/applications/octopi-cachecleaner.desktop"
    "/usr/share/applications/octopi-notifier.desktop"
    "/usr/share/applications/octopi-repoeditor.desktop"
    "/usr/share/applications/org.kde.filelight.desktop"
    "/usr/share/applications/jconsole-java-openjdk.desktop"
    "/usr/share/applications/jshell-java-openjdk.desktop"
    "/usr/share/applications/qv4l2.desktop"
    "/usr/share/applications/qvidcap.desktop"
    "/usr/share/applications/xgps.desktop"
    "/usr/share/applications/xgpsspeed.desktop"
    "/usr/share/applications/avahi-discover.desktop"
    "/usr/share/applications/mpv.desktop"
    "/usr/share/applications/nvim.desktop"
    "/usr/share/applications/bvnc.desktop"
    "/usr/share/applications/bssh.desktop"
)

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
