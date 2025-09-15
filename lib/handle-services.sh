# Export system units array (run once at script startup)
system_units_array() {
    mapfile -t SYSTEM_UNITS < <(systemctl list-unit-files --type=service,timer,socket --no-legend | awk '{print $1}')
    export SYSTEM_UNITS

    mapfile -t USER_UNITS < <(systemctl --user list-unit-files --type=service,timer,socket --no-legend | awk '{print $1}')
    export USER_UNITS
}

enable_services() {
    log INFO "Enabling system units..."
    for unit in "${SERV_ENABLE[@]}"; do
        if [[ " ${SYSTEM_UNITS[*]} " =~ " ${unit} " ]]; then
            if sudo systemctl enable "$unit" &>/dev/null; then
                log INFO "Enabled $unit"
            else
                log WARNING "Failed to enable $unit"
            fi
        else
            log WARNING "Unit $unit not found"
        fi
    done
}

enable_user_services() {
    log INFO "Enabling user system units..."
    for unit in "${SERV_USER_ENABLE[@]}"; do
        if [[ " ${USER_UNITS[*]} " =~ " ${unit} " ]]; then
            if systemctl --user enable "$unit" &>/dev/null; then
                log INFO "Enabled user unit $unit"
            else
                log WARNING "Failed to enable user unit $unit"
            fi
        else
            log WARNING "User unit $unit not found"
        fi
    done
}

disable_services() {
    log INFO "Disabling system units..."
    for unit in "${SRV_DISABLE[@]}"; do
        if [[ " ${SYSTEM_UNITS[*]} " =~ " ${unit} " ]]; then
            if sudo systemctl disable "$unit" &>/dev/null; then
                log INFO "Disabled $unit"
            else
                log WARNING "Failed to disable $unit"
            fi
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
            if sudo systemctl mask "$unit" &>/dev/null; then
                log INFO "Masked $unit"
            else
                log WARNING "Failed to mask $unit"
            fi
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
