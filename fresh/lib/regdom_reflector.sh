update_wireless_regdom() {
    local regdom_conf="$MOUNT_POINT/etc/conf.d/wireless-regdom"

    # -e '/^[[:space:]]*WIRELESS_REGDOM=/d': Any line that starts with zero or more spaces followed by WIRELESS_REGDOM=, deletes it (d).
    # -e "\$aWIRELESS_REGDOM=\"$COUNTRY_CODE\"": $ refers to the last line of the file. a=append
    sudo sed -i -E -e '/^[[:space:]]*WIRELESS_REGDOM=/d' -e "\$aWIRELESS_REGDOM=\"$COUNTRY_CODE\"" "$regdom_conf"

    info "Set wireless regulatory domain to $COUNTRY_CODE and updated $file"
}

update_reflector() {
    local reflector_conf="$MOUNT_POINT/etc/xdg/reflector/reflector.conf"
    sudo tee "$reflector_conf" > /dev/null <<EOF

--save "/etc/pacman.d/mirrorlist"

--protocol https

--country $COUNTRY_NAME

--latest 15

--sort rate

--fastest 5

--timeout 2

--ip-version all
EOF

    echo "Updating mirrorlist..."
    sudo reflector --country "$COUNTRY_NAME" --latest 10 --sort rate --save "$mirrorlist_file"
    touch $reflector_flag
}
