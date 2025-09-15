log() {
    # Convert level to uppercase
    local level="${1^^}"
    # Shift removes the first argument ($1)
    shift

    # Timestamp format
    local timestamp
    timestamp="$(date +'%y-%m-%d %H:%M:%S')"

    # Print to stderr and append to log file (%s, placeholders for strings)
    printf "[%s] [%s] %s\n" "$timestamp" "$level" "$*" | tee -a "$LOG_FILE" >&2
}

check_cmd() {
    # 0 = all commands found
    local missing=0
    for cmd in "$@"; do
        # Uses command -v to check if the command exists in the user's PATH.
        # Redirects both stdout and stderr to /dev/null to suppress output
        if command -v "$cmd" &>/dev/null; then
            echo "'$cmd' found"
        else
            echo "'$cmd' not found"
            missing=1
        fi
    done
    # Returns 0 if all commands were found, 1 if any were missing.
    return $missing
}

ensure_owner() {
    local path="$1"
    local expected_user="$2"

    # read current owner (%U) and group (%G)
    read -r owner group < <(stat -c "%U %G" "$path")

    # The current user owner is not the expected user
    # (group name is assumed to match the username)
    if [[ "$owner" != "$expected_user" || "$group" != "$expected_user" ]]; then
        chown "$expected_user:$expected_user" "$path"
    fi
}

ensure_mode() {
    local path="$1"
    local expected_mode="$2"

    local current_mode
    # %a gives the numeric permission bits (e.g., 644, 755)
    current_mode=$(stat -c "%a" "$path")

    if [[ "$current_mode" != "$expected_mode" ]]; then
        chmod "$expected_mode" "$path"
    fi
}

reboot_prompt() {
    # -n 1 reads exactly 1 character of input (without waiting for Enter)
    # -r to prevent backslash escape
    read -p "Reboot now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      log "INFO" "Rebooting system..."
      sudo reboot
    fi
}
