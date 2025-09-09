#!/usr/bin/env bash

check_online() {
    ping -q -c3 -i1 1.1.1.1 &>/dev/null
}

wifi_auto_connect() {
    check_online && { log INFO "Internet already connected."; return 0; }

    command -v nmcli >/dev/null || { log ERROR "nmcli not installed."; return 1; }

    if [[ -f "$HOME/wifi.sh" ]]; then
        log INFO "Connecting to Wi-Fi via config..."
        source "$HOME/wifi.sh"
        nmcli networking on
        sleep 1
        nmcli device wifi connect "${DEFAULT_WIFI_SSID:-}" password "${DEFAULT_WIFI_PASS:-}" &>/dev/null &&
            log INFO "Connected to Wi-Fi." ||
            log WARNING "Wi-Fi connection failed via wifi.sh."
    fi

    if ! check_online; then
        log WARNING "Wi-Fi connection failed. Launching interactive selector."
        nmcli device wifi rescan
        sleep 2
        nmcli device wifi list
        nmcli device wifi connect || { log ERROR "Interactive Wi-Fi connection failed."; return 1; }
    fi
}
