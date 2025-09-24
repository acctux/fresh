add_groups() {
    local existing_groups
    local target_groups=()

    # Get list of all group names on the system
    mapfile -t existing_groups < <(cut -d: -f1 /etc/group)

    for group in "${USER_GROUPS[@]}"; do
        # Skip commented-out groups
        [[ "$group" =~ ^# ]] && continue

        # Check if the group exists
        if printf '%s\n' "${existing_groups[@]}" | grep -qx "$group"; then
            target_groups+=("$group")
        fi
    done

    if [ "${#target_groups[@]}" -gt 0 ]; then
        sudo usermod -aG "$(IFS=,; echo "${target_groups[*]}")" "$USER"
    fi
}
