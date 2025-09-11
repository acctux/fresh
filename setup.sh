#!/usr/bin/env bash
set -euo pipefail

# ─────── Source Configuration ────── #
#source "$(dirname "$0")/conf/conf_pac.sh"
#source "$(dirname "$0")/conf/conf_services.sh"
source "$(dirname "$0")/conf/conf_user.sh"

# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/logging.sh"
source "$(dirname "$0")/lib/mnt-cp-keys.sh"
#source "$(dirname "$0")/lib/wifi-connect.sh"
#source "$(dirname "$0")/lib/detect-country.sh"
#source "$(dirname "$0")/lib/regdom-reflector.sh"
#source "$(dirname "$0")/lib/import-personal-keys.sh"
#source "$(dirname "$0")/lib/all-remaining-packages.sh"
#source "$(dirname "$0")/lib/user-setup.sh"
#source "$(dirname "$0")/lib/git-dots-etc.sh"
#source "$(dirname "$0")/lib/handle-services.sh"
#source "$(dirname "$0")/lib/cleanup-and-autorun.sh"

# ─────── Run Main ────── #
main() {
    log INFO "Starting system setup"
    mnt_cp_keys
#    wifi_connect
#    detect_country
#    regdom_reflector
#    sudo pacman -Syu --needed --noconfirm "${BASE_PAC[@]}"
#    import_personal_keys
#    chaos_remaining_packages
#    git_dots_etc
#    user_setup
#    hide_apps
#    handle_services
#    cleanup_and_autorun
#    log INFO "Setup Completed Successfully!"
#    read -p "Reboot now? (y/N): " -n 1 -r
#    echo
#    if [[ $REPLY =~ ^[Yy]$ ]]; then
#      log "INFO" "Rebooting system..."
#      sudo reboot
#    fi
}

main "$@"
