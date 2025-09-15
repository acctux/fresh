#!/usr/bin/env bash
set -euo pipefail

# ───────── Variables ──────── #
KEYS_MNT=$(mktemp -d)

# ─────── Source Configuration ────── #
source "$(dirname "$0")/conf/conf_pac.sh"
source "$(dirname "$0")/conf/conf_services.sh"
source "$(dirname "$0")/conf/conf_user.sh"

# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/mnt-cp-keys.sh"
source "$(dirname "$0")/lib/wifi-connect.sh"
source "$(dirname "$0")/lib/detect-country.sh"
source "$(dirname "$0")/lib/regdom-reflector.sh"
source "$(dirname "$0")/lib/import-personal-keys.sh"
source "$(dirname "$0")/lib/chaotic-aur-setup.sh"
source "$(dirname "$0")/lib/pacman-aur-packages.sh"
source "$(dirname "$0")/lib/install-icons.sh"
source "$(dirname "$0")/lib/user-setup.sh"
source "$(dirname "$0")/lib/git-dots-etc.sh"
source "$(dirname "$0")/lib/handle-services.sh"
source "$(dirname "$0")/lib/cleanup-and-autorun.sh"

# ─────── Run Main ────── #
main() {
    log INFO "Starting system setup"
    mnt_cp_keys
    wifi_connect
    detect_country

    # Install regdb reflector/rsync base-devel openssh/keychain
    sudo pacman -Syu --needed --noconfirm "${BASE_PAC[@]}"
    regdom_reflector
    import_personal_keys
    chaotic_aur_setup
    pacman_aur_packages

    # remove previously created config
    rm ~/.ssh/config
    install_icons
    git_dots_etc
    user_setup
    hide_apps
    handle_services
    cleanup_and_autorun
    log INFO "Setup Completed Successfully!"
    reboot_prompt
}

main "$@"
