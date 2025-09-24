enable_user_services() {
    mapfile -t USER_UNITS < <(systemctl --user list-unit-files \
        --type=service,timer,socket --no-legend | awk '{print $1}')
    for unit in "${SERV_USER_ENABLE[@]}"; do
        if [[ " ${USER_UNITS[*]} " =~ " ${unit} " ]]; then
            systemctl --user enable "$unit"
        else
            log WARNING "User unit $unit not found"
        fi
    done
}
