#!/usr/bin/env bash

install_nec() {
    sudo pacman -S --needed --noconfirm openssh reflector rsync base-devel wireless-regdb jq
}

update_wireless_regdom() {
    local file="/etc/conf.d/wireless-regdom"
    local code="$COUNTRY_CODE"

    if sudo grep -q '^WIRELESS_REGDOM=' "$file"; then
        sudo sed -i "/^WIRELESS_REGDOM=/c\\WIRELESS_REGDOM=\"$code\"" "$file"
    else
        echo "WIRELESS_REGDOM=\"$code\"" | sudo tee -a "$file" > /dev/null
    fi

    # Apply immediately (optional)
    sudo iw reg set "$code"

    log INFO "Updated wireless regulatory domain to $code"
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
