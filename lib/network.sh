#!/usr/bin/env bash

# Exit on errors, undefined variables, or pipeline failures
set -euo pipefail

# Constants
readonly LOG_FILE="$HOME/bootstrap.log"
readonly PING_TARGET="1.1.1.1"
readonly PING_COUNT=3
readonly PING_INTERVAL=1
readonly WIFI_SCAN_WAIT=10
readonly WIFI_CONFIG_FILE="$HOME/wifi.sh"

# Log function with timestamp and level
log() {
    local level="$1"; shift
    printf "[%s] [%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a "$LOG_FILE" >&2
}

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

# Check if nmcli is installed
check_nmcli_installed() {
    if ! command -v nmcli &>/dev/null; then
        log ERROR "nmcli is not installed."
        return 1
    fi
    return 0
}

# Connect using saved Wi-Fi configuration
connect_with_config() {
    if [[ ! -f "$WIFI_CONFIG_FILE" ]]; then
        log WARNING "Wi-Fi config file $WIFI_CONFIG_FILE not found."
        return 1
    fi

    log INFO "Connecting to Wi-Fi using saved config..."
    # Source config safely
    # shellcheck source=/dev/null
    source "$WIFI_CONFIG_FILE"

    # Validate required variables
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

    # Wait for the connection to be fully established and check its status
    for i in {1..10}; do
        if nmcli -t -f GENERAL.STATE dev show wlan0 | grep -q "connected"; then
            log INFO "Successfully connected to Wi-Fi SSID: $DEFAULT_WIFI_SSID."
            return 0
        fi
        sleep 1
    done

    log WARNING "Timed out waiting for a successful connection to '$DEFAULT_WIFI_SSID'."
    return 1
}

# Connect interactively by prompting for SSID and password
connect_interactively() {
    log INFO "Starting interactive Wi-Fi connection..."

    nmcli networking on &>/dev/null || {
        log ERROR "Failed to enable networking."
        return 1
    }

    log INFO "Scanning $WIFI_SCAN_WAIT seconds for Wi-Fi networks..."
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
wifi_auto_connect() {
    # Check if nmcli is installed
    if ! check_nmcli_installed; then
        log ERROR "Cannot proceed without nmcli installed."
        return 1
    fi

    # Check if already online
    if check_online; then
        return 0
    fi

    # Try connecting with config
    if connect_with_config && check_online; then
        return 0
    fi

    # Fall back to interactive connection
    log INFO "Config-based connection failed or unavailable. Attempting interactive connection."
    if connect_interactively && check_online; then
        return 0
    fi

    log ERROR "Failed to establish internet connection."
    return 1
}

# Execute main function and handle exit status
main() {
    wifi_auto_connect
    local status=$?
    if [[ $status -ne 0 ]]; then
        log ERROR "Wi-Fi connection script failed."
        exit 1
    fi
    log INFO "Wi-Fi connection script completed successfully."
}

# Run main function
main
