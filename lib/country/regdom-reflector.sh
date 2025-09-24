LATEST=20
FASTEST=5
TIMEOUT=2
IP_VERSION="all"

update_wireless_regdom() {
    local file="/etc/conf.d/wireless-regdom"

    # -e '/^[[:space:]]*WIRELESS_REGDOM=/d': Any line that starts with zero or more spaces followed by WIRELESS_REGDOM=, deletes it (d).
    # -e "\$aWIRELESS_REGDOM=\"$COUNTRY_CODE\"": $ refers to the last line of the file. a=append
    sudo sed -i -E -e '/^[[:space:]]*WIRELESS_REGDOM=/d' -e "\$aWIRELESS_REGDOM=\"$COUNTRY_CODE\"" "$file"

    # Apply immediately
    sudo iw reg set "$COUNTRY_CODE"

    log INFO "Set wireless regulatory domain to $COUNTRY_CODE and updated $file"
}

update_mirrorlist_if_changed() {
    local mirrorlist_file="/etc/pacman.d/mirrorlist"
    local reflector_conf="/etc/xdg/reflector/reflector.conf"
    local reflector_flag="$HOME/.cache/fresh/reflector.flag"

    if [[ -f "$reflector_flag" ]]; then
        echo "Mirrorlist already updated. Skipping."
        return 0
    fi
    sudo tee "$reflector_conf" > /dev/null <<EOF

--save $mirrorlist_file

--protocol https

--country $COUNTRY_NAME

--latest $LATEST

--sort rate

--fastest $FASTEST

--timeout $TIMEOUT

--ip-version all
EOF

    echo "Updating mirrorlist..."
    sudo reflector --country "$COUNTRY_NAME" --latest 10 --sort rate --save "$mirrorlist_file"
    touch $reflector_flag
}

regdom_reflector() {
    update_wireless_regdom
    update_mirrorlist_if_changed
}
