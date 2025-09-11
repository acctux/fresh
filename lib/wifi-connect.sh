# Establish Internet

# Constants
readonly PING_TARGET="1.1.1.1"
readonly PING_COUNT=3
readonly PING_INTERVAL=1
readonly WIFI_SCAN_WAIT=10

# Check if system is online by pinging a target
check_online() {
    if ping -q -c "$PING_COUNT" -W "$PING_INTERVAL" "$PING_TARGET" &>/dev/null; then
        log INFO "Internet connection detected."
        return 0
    else
        log WARNING "No internet connection detected."
        return 1
    fi
}

# Connect using saved Wi-Fi configuration
connect_with_config() {
    local WIFI_CONFIG_FILE="$HOME/.ssh/wifi.env"

    if [[ ! -f "$WIFI_CONFIG_FILE" ]]; then
        log WARNING "Wi-Fi config file $WIFI_CONFIG_FILE not found."
        return 1
    fi

    log INFO "Connecting to Wi-Fi using saved config..."
    # shellcheck source=/dev/null
    source "$WIFI_CONFIG_FILE"

    if [[ -z "${DEFAULT_WIFI_SSID:-}" || -z "${DEFAULT_WIFI_PASS:-}" ]]; then
        log ERROR "Wi-Fi SSID or password not set in $WIFI_CONFIG_FILE."
        return 1
    fi

    log INFO "Performing Wi-Fi scan to locate network: $DEFAULT_WIFI_SSID. Please wait $WIFI_SCAN_WAIT seconds..."
    nmcli device wifi rescan &>/dev/null
    sleep "$WIFI_SCAN_WAIT"

    if ! nmcli -f BSSID,SSID dev wifi list | grep -q "$DEFAULT_WIFI_SSID"; then
        log ERROR "Wi-Fi network '$DEFAULT_WIFI_SSID' not found in scan results."
        return 1
    fi

    log INFO "Attempting to connect..."
    if ! nmcli device wifi connect "$DEFAULT_WIFI_SSID" password "$DEFAULT_WIFI_PASS" >/dev/null; then
        log ERROR "Failed to connect to Wi-Fi. Check password or signal strength."
        return 1
    fi

    log INFO "Connection attempt successful. Verifying internet access..."
    if check_online; then
        log INFO "Config connection succeeded."
        return 0
    fi
}


# Connect interactively by prompting for SSID and password
connect_interactively() {
    log INFO "Starting interactive Wi-Fi connection. Scanning $WIFI_SCAN_WAIT seconds."
    nmcli device wifi rescan &>/dev/null || {
        log WARNING "Wi-Fi rescan failed."
    }
    sleep "$WIFI_SCAN_WAIT"

    log INFO "Available Wi-Fi networks:"
    nmcli device wifi list

    local ssid password
    while true; do
        read -r -p "Enter Wi-Fi SSID: " ssid
        if [[ -n "$ssid" ]]; then
            break
        fi
        log ERROR "No SSID provided. Please try again."
    done

    read -r -s -p "Enter Wi-Fi password (input hidden): " password
    echo
    if [[ -z "$password" ]]; then
        log ERROR "No password provided."
        return 1
    fi

    if nmcli device wifi connect "$ssid" password "$password" &>/dev/null; then
        log INFO "Connected to Wi-Fi SSID: $ssid."
        return 0
    else
        log ERROR "Failed to connect to Wi-Fi SSID: $ssid."
        return 1
    fi
}

# Main function to manage Wi-Fi connection
wifi_connect() {

    # Check if already online
    if check_online; then
        return 0
    fi

    # Check if nmcli is installed
    if ! command -v nmcli &>/dev/null; then
        log ERROR "nmcli is not installed."
        return 1
    fi

    # Try connecting with config
    if connect_with_config && check_online; then
        return 0
    fi

    log INFO "Config-based connection failed or unavailable. Attempting interactive connection."
    if connect_interactively && check_online; then
        return 0
    fi

    log ERROR "Failed to establish internet connection."
    return 1
}
