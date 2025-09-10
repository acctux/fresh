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
    local today_date
    today_date=$(date +%F)

    if [[ -f "$mirrorlist_file" ]]; then
        # Extract date from the '# When:' line in the mirrorlist header
        local header_date
        # Search the mirrorlist file for the line starting with "# When:"
        # 'grep '^# When:' "$mirrorlist_file"' finds all lines beginning with "# When:"
        # 'head -1' takes the first matching line (in case there are multiple)
        # 'awk '{print $3}'' extracts the third field from that line, (1=#, 2="When", 3=date)
        header_date=$(grep '^# When:' "$mirrorlist_file" | head -1 | awk '{print $3}')

        if [[ "$header_date" == "$today_date" ]]; then
            log INFO "Mirrorlist already generated today ($header_date). Skipping update."
            return 0
        fi
    fi

    log INFO "Mirrorlist missing or outdated. Running reflector..."

    sudo reflector --country "$COUNTRY_NAME" \
                   --latest 10 \
                   --sort rate \
                   --save "$mirrorlist_file"
}

do_the_needful() {
    install_nec
    update_wireless_regdom
    update_mirrorlist_if_changed
}
