# Constants
PING_TARGET="1.1.1.1"
PING_COUNT=3
PING_INTERVAL=1
WIFI_SCAN_WAIT=10

# Check if system is online
check_online() {
    ping -q -c "$PING_COUNT" -W "$PING_INTERVAL" "$PING_TARGET" &>/dev/null
    return $?
}

# Connect using saved Wi-Fi variables
connect_with_loaded_credentials() {
    if [[ -z "${DEFAULT_WIFI_SSID:-}" || -z "${DEFAULT_WIFI_PASS:-}" ]]; then
        log ERROR "Wi-Fi credentials are not loaded in memory."
        return 1
    fi

    log INFO "Scanning for network: $DEFAULT_WIFI_SSID (wait $WIFI_SCAN_WAIT seconds)..."
    nmcli device wifi rescan &>/dev/null
    sleep "$WIFI_SCAN_WAIT"

    if ! nmcli -f SSID dev wifi list | grep -qF "$DEFAULT_WIFI_SSID"; then
        log ERROR "Wi-Fi network '$DEFAULT_WIFI_SSID' not found."
        return 1
    fi

    log INFO "Connecting to $DEFAULT_WIFI_SSID..."
    if nmcli device wifi connect "$DEFAULT_WIFI_SSID" password "$DEFAULT_WIFI_PASS" &>/dev/null; then
        log INFO "Connected to Wi-Fi."
        # Unset sensitive variables after successful connection
        unset DEFAULT_WIFI_SSID
        unset DEFAULT_WIFI_PASS
        return 0
    else
        log ERROR "Failed to connect to Wi-Fi."
        return 1
    fi
}

# Prompt user for Wi-Fi credentials and connect
connect_interactively() {
    log INFO "Starting interactive Wi-Fi connection. Scanning $WIFI_SCAN_WAIT seconds..."
    nmcli device wifi rescan &>/dev/null || log WARNING "Wi-Fi rescan failed."
    sleep "$WIFI_SCAN_WAIT"

    log INFO "Available Wi-Fi networks:"
    nmcli device wifi list

    local ssid password
    while [[ -z "${ssid:-}" ]]; do
        read -r -p "Enter Wi-Fi SSID: " ssid
        [[ -n "$ssid" ]] || log ERROR "SSID cannot be empty."
    done

    read -r -s -p "Enter Wi-Fi password (input hidden): " password
    echo
    if [[ -z "$password" ]]; then
        log ERROR "No password provided."
        return 1
    fi

    nmcli device wifi connect "$ssid" password "$password" &>/dev/null
    return $?
}

# Master Wi-Fi connect handler
wifi_connect() {
    if check_online; then
        log INFO "Already online. Skipping Wi-Fi setup."
        return 0
    fi

    check_cmd nmcli
    log INFO "Attempting to connect to Wi-Fi with NetworkManager."
    connect_with_loaded_credentials || connect_interactively

    if check_online; then
        log INFO "Internet connection established."
        return 0
    fi

    log ERROR "Failed to establish internet connection."
    return 1
}
