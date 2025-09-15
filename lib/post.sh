# --- Configuration ---
DBEAVER_DELAY="${DBEAVER_DELAY:-60}"
DEFAULT_DELAY=5
PROFILE_CHECK_TIMEOUT=30

# --- Sourcing Hidden Variables ---
decrypt_and_source_secrets() {
    # Check if the GPG secret file exists
    if [[ ! -f "$MY_PASS" ]]; then
        log_error "GPG file '$MY_PASS' does not exist."
    fi

    local tmpfile
    tmpfile=$(mktemp) || log_error "Failed to create temporary file."
    ensure_mode "$tmpfile" 600

    # Decrypt the secrets using GPG
    if ! gpg --quiet --decrypt "$MY_PASS" > "$tmpfile"; then
        rm -f "$tmpfile"
        log_error "Failed to decrypt secrets."
    fi

    source "$tmpfile"
    rm -f "$tmpfile"

    # Check if the passphrase is set after decryption
    if [[ -z "${MY_PASS:-}" ]]; then
        log_error "MY_PASS variable is not set after decryption."
    fi
}

# --- Utilities ---
run_temp_app() {
    local cmd="$1"
    local delay="${2:-$DEFAULT_DELAY}"
    local pid

    require_cmd "$cmd"

    log_info "Launching '$cmd' for $delay seconds."
    "$cmd" &
    pid=$!
    sleep "$delay"
    kill "$pid" 2>/dev/null || log_info "Process '$cmd' (PID: $pid) already terminated."

    # Force kill if the process is still running after the sleep
    sleep 2
    if kill -0 "$pid" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null || true
        log_info "Process '$cmd' (PID: $pid) killed forcibly."
    fi

    wait "$pid" 2>/dev/null || true
}

# Wait for Betterbird to create its profile, used in symlink_profile_contents
create_and_find_betterbird_profile_dir() {

    log_info "Waiting for Betterbird to create a valid profile folder..."

    # Loop until we either find a valid profile or time out
    while [[ $elapsed -lt $$PROFILE_CHECK_TIMEOUT ]]; do
        # Check if we have a profile folder with files or the *default-default folder
        dynamic_profile_dir=$(find "$betterbird_home_dir" -maxdepth 1 -type d -name '*.default-default' | head -n1)

        if [[ -z "$dynamic_profile_dir" ]]; then
            # If no *default-default, find the folder with the most files
            dynamic_profile_dir=$(find "$betterbird_home_dir" -maxdepth 1 -type d | \
                sort -n -k2 | \
                tail -n1)
        fi

        # If we found a valid profile folder with files, we're good to go
        if [[ -n "$dynamic_profile_dir" && -d "$dynamic_profile_dir" && -n "$(ls -A "$dynamic_profile_dir")" ]]; then
            log_info "Found a valid Betterbird profile directory: $dynamic_profile_dir"
            return 0  # Exit successfully if we find a valid profile folder
        fi

        # Otherwise, keep waiting and increment the elapsed time
        sleep "$sleep_interval"
        ((elapsed += sleep_interval))
    done

    log_error "Timeout ($$PROFILE_CHECK_TIMEOUT seconds) waiting for Betterbird profile creation."
}

# Symlink profile contents from the stow directory to the dynamic profile directory
symlink_profile_contents() {
    local $PROFILE_CHECK_TIMEOUT=$PROFILE_CHECK_TIMEOUT
    betterbird_dots_dir=$(echo "$HOME/Lit/dotfiles/.thunderbird/*default")  # Wildcard expansion
    betterbird_home_dir="$HOME/.thunderbird"
    local elapsed=0
    local sleep_interval=1
    local dynamic_profile_dir

    create_and_find_betterbird_profile_dir
    # Assuming wait_for_profile_creation already identified the correct profile folder
    if [[ -z "$dynamic_profile_dir" ]]; then
        log_error "No valid Betterbird profile directory found. Cannot proceed with symlink."
    fi

    if [[ ! -d "$betterbird_dots_dir" ]]; then
        log_error "Stow directory '$betterbird_dots_dir' not found."
    fi

    log_info "Symlinking profile contents from '$betterbird_dots_dir' to '$dynamic_profile_dir'."

    # Loop through files in the source directory and symlink to target
    for file in "$betterbird_dots_dir"/*; do
        if [[ -d "$file" ]]; then
            continue
        fi

        # Define target file path in dynamic profile dir
        local target_file="$dynamic_profile_dir/$(basename "$file")"

        # Create the target directory if it doesn't exist
        local target_dir_file=$(dirname "$target_file")
        if [[ ! -d "$target_dir_file" ]]; then
            log_info "Creating directory '$target_dir_file'."
            mkdir -p "$target_dir_file" || log_error "Failed to create directory '$target_dir_file'."
        fi

        # Create the symlink (force overwrite if already exists)
        ln -sfv "$file" "$target_file" || log_error "Failed to symlink '$file' to '$target_file'."
        log_info "Symlinked '$file' to '$target_file'."
    done
}

# --- Setup and Prepare ---
setup_and_prepare() {
    log_info "Running pre-flight checks and setup."

    require_cmd "$cmd"

    log_info "Stowing static Betterbird configuration."
    (cd "$betterbird_dots_dir" && stow -t "$HOME" --no-fold betterbird-static) || log_error "Failed to stow static Betterbird files."

    log_info "Launching Betterbird to generate dynamic profile folder."
    betterbird &>/dev/null &
    local pid=$!

    # Wait for profile creation before proceeding with symlink
    wait_for_profile_creation

    # Once the profile is detected, kill Betterbird process
    kill "$pid" 2>/dev/null || true

    # Symlink profile contents to Betterbird's dynamic profile
    symlink_profile_contents
}

# Launch main applications
launch_applications() {
    log_info "Launching main applications..."

    # Ensure required applications are available
    for cmd in wl-copy brave protonmail-bridge steam-native-runtime dbeaver betterbird; do
        require_cmd "$cmd"
    done

    # Copy the passphrase to clipboard
    echo "$MY_PASS" | wl-copy || log_error "Failed to copy password to clipboard."

    # Launch the main applications
    brave &>/dev/null &
    protonmail-bridge &>/dev/null &
    steam-native-runtime &>/dev/null &
    betterbird &>/dev/null &

    # Launch DBeaver for a defined delay
    run_temp_app dbeaver "$DBEAVER_DELAY"
}

# --- Main ---
main() {
    setup_and_prepare
    decrypt_and_source_secrets
    launch_applications

    # Clear sensitive data after use
    unset MY_PASS
    log_info "Script completed successfully."
}

# Trap any unexpected errors and display a message
trap 'log_error "Script terminated unexpectedly."' ERR

# Run the main function
main "$@"
