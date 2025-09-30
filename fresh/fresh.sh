#!/usr/bin/env bash

# Robust Arch Linux base installer – improved version
set -Eeuo pipefail
source "$(dirname "$0")/utils.sh"

source "$(dirname "$0")/utils/passwords_util.sh"
source "$(dirname "$0")/utils/select_from_menu.sh"
source "$(dirname "$0")/utils/timezone_util.sh"
source "$(dirname "$0")/utils/yes_no.sh"

source "$(dirname "$0")/lib/system_services.sh"
source "$(dirname "$0")/lib/disk_management.sh"
source "$(dirname "$0")/lib/disk_validation.sh"
source "$(dirname "$0")/lib/key_management.sh"
source "$(dirname "$0")/lib/regdom_reflector.sh"
source "$(dirname "$0")/lib/copy_fresh.sh"

source "$(dirname "$0")/conf/conf_user.sh"
source "$(dirname "$0")/conf/conf_services.sh"
source "$(dirname "$0")/conf/conf_pac.sh"


# Runtime variables (initially empty)
DISK=""
ROOT_PASSWORD=""
USER_PASSWORD=""
SWAP_PARTITION=""
TIMEZONE=""
BTRFS_MOUNT_OPTIONS="compress=zstd,noatime"

#######################################
# Disk management functions
#######################################
partition_prefix() {
    local disk="$1"
    if [[ "$disk" =~ (nvme|mmcblk|loop) ]]; then
        echo "${disk}p"
    else
        echo "$disk"
    fi
}

create_partitions() {
    info "Creating partitions on $DISK"
    wipefs -af "$DISK"
    sgdisk --zap-all "$DISK" >/dev/null
    sgdisk -n 1:0:+${EFI_SIZE} -t 1:ef00 "$DISK"
    sgdisk -n 2:0:+${SWAP_SIZE} -t 2:8200 "$DISK"
    sgdisk -n 3:0:0 -t 3:8300 "$DISK"
    partprobe "$DISK"
    sleep 2
    success "Partitions created successfully"
}


mount_filesystems() {
    info "Mounting filesystems"
    local prefix
    prefix=$(partition_prefix "$DISK")

    local efi_partition="${prefix}1"
    local root_partition="${prefix}3"

    mount "$root_partition" "$MOUNT_POINT"
    mkdir -p "$MOUNT_POINT/boot"
    mount "$efi_partition" "$MOUNT_POINT/boot"


    btrfs subvolume create "$MOUNT_POINT/@"
    btrfs subvolume create "$MOUNT_POINT/@home"
    btrfs subvolume create "$MOUNT_POINT/@log"
    btrfs subvolume create "$MOUNT_POINT/@pkg"

    umount "$MOUNT_POINT/boot"
    umount "$MOUNT_POINT"

    mount -o subvol=@,$BTRFS_MOUNT_OPTIONS "$root_partition" "$MOUNT_POINT"

    mkdir -p "$MOUNT_POINT/home" "$MOUNT_POINT/var/log" "$MOUNT_POINT/var/cache/pacman/pkg"
    mount -o subvol=@home,$BTRFS_MOUNT_OPTIONS "$root_partition" "$MOUNT_POINT/home"
    mount -o subvol=@log,$BTRFS_MOUNT_OPTIONS "$root_partition" "$MOUNT_POINT/var/log"
    mount -o subvol=@pkg,$BTRFS_MOUNT_OPTIONS "$root_partition" "$MOUNT_POINT/var/cache/pacman/pkg"

    mkdir -p "$MOUNT_POINT/boot"
    mount "$efi_partition" "$MOUNT_POINT/boot"
    success "Filesystems mounted successfully"
}

#######################################
# System installation functions
#######################################
install_base_system() {
    info "Installing base system (minimal)"
    pacman -Sy --noconfirm
    echo $MOUNT_POINT ${BASE_PAC[@]}
    pacstrap "$MOUNT_POINT" "${BASE_PAC[@]}"
    success "Base system installed successfully"
}

chaotic_repo() {
    local chaotic_key_id="3056513887B78AEB"

    info "Adding Chaotic AUR GPG key."

    arch-chroot "$MOUNT_POINT" pacman-key --init
    arch-chroot "$MOUNT_POINT" pacman-key --recv-key "$chaotic_key_id" --keyserver keyserver.ubuntu.com
    arch-chroot "$MOUNT_POINT" pacman-key --lsign-key "$chaotic_key_id"

    info "Installing Chaotic AUR keyring and mirrorlist in chroot..."
    arch-chroot "$MOUNT_POINT" pacman -U --noconfirm --needed \
        https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst \
        https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst

    success "Chaotic AUR repository initialized."
}

configure_pacman() {
    info "Configuring pacman"
    local pacman_conf="$MOUNT_POINT/etc/pacman.conf"
    if [[ ! -f $pacman_conf ]]:
        info "pacman conf not found"
        exit 1
    # Uncomment [multilib], set ParallelDownloads = 10,
    #  Append [chaotic-aur] repo
    sed -i '/^\[multilib\]/,/^Include/ s/^#//' "$pacman_conf"
    sed -i 's/^ParallelDownloads *= *.*/ParallelDownloads = 10/' "$pacman_conf"
    echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> "$pacman_conf"

    arch-chroot "$MOUNT_POINT" pacman -Sy --noconfirm
    success "Pacman configured successfully"
}

install_additional_packages() {
    info "Installing additional packages"
    arch-chroot "$MOUNT_POINT" pacman -S --noconfirm "${FRESH_PAC[@]}"
    success "Additional packages installed successfully"
}

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

configure_users() {
    info "Configuring users"
    echo "root:$ROOT_PASSWORD" | arch-chroot "$MOUNT_POINT" chpasswd

    arch-chroot "$MOUNT_POINT" useradd -m -s "/bin/zsh" "$USERNAME"
    echo "$USERNAME:$USER_PASSWORD" | arch-chroot "$MOUNT_POINT" chpasswd


    cat > "$MOUNT_POINT/etc/sudoers.d/$USERNAME" <<EOF
$USERNAME ALL=(ALL:ALL) ALL
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/udisksctl
Defaults:$USERNAME timestamp_timeout=-1
Defaults passwd_tries=10
EOF

    # No default shell configurations - let users configure their shell as they prefer
    success "Users configured successfully"
}

#######################################
# Cleanup and main logic
#######################################
cleanup() {
    info "Performing cleanup"
    # Unmount submounts in reverse order
    if mountpoint -q "$MOUNT_POINT/boot"; then
        umount "$MOUNT_POINT/boot" || true
    fi
    for sub in home var/log var/cache/pacman/pkg; do
        if mountpoint -q "$MOUNT_POINT/$sub"; then
            umount "$MOUNT_POINT/$sub" || true
        fi
    done
    if mountpoint -q "$MOUNT_POINT"; then
        umount "$MOUNT_POINT" || true
    fi
    if [[ -n "$SWAP_PARTITION" ]]; then
        swapoff "$SWAP_PARTITION" || true
    fi
}

ansible_etc_playbook() {
    info "Running ansible playbook on etc files"
    ansible-galaxy collection install community.general
    ansible-playbook -i ~/fresh/fresh_ans_inv.yml ~/fresh/fresh_ans_play.yml
}

main() {
    require_root
    check_dependencies
    # trap cleanup EXIT
    trap 'error_trap $LINENO $BASH_COMMAND' ERR
    info "Starting Arch Linux installation"

    get_disk_selection
    validate_disk_size
    choose_timezone
    ROOT_PASSWORD=$(get_password "Enter root password")
    success "Root password set"
    USER_PASSWORD=$(get_password "Enter password for $USERNAME")
    success "User password set"

    # Summary
    info "Installation summary:"
    printf 'Disk: %s\nEFI size: %s\nSwap size: %s\nHostname: %s\nUsername: %s\nTimezone: %s\n\n' \
        "$DISK" "$EFI_SIZE" "$SWAP_SIZE" "$HOSTNAME" "$USERNAME" "$TIMEZONE"

    yes_no_prompt "Proceed with installation?" || fatal "Installation cancelled by user"

    create_partitions
    format_partitions
    mount_filesystems

    update_reflector
    install_base_system
    chaotic_repo
    configure_pacman
    update_wireless_regdom
    update_reflector_conf
    arch-chroot "$MOUNT_POINT" pacman -Sy
    install_additional_packages
    configure_system
    arch-chroot "$MOUNT_POINT" systemctl enable "${SERV_ENABLE}"
    arch-chroot "$MOUNT_POINT" systemctl disable "${SERV_DISABLE}"
    configure_bootloader
    configure_users
    ansible_etc_playbook


    success "Arch Linux installation completed successfully!"
    info "System is ready to boot. Remove installation media and reboot."
    if yes_no_prompt "Reboot now?"; then
        reboot
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
