#!/usr/bin/env bash
set -euo pipefail

# ───────── Variables ──────── #
readonly LOG_FILE="$HOME/bootstrap.log"

# ─────── Source Configuration ────── #
source "$(dirname "$0")/conf/conf_pac.sh"
source "$(dirname "$0")/conf/conf_services.sh"

# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/core/core-setup.sh"
source "$(dirname "$0")/lib/country/country-setup.sh"
source "$(dirname "$0")/lib/packages/package-setup.sh"
source "$(dirname "$0")/lib/user-env/user-env.sh"
source "$(dirname "$0")/lib/git-dots-etc.sh"
source "$(dirname "$0")/lib/add-user-to-groups.sh"
source "$(dirname "$0")/lib/handle-services.sh"
source "$(dirname "$0")/lib/hide-apps.sh"
source "$(dirname "$0")/lib/cleanup-files.sh"

# ─────── Run Main ────── #
main() {
    log INFO "Starting system setup"
    setup_core
    setup_country
    setup_packages
    setup_folders
    install_icons
    user_setup
    git_dots_etc
    handle_services
    add_user_to_groups
    hide_apps

    log INFO "Setup Completed Successfully!"

    if reboot_prompt; then
        cleanup_files
        sudo reboot
    fi
}

main "$@"
