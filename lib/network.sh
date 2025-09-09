#!/usr/bin/env bash

check_online() {
    ping -q -c3 -i1 1.1.1.1 &>/dev/null
}

connect_with_config() {
    if [[ -f "$HOME/wifi.sh" ]]; then
        log INFO "Connecting to Wi-Fi using saved config..."
        source "$HOME/wifi.sh"

        nmcli networking on
        sleep 1

        nmcli device wifi connect "${DEFAULT_WIFI_SSID:-}" password "${DEFAULT_WIFI_PASS:-}" &>/dev/null &&
            log INFO "Connected to Wi-Fi via wifi.sh." ||
            log WARNING "Connection attempt via wifi.sh failed."
    fi
}

connect_interactively() {
    log INFO "Attempting interactive Wi-Fi connection..."

    nmcli networking on
    nmcli device wifi rescan
    sleep 2

    nmcli device wifi list

    nmcli device wifi connect || {
        log ERROR "Interactive Wi-Fi connection failed."
        return 1
    }
}

wifi_auto_connect() {
    if check_online; then
        log INFO "Internet already connected."
        return 0
    fi

    command -v nmcli >/dev/null || {
        log ERROR "nmcli is not installed."
        return 1
    }

    connect_with_config

    if check_online; then
        return 0
    fi

    log WARNING "Wi-Fi config connection failed or was not available."
    connect_interactively

    if ! check_online; then
        log ERROR "Still offline after interactive attempt."
        return 1
    fi
}
