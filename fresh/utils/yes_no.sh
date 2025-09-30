yes_no_prompt() {
    # Ask a yes/no question until the user enters y or n
    local prompt="$1"
    local reply
    while true; do
        if ! read -rp "$prompt [y/n]: " reply; then
            fatal "Input aborted"
        fi
        case "$reply" in
            [Yy]) return 0 ;;
            [Nn]) return 1 ;;
        esac
        warning "Please answer 'y' or 'n'."
    done
}
