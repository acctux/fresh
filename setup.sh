#!/usr/bin/env bash
set -euo pipefail

# ─────── Source Configuration ────── #
source "$(dirname "$0")/config/conf_pac.sh"
source "$(dirname "$0")/config/conf_services.sh"
source "$(dirname "$0")/config/conf_user.sh"

# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/logging.sh"
source "$(dirname "$0")/lib/usb.sh"
source "$(dirname "$0")/lib/network.sh"
source "$(dirname "$0")/lib/countries.sh"
source "$(dirname "$0")/lib/gitandkeys.sh"
source "$(dirname "$0")/lib/installpackages.sh"
source "$(dirname "$0")/lib/system.sh"
source "$(dirname "$0")/lib/dotfiles.sh"
source "$(dirname "$0")/lib/hide.sh"
source "$(dirname "$0")/lib/cleanupservices.sh"

# ─────── Run Main ────── #
main() {
    log INFO "Starting system setup"

    # Execute setup steps
    usb_and_copy_keys
    wifi_auto_connect
    detect_country
    git_and_keys
    setup_packages
    setup_dotfiles_and_config
    hide_apps
    services_and_cleanup
    log INFO "Setup Completed Successfully! Rebooting."
    sudo reboot
}

main "$@"
