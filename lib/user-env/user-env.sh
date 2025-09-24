#!/usr/bin/env bash
set -euo pipefail

# ───────── Variables ──────── #
readonly LOG_FILE="$HOME/bootstrap.log"

# ─────── Source Configuration ────── #
source "$(dirname "$0")/conf/conf_user.sh"

# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/user-env/setup-folders.sh"
source "$(dirname "$0")/lib/user-env/install-icons.sh"
source "$(dirname "$0")/lib/user-env/mariadb.sh"
source "$(dirname "$0")/lib/user-env/user-setup.sh"

# ─────── Run Main ────── #
user_env() {
   user-setup
   setup_folders
   install_icons
   mariadb
}
