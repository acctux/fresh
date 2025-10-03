zram_config() {
    local config_path="$MOUNT_POINT/etc/systemd/zram-generator.conf"
    local zram_parameters="$MOUNT_POINT/etc/sysctl.d/99-vm-zram-parameters.conf"

    tee "$config_path" > /dev/null <<EOF
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
EOF

    tee "$zram_parameters" > /dev/null <<EOF
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOF
}
chameleon() {
    zram_config
    arch-chroot "$MOUNT_POINT" systemctl enable --now systemd-zram-setup@zram0.service
    echo "ZRAM enabled."
}
