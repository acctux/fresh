# Helpers
prompt_for_mariadb() {
    local password confirmation
    while true; do
        read -r -s -p "Enter new MariaDB root password: " password
        echo
        read -r -s -p "Confirm new MariaDB root password: " confirmation
        echo
        [[ "$password" == "$confirmation" && -n "$password" ]] && { echo "$password"; return 0; }
        log WARNING "Passwords do not match or are empty. Try again."
    done
}

# Main
setup_mariadb() {
    check_cmd mariadb || { log ERROR "MariaDB not installed."; return 1; }
    local db_data_dir="/var/lib/mysql"

    if [[ ! -d "$db_data_dir" ]]; then
        log INFO "Initializing MariaDB data directory..."
        # Use DB_USER and DB_BASE_DIR from config.sh
        sudo mariadb-install-db --user="$DB_USER" --basedir="/usr/" --datadir="$db_data_dir" ||
            { log ERROR "MariaDB init failed."; return 1; }
    else
        log INFO "MariaDB data directory exists."
    fi

    log INFO "Starting MariaDB service..."
    sudo systemctl start mariadb || { log ERROR "Failed to start MariaDB."; return 1; }

    local timeout=60
    while [[ "$timeout" -gt 0 ]]; do
        sudo mariadb -e "SELECT 1;" &>/dev/null && break
        sleep 1
        timeout=$((timeout - 1))
    done
    [[ "$timeout" -eq 0 ]] && { log ERROR "MariaDB failed to start."; return 1; }

    if sudo mariadb -u root -e "QUIT" 2>/dev/null; then
        log INFO "Setting MariaDB root password..."
        local db_root_password
        db_root_password=$(prompt_for_mariadb)
        sudo mariadb -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$db_root_password';" ||
            log ERROR "Failed to set MariaDB root password."
    else
        log INFO "MariaDB root user already configured."
    fi
}
