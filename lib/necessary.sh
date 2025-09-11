#!/usr/bin/env bash

install_nec() {
    sudo pacman -S --needed --noconfirm openssh reflector rsync base-devel wireless-regdb
}

update_wireless_regdom() {
    local file="/etc/conf.d/wireless-regdom"

    # Check for an uncommented WIRELESS_REGDOM line
    if sudo grep -q '^WIRELESS_REGDOM=' "$file" | grep -v '^#'; then
        # Update the first uncommented WIRELESS_REGDOM line
        sudo sed -i "/^WIRELESS_REGDOM=/ s/.*/WIRELESS_REGDOM=\"$COUNTRY_CODE\"/" "$file"
    else
        # Append the new setting if no uncommented line is found
        echo "WIRELESS_REGDOM=\"$COUNTRY_CODE\"" | sudo tee -a "$file" > /dev/null
    fi

    # Apply immediately (optional)
    sudo iw reg set "$COUNTRY_CODE"

    log INFO "Updated wireless regulatory domain to $COUNTRY_CODE"
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

do_the_needful() {
    install_nec
    update_wireless_regdom
    update_mirrorlist_if_changed
}
