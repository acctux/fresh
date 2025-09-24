#!/usr/bin/env bash
set -euo pipefail

# ───────── Variables ──────── #
readonly LOG_FILE="$HOME/bootstrap.log"

# ─────── Source Configuration ────── #
source "$(dirname "$0")/conf/conf_pac.sh"

# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/packages/chaotic-repo.sh"
source "$(dirname "$0")/lib/packages/aur-helper.sh"

# ─────── Run Main ────── #
setup_country() {
    chaotic_repo_setup
    aur_helper_install
    $AUR_HELPER -S --needed "${PACMAN[@]}"
    $AUR_HELPER -S --needed "${AUR[@]}"
}
