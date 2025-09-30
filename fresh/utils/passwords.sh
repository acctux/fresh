get_password() {
    local prompt="$1"
    local pass confirm
    while true; do
        if ! read -rsp "$prompt: " pass; then
            fatal "Input aborted"
        fi
        echo
        (( ${#pass} >= 4 )) || { warning "Password must be at least 4 characters long"; continue; }
        if ! read -rsp "Confirm password: " confirm; then
            fatal "Input aborted"
        fi
        echo
        [[ "$pass" == "$confirm" ]] || { warning "Passwords do not match"; continue; }
        echo "$pass"
        return 0
    done
}
