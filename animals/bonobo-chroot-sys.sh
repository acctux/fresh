#######################################
# PACSTRAP and initial config of machine for real install
#######################################

#######################################
# Variables
#######################################

CPU_MAN=""

autodetect_cpu() {
    init_pkgs=(
    base \
    base-devel \
    btrfs-progs \
    efibootmgr \
    linux \
    linux-firmware \
    neovim-lspconfig \
    reflector \
    zram-generator
    )
    cpu_type=$(lscpu)
    if grep -E "AuthenticAMD" <<< ${cpu_type}; then
        init_pkgs+=(amd-ucode)
        CPU_MAN="amd"
    elif grep -E "GenuineIntel" <<< ${cpu_type}; then
        init_pkgs+=(intel-ucode)
        CPU_MAN="intel"
    fi
    echo "Detectcted: $CPU_MAN"
    pacstrap --noconfirm "$MOUNT_POINT" "${init_pkgs[@]}"
}

regional_settings() {


    info "Configuring system"
    genfstab -U "$MOUNT_POINT" > "$MOUNT_POINT/etc/fstab"

    # Timezone & LOCALE
    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    hwclock --systohc
    echo "$LOCALE UTF-8" >> "$MOUNT_POINT/etc/LOCALE.gen"
    arch-chroot "$MOUNT_POINT" LOCALE-gen
    echo "LANG=$LOCALE" > "$MOUNT_POINT/etc/LOCALE.conf"
}

set_hostname() {
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

    echo "initrd /$CPU_MAN-ucode.img"   >> "$MOUNT_POINT/boot/loader/entries/arch.conf"
    echo "initrd /initramfs-linux.img" >> "$MOUNT_POINT/boot/loader/entries/arch.conf"
    echo "options root=UUID=$root_uuid rw rootflags=subvol=@" >> "$MOUNT_POINT/boot/loader/entries/arch.conf"
    success "Systemd-boot configured."
}

bonobo() {
    autodetect_cpu
    # regional_settings
    # set_hostname
    # configure_bootloader
}
