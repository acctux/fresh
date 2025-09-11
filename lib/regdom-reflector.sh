# keychain is only needed depending on the amount of pw protected gh repos you need
sudo pacman -S --needed --noconfirm

update_wireless_regdom() {
    local file="/etc/conf.d/wireless-regdom"

    # Remove any uncommented WIRELESS_REGDOM= lines
    sudo sed -i '/^[[:space:]]*WIRELESS_REGDOM=/!b; /^[[:space:]]*#/! s/^.*$//' "$file"

    # Append new setting
    echo "WIRELESS_REGDOM=\"$COUNTRY_CODE\"" | sudo tee -a "$file" > /dev/null

    # Apply immediately
    sudo iw reg set "$COUNTRY_CODE"

    log INFO "Set wireless regulatory domain to $COUNTRY_CODE and updated $file"
}

update_mirrorlist_if_changed() {
    local mirrorlist_file="/etc/pacman.d/mirrorlist"
    local today_date=$(date +%F)

    # Check if file exists and has a "# When:" line with today's date
    if [[ -f "$mirrorlist_file" ]] && grep -q "^# When:.*$today_date" "$mirrorlist_file"; then
        echo "Mirrorlist already generated today ($today_date). Skipping update."
        return 0
    fi

    echo "Updating mirrorlist..."
    sudo reflector --country "$COUNTRY_NAME" --latest 10 --sort rate --save "$mirrorlist_file"
}

regdom_reflector() {
    update_wireless_regdom
    update_mirrorlist_if_changed
}
