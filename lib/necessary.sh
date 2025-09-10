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
    local mirror_status_url="https://archlinux.org/mirrors/status/json/"

    log INFO "Checking Arch mirror server list for country: $COUNTRY_NAME ($COUNTRY_CODE)"

    # Fetch current mirror URLs from Arch's mirror status JSON for the selected country
    local current_servers
    current_servers=$(curl -sf "$mirror_status_url" | \
        jq -r --arg cc "$COUNTRY_CODE" '.urls[] | select(.country_code == $cc) | .url' | \
        sort)

    # If fetching failed or no mirrors were found, log and skip
    if [[ -z "$current_servers" ]]; then
        log WARNING "No mirrors found for $COUNTRY_NAME ($COUNTRY_CODE), or network error occurred."
        return 0
    fi

    # Determine whether to update the mirrorlist based on cached server list
    if [[ ! -f "$ARCH_MIRROR_CACHE" ]] || ! diff -q <(echo "$current_servers") "$ARCH_MIRROR_CACHE" > /dev/null; then
        log INFO "Mirror server list has changed. Regenerating mirrorlist with reflector..."

        # Generate new mirrorlist using reflector
        sudo reflector --country "$COUNTRY_NAME" \
                       --latest 10 \
                       --sort rate \
                       --save /etc/pacman.d/mirrorlist

        # Cache the current list of servers for future comparisons
        echo "$current_servers" | sudo tee "$ARCH_MIRROR_CACHE" > /dev/null
    else
        log INFO "Mirror server list unchanged. Skipping reflector."
    fi
}

do_the_needful() {
    install_nec
    update_wireless_regdom
    update_mirrorlist_if_changed
}
