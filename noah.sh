#!/usr/bin/env bash

# -------------------------------------------------------------------------

# ███╗   ██╗  ██████╗   █████╗  ██╗  ██╗  ██████╗     █████╗  ██████╗   ██████╗ ██╗  ██╗
# ████╗  ██║ ██╔═══██╗ ██╔══██╗ ██║  ██║ ██╔════╝    ██╔══██╗ ██╔══██╗ ██╔════╝ ██║  ██║
# ██╔██╗ ██║ ██║   ██║ ███████║ ███████║ ╚█████╗     ███████║ ██████╔╝ ██║      ███████║
# ██║╚██╗██║ ██║   ██║ ██╔══██║ ██╔══██║  ╚═══██╗    ██╔══██║ ██╔══██╗ ██║      ██╔══██║
# ██║ ╚████║ ╚██████╔╝ ██║  ██║ ██║  ██║ ██████╔╝    ██║  ██║ ██║  ██║ ╚██████╗ ██║  ██║
# ╚═╝  ╚═══╝  ╚═════╝  ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝  ╚═╝ ╚═╝  ╚═╝  ╚═════╝ ╚═╝  ╚═╝

# -------------------------------------------------------------------------
# The one-opinion opinionated automated Arch Linux Installer
# -------------------------------------------------------------------------

# Robust Arch Linux base installer – improved version
set -Eeuo pipefail

#######################################
# Global configuration and constants
#######################################

readonly LOG_FILE="/tmp/noah.log"

readonly USERNAME="nick"
readonly HOSTNAME="arch"
readonly EFI_SIZE="512M"
readonly MOUNT_POINT="/mnt"
readonly TIMEZONE="US/Eastern"
LOCALE="en_US.UTF-8"

readonly HOME_MNT="$MOUNT_POINT/home/$USERNAME"
KEY_DIR="$HOME_MNT/.ssh"
KEY_FILES=(
    "my-private-key.asc"
    "id_ed25519"
    "my-public-key.asc"
    "id_ed25519.pub"
)

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/animals/aardvark-disks.sh"
# source "$SCRIPT_DIR/animals/bonobo-chroot-sys.sh"
# source "$SCRIPT_DIR/animals/chameleon-zram-config.sh"
# source "$SCRIPT_DIR/animals/dingo-reflector-chaotic.sh"
# source "$SCRIPT_DIR/animals/echidna-gpu-flood.sh"
# source "$SCRIPT_DIR/animals/fox-copy-etc.sh"
# source "$SCRIPT_DIR/animals/gecko-sys-serv.sh"
# source "$SCRIPT_DIR/animals/hyena-mariadb.sh"
# source "$SCRIPT_DIR/conf/test_pac.sh"
# source "$SCRIPT_DIR/conf/conf_sysctl.sh"


# Runtime variables (initially empty)
DISK=""
ROOT_PASSWORD=""
USER_PASSWORD=""
SWAP_PARTITION=""

unmount_mounted() {
    info "Unmounting filesystems"
    if mountpoint -q "$MOUNT_POINT/boot"; then
        umount "$MOUNT_POINT/boot" || error "Failed to unmount $MOUNT_POINT/boot"
    fi
    for sub in home var/log var/cache/pacman/pkg; do
        if mountpoint -q "$MOUNT_POINT/$sub"; then
            umount "$MOUNT_POINT/$sub" || error "Failed to unmount $MOUNT_POINT/$sub"
        fi
    done
    if mountpoint -q "$MOUNT_POINT"; then
        umount "$MOUNT_POINT" || error "Failed to unmount $MOUNT_POINT"
    fi
    success "Filesystems unmounted successfully"
}
#######################################
# Main
#######################################

main() {
    # trap 'error_trap $LINENO $BASH_COMMAND' ERR

    # require_root
    # check_dependencies

    # trap unmount_mounted EXIT
    info "Starting Arch Linux installation"
    unmount_mounted
    aardvark
    bonobo
    chameleon
    dingo

#     pacman -Sy archlinux-keyring
#     ( arch-chroot "$HOME_MNT" /usr/bin/runuser -u $USERNAME -- /home/$USERNAME/scripts/zebra-user.sh )|& tee 2-user.log

#     echo -ne "
# -------------------------------------------------------------------------
# ███╗   ██╗  ██████╗   █████╗  ██╗  ██╗  ██████╗     █████╗  ██████╗   ██████╗ ██╗  ██╗
# ████╗  ██║ ██╔═══██╗ ██╔══██╗ ██║  ██║ ██╔════╝    ██╔══██╗ ██╔══██╗ ██╔════╝ ██║  ██║
# ██╔██╗ ██║ ██║   ██║ ███████║ ███████║ ╚█████╗     ███████║ ██████╔╝ ██║      ███████║
# ██║╚██╗██║ ██║   ██║ ██╔══██║ ██╔══██║  ╚═══██╗    ██╔══██║ ██╔══██╗ ██║      ██╔══██║
# ██║ ╚████║ ╚██████╔╝ ██║  ██║ ██║  ██║ ██████╔╝    ██║  ██║ ██║  ██║ ╚██████╗ ██║  ██║
# ╚═╝  ╚═══╝  ╚═════╝  ╚═╝  ╚═╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝  ╚═╝ ╚═╝  ╚═╝  ╚═════╝ ╚═╝  ╚═╝

# -------------------------------------------------------------------------
#                     Automated Arch Linux Installer
# -------------------------------------------------------------------------
#                 Done - Please Eject Install Media and Reboot
# "
#     if yes_no_prompt "Reboot now?"; then
#         reboot
#     fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
