readonly ref_quant=20
readonly ref_timeout=3

update_wireless_regdom() {
    local regdom_conf="$MOUNT_POINT/etc/conf.d/wireless-regdom"

    # -e '/^[[:space:]]*WIRELESS_REGDOM=/d': Any line that starts with zero or more spaces followed by WIRELESS_REGDOM=, deletes it (d).
    # -e "\$aWIRELESS_REGDOM=\"$COUNTRY_CODE\"": $ refers to the last line of the file. a=append
    sudo sed -i -E -e '/^[[:space:]]*WIRELESS_REGDOM=/d' -e "\$aWIRELESS_REGDOM=\"$COUNTRY_CODE\"" "$regdom_conf"

    info "Set wireless regulatory domain to $COUNTRY_CODE and updated $regdom_conf"
}

update_reflector() {
    reflector \
  		--country $COUNTRY_CODE \
		--protocol https \
		--completion-percent 100 \
		--latest $ref_quant \
		--sort rate \
		--threads 8 \
		--download-timeout $ref_timeout \
		--save /etc/pacman.d/mirrorlist
}

update_reflector_conf() {
    info "Writing reflector configuration."
	cat > /mnt/etc/xdg/reflector/reflector.conf <<- EOF
	--country $COUNTRY_CODE \
	--protocol https \
	--completion-percent 100 \
	--latest $ref_quant \
	--sort rate \
	--threads 8 \
	--download-timeout $ref_timeout \
	--save /etc/pacman.d/mirrorlist
	EOF
}
