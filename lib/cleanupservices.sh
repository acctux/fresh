#!/usr/bin/env bash

enable_services() {
    log INFO "Managing services..."
    for service in "${SERVENABLE[@]}"; do
        systemctl list-unit-files "$service.service" &>/dev/null &&
            sudo systemctl enable "$service" && log INFO "Enabled $service" ||
            log WARNING "Service $service not found."
    done
}

disable_services() {
    for service in "${SERVDISABLE[@]}"; do
        systemctl list-unit-files "$service.service" &>/dev/null &&
            sudo systemctl disable "$service" && log INFO "Disabled $service" ||
            log WARNING "Service $service not found."
    done
}
mask_services() {
    log INFO "Masking services..."
    for service in "${SERVMASK[@]}"; do
        if systemctl list-unit-files "$service" &>/dev/null; then
            sudo systemctl stop "$service" &>/dev/null
            sudo systemctl mask "$service"
            log INFO "Stopped and masked $service"
        else
            log WARNING "Service $service not found."
        fi
    done
}

enable_user_services() {
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
    enable_services
    disable_services
    mask_services
    enable_user_services
    cleanup_files
}
