add_user_to_groups() {
    local username="$USER"
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
        else
            echo "Group '$group' does not exist, creating it..."
            sudo groupadd "$group"
            target_groups+=("$group")
        fi
    done

    if [ "${#target_groups[@]}" -gt 0 ]; then
        echo "Adding user '$username' to groups: ${target_groups[*]}"
        sudo usermod -aG "$(IFS=,; echo "${target_groups[*]}")" "$username"
        echo "Done. You may need to log out and back in for group changes to take effect."
    else
        echo "No valid groups to add."
    fi
}
