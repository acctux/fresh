#!/usr/bin/env bash

manage_services() {
    log INFO "Managing services..."
    for service in "${SERVENABLE[@]}"; do
        systemctl list-unit-files "$service.service" &>/dev/null &&
            sudo systemctl enable "$service" && log INFO "Enabled $service" ||
            log WARNING "Service $service not found."
    done
    for service in "${SERVDISABLE[@]}"; do
        systemctl list-unit-files "$service.service" &>/dev/null &&
            sudo systemctl disable "$service" && log INFO "Disabled $service" ||
            log WARNING "Service $service not found."
    done
    systemctl --user enable pipewire pipewire-pulse wireplumber ssh-agent 2>/dev/null ||
        log WARNING "Failed to enable user services."
}

cleanup_files() {
    log INFO "Cleaning up files..."
    for item in "${CLEANUP_USER_FILES[@]}"; do
        [[ -e "$item" ]] && rm -rf "$item" && log INFO "Removed $item" ||
            log WARNING "Item $item not found."
    done
    for file in "${CLEANUP_SYS_FILES[@]}"; do
        [[ -f "$file" ]] && sudo rm -f "$file" && log INFO "Removed $file" ||
            log WARNING "File $file not found."
    done
    for dir in "${CLEANUP_SYS_DIRS[@]}"; do
        [[ -d "$dir" ]] && sudo rm -rf "$dir" && log INFO "Removed $dir" ||
            log WARNING "Directory $dir not found."
    done
}

services_and_cleanup() {
    manage_services
    cleanup_files
}
