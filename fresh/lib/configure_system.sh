configure_system() {
    info "Configuring system"
    genfstab -U "$MOUNT_POINT" > "$MOUNT_POINT/etc/fstab"

    # Timezone & locale
    arch-chroot "$MOUNT_POINT" ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    arch-chroot "$MOUNT_POINT" hwclock --systohc
    echo "$LOCALE UTF-8" >> "$MOUNT_POINT/etc/locale.gen"
    arch-chroot "$MOUNT_POINT" locale-gen
    echo "LANG=$LOCALE" > "$MOUNT_POINT/etc/locale.conf"

    # Hostname & hosts file
    echo "$HOSTNAME" > "$MOUNT_POINT/etc/hostname"
    cat > "$MOUNT_POINT/etc/hosts" <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF
    success "System configuration completed"
}

configure_bootloader() {
    info "Configuring systemd boot"
    local prefix
    prefix=$(partition_prefix "$DISK")
    local root_uuid
    root_uuid=$(blkid -s UUID -o value "${prefix}3")

    arch-chroot "$MOUNT_POINT" bootctl --path=/boot install
    cat > "$MOUNT_POINT/boot/loader/loader.conf" <<EOF
default arch.conf
timeout 1
EOF
    cat > "$MOUNT_POINT/boot/loader/entries/arch.conf" <<EOF
title   Arch Linux
linux   /vmlinuz-linux
EOF

    echo "initrd /amd-ucode.img"   >> "$MOUNT_POINT/boot/loader/entries/arch.conf"
    echo "initrd /initramfs-linux.img" >> "$MOUNT_POINT/boot/loader/entries/arch.conf"
    echo "options root=UUID=$root_uuid rw rootflags=subvol=@" >> "$MOUNT_POINT/boot/loader/entries/arch.conf"
    success "Systemd-boot configured."
}
