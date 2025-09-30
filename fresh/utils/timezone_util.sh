choose_timezone() {
    info "Setting timezone. You can choose your region."
    local auto_zone
    auto_zone=$(timedatectl show --value --property=Timezone 2>/dev/null || true)
    if [[ -n "$auto_zone" ]]; then
        info "Detected current timezone: $auto_zone"
        if yes_no_prompt "Use detected timezone ($auto_zone)?"; then
            TIMEZONE="$auto_zone"
            return 0
        fi
    fi
    while true; do
        if ! read -rp "Enter your timezone (e.g. America/Chicago): " TIMEZONE; then
            fatal "Input aborted"
        fi
        [[ -f "/usr/share/zoneinfo/$TIMEZONE" ]] && break
        warning "Invalid timezone. Please choose a valid entry from /usr/share/zoneinfo."
    done
}
