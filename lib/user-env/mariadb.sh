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
install_db() {
    local db_data_dir="/var/lib/mysql"

    if [[ ! -d "$db_data_dir" ]]; then
        log INFO "Initializing MariaDB data directory..."
        sudo mariadb-install-db --user="$USER" --basedir="/usr/" --datadir="$db_data_dir"
    fi
}
set_db_password() {
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
# Main
setup_mariadb() {
    sudo systemctl start mariadb
    install_db
    log INFO "Starting MariaDB service..."
    set_db_password
}
