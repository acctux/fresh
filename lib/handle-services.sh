enable_services() {
    log INFO "Managing services..."
    for service in "${SERVENABLE[@]}"; do
        if systemctl status "$service.service" &>/dev/null; then
            sudo systemctl enable "$service" && log INFO "Enabled $service" ||
                log WARNING "Failed to enable $service"
        else
            log WARNING "Service $service not found."
        fi
    done
}

disable_services() {
    for service in "${SERVDISABLE[@]}"; do
        if systemctl status "$service.service" &>/dev/null; then
            sudo systemctl disable "$service" && log INFO "Disabled $service"
        else
            log WARNING "Service $service not found."
        fi
    done
}

mask_services() {
    log INFO "Masking services..."
    for service in "${SERVMASK[@]}"; do
        if systemctl status "$service.service" &>/dev/null; then
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

handle_services() {
    enable_services
    disable_services
    mask_services
    enable_user_services
    cleanup_files
}
