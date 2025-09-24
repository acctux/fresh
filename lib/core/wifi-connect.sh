# Constants
WIFI_SCAN_WAIT=8
STATION="wlan0"

# ---- Helpers -------
# Check if system is online
check_online() {
    local ping_count=5
    local ping_interval=1
    local ping_target="1.1.1.1"

    ping -q -c "$ping_count" -W "$ping_interval" "$ping_target" &>/dev/null
    return $?
}

# Prompt user for Wi-Fi credentials and connect
connect_interactively() {
    log INFO "Scanning for network, waiting $WIFI_SCAN_WAIT seconds."
    iwctl station $STATION scan &>/dev/null
    sleep "$WIFI_SCAN_WAIT"
    iwctl station $STATION get-networks

    local ssid password

    read -r -p "Enter Wi-Fi SSID: " ssid
    echo
    read -r -s -p "Enter Wi-Fi password (input hidden): " password
    echo
    iwctl --passphrase "$password" station "$STATION" connect "$ssid" &>/dev/null
}

# Master Wi-Fi connect handler
wifi_connect() {
    if check_online; then
        log INFO "Already online, skipping Wi-Fi setup."
        return
    fi
    while ! check_online; do
        connect_interactively
    done
    log INFO "Internet connection established."
    return 0
}
