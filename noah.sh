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

# echo -ne "
# "

# Runtime variables (initially empty)
DISK=""
ROOT_PASSWORD=""
USER_PASSWORD=""
SWAP_PARTITION=""

#######################################
# Main
#######################################

main() {
    # trap 'error_trap $LINENO $BASH_COMMAND' ERR

    # require_root
    # check_dependencies

    trap unmount_mounted EXIT
    info "Starting Arch Linux installation"

   aardvark
#     ( bash "$SCRIPT_DIR"/fresh/animals/bonobo-chroot-sys.sh )|& tee 0-preinstall.log
#     pacman -Sy archlinux-keyring
#     ( arch-chroot "$HOME_MNT"/animals/chameleon-init-chaos.sh )|& tee 1-setup.log
#     ( arch-chroot "$HOME_MNT"/animals/dingo-suusers.sh )|& tee 2-setup.log
#     ( arch-chroot python "$HOME_MNT"/animals/echidna-copy-etc.py )|& tee 3-post-setup.log
#     ( arch-chroot "$HOME_MNT"/animals/fox-services.sh )|& tee 3-post-setup.log
#     ( arch-chroot "$HOME_MNT"/animals/fox-services.sh )|& tee 3-post-setup.log
#     ( arch-chroot "$HOME_MNT" /usr/bin/runuser -u $USERNAME -- /home/$USERNAME/scripts/zebra-user.sh )|& tee 2-user.log

#     additional_packages
#     arch-chroot "$MOUNT_POINT" systemctl enable "${SERV_ENABLE}"
#     arch-chroot "$MOUNT_POINT" systemctl disable systemd-timesyncd.service
#     ansible_etc_playbook
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
