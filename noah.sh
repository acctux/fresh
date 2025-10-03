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

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/conf.sh"
source "$SCRIPT_DIR/ark.sh"
# source "$SCRIPT_DIR/animals/bonobo-chroot-sys.sh"
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
  ark
  arch-chroot /mnt "$HOME/Noah/animals/chameleon-zram-config.sh"
  # aardvark
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
