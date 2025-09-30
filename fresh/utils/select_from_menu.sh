select_from_menu() {
    # Generic menu selection helper
    local prompt="$1"
    shift
    local options=("$@")
    local num="${#options[@]}"
    local choice
    while true; do
        info "$prompt" >&2
        for i in "${!options[@]}"; do
            printf '%d) %s\n' "$((i+1))" "${options[i]}" >&2
        done
        if ! read -rp "Select an option (1-${num}): " choice; then
            fatal "Input aborted"
        fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= num )); then
            echo "${options[$((choice-1))]}"
            return 0
        fi
        warning "Invalid choice. Please select a number between 1 and ${num}." >&2
    done
}
