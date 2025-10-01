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
source "$(dirname "$0")/lib/configure_users.sh"
source "$(dirname "$0")/lib/configure_system.sh"
source "$(dirname "$0")/lib/package_management.sh"

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


main() {
    require_root
    check_dependencies
    trap cleanup EXIT
    trap 'error_trap $LINENO $BASH_COMMAND' ERR
    info "Starting Arch Linux installation"

    cleanup
    get_disk_selection
    validate_disk_size
    choose_timezone
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
