choose_timezone() {
    info "Setting timezone."
    local auto_zone
    auto_zone=$(timedatectl show --value --property=Timezone 2>/dev/null || true)
    if [[ -n "$auto_zone" ]]; then
        TIMEZONE="$auto_zone"
    else
        TIMEZONE=$DEFAULT_TIME_ZONE
    fi
    return 0
}
