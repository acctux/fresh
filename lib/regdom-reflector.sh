update_wireless_regdom() {
    local file="/etc/conf.d/wireless-regdom"
    if grep -q -E "^[[:space:]]*WIRELESS_REGDOM=\"$COUNTRY_CODE\"" "$file" 2>/dev/null; then
        log INFO "Wireless regulatory domain already set to $COUNTRY_CODE in $file. Skipping."
        return 0
    fi

    # Remove any uncommented WIRELESS_REGDOM= lines
    sudo sed -i '/^[[:space:]]*WIRELESS_REGDOM=/d' "$file"

    # Append new setting
    echo "WIRELESS_REGDOM=\"$COUNTRY_CODE\"" | sudo tee -a "$file" > /dev/null

    # Apply immediately
    sudo iw reg set "$COUNTRY_CODE"

    log INFO "Set wireless regulatory domain to $COUNTRY_CODE and updated $file"
}

update_mirrorlist_if_changed() {
    local mirrorlist_file="/etc/pacman.d/mirrorlist"
    local today_date=$(date +%F)

    if [[ -f "$mirrorlist_file" ]]; then
        local file_date=$(date -r "$mirrorlist_file" +%F)
        if [[ "$file_date" == "$today_date" ]]; then
            echo "Mirrorlist already updated today ($today_date). Skipping."
            return 0
        fi
    fi

    echo "Updating mirrorlist..."
    sudo reflector --country "$COUNTRY_NAME" --latest 10 --sort rate --save "$mirrorlist_file"
}

regdom_reflector() {
    update_wireless_regdom
    update_mirrorlist_if_changed
}
