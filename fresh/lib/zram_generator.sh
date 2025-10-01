systemd-zram-setup@zram0.service


create_zram_config() {
  local config_path="/etc/systemd/zram-generator.conf"

  sudo tee "$config_path" > /dev/null <<EOF
[zram0]
zram-size = min(ram / 2, 4096)
compression-algorithm = zstd
EOF

  echo "ZRAM configuration written to $config_path"
}

create_zram_optimizations() {
  local config_path="/etc/sysctl.d/99-vm-zram-parameters.conf"

  sudo tee "$config_path" > /dev/null <<EOF
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
EOF

  echo "ZRAM configuration written to $config_path"
}
