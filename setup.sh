#!/usr/bin/env bash
set -euo pipefail

# ───────── Variables ──────── #
readonly LOG_FILE="$HOME/bootstrap.log"

# ─────── Source Configuration ────── #
source "$(dirname "$0")/conf/conf-pac.sh"
source "$(dirname "$0")/conf/conf-grp-srv.sh"
source "$(dirname "$0")/conf/conf-user.sh"
source "$(dirname "$0")/conf/conf-folders.sh"

# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/core/core.sh"
source "$(dirname "$0")/lib/country/country.sh"
source "$(dirname "$0")/lib/packages/packages.sh"
source "$(dirname "$0")/lib/diffs/diffs.sh"
source "$(dirname "$0")/lib/user-env/user-env.sh"
source "$(dirname "$0")/lib/stow/files.sh"
source "$(dirname "$0")/lib/services/services.sh"
source "$(dirname "$0")/lib/post/hide-apps.sh"
source "$(dirname "$0")/lib/post/cleanup-files.sh"

run_sudo() {
    # log INFO "Starting system setup"
    # setup_core
    # log INFO "Wifi established and keys copied."
    # setup_country
    # log INFO "Country specific changes applied."
    # package_setup
    apply_diffs
}
run_user() {
    user_env
    replace_files
    handle_services
    hide_apps
    log INFO "Setup Completed Successfully!"
}

# ─────── Run Main ────── #
main() {
    run_sudo
#    run_user
#    if reboot_prompt; then
#        cleanup_files
#        sudo reboot
#    fi
}

main "$@"
