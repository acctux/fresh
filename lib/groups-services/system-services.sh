# Export system units array (run once at script startup)
system_units_array() {
    mapfile -t SYSTEM_UNITS < <(systemctl list-unit-files --type=service,timer,socket --no-legend | awk '{print $1}')
    export SYSTEM_UNITS
}

enable_services() {
    log INFO "Enabling system units..."
    for unit in "${SERV_ENABLE[@]}"; do
        if [[ " ${SYSTEM_UNITS[*]} " =~ " ${unit} " ]]; then
            sudo systemctl enable "$unit"
        else
            log WARNING "Unit $unit not found"
        fi
    done
}

disable_services() {
    log INFO "Disabling system units..."
    for unit in "${SRV_DISABLE[@]}"; do
        if [[ " ${SYSTEM_UNITS[*]} " =~ " ${unit} " ]]; then
            sudo systemctl disable "$unit"
        else
            log WARNING "Unit $unit not found"
        fi
    done
}

mask_services() {
    log INFO "Masking system units..."
    for unit in "${SERV_MASK[@]}"; do
        if [[ " ${SYSTEM_UNITS[*]} " =~ " ${unit} " ]]; then
            # Attempt to stop and mask, but don't fail if stop doesn't work
            sudo systemctl stop "$unit" &>/dev/null || true
            sudo systemctl mask "$unit"
        else
            log WARNING "Unit $unit not found"
        fi
    done
}

handle_services() {
    system_units_array
    enable_services
    enable_user_services
    disable_services
    mask_services
}
