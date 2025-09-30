user_services() {
    local unit
    mapfile -t USER_UNITS < <(systemctl --user list-unit-files \
        --type=service,timer,socket --no-legend | awk '{print $1}')

    for unit in "${SERV_USER_ENABLE[@]}"; do
        if printf '%s\n' "${USER_UNITS[@]}" | grep -Fxq "$unit"; then
            systemctl --user enable "$unit"
        else
            echo "WARNING: User unit $unit not found"
        fi
    done
}
