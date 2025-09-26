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
source "$(dirname "$0")/lib/core/1-core.sh"
source "$(dirname "$0")/lib/country/2-country.sh"
source "$(dirname "$0")/lib/packages/3-packages.sh"
source "$(dirname "$0")/lib/user-env/4-user-env.sh"
source "$(dirname "$0")/lib/replace-files/5-files.sh"
source "$(dirname "$0")/lib/services/6-services.sh"
#source "$(dirname "$0")/lib/post/hide-apps.sh"
#source "$(dirname "$0")/lib/post/cleanup-files.sh"

# ─────── Run Main ────── #
main() {
    log INFO "Starting system setup"
#    setup_core
#    setup_country
#    package_setup
#    user_env
    replace_files
#    handle_services
#    hide_apps

#    log INFO "Setup Completed Successfully!"

#    if reboot_prompt; then
#        cleanup_files
#        sudo reboot
#    fi
}

main "$@"
