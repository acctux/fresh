#!/usr/bin/env bash
set -euo pipefail

# ─────── Source Configuration ────── #
source "$(dirname "$0")/conf/conf_pac.sh"

# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/packages/chaotic-repo.sh"
source "$(dirname "$0")/lib/packages/aur-helper.sh"

# ─────── Run Main ────── #
package_setup() {
    chaotic_repo
    aur_helper
    $AUR_HELPER -S --needed "${PACMAN[@]}"
    $AUR_HELPER -S --needed "${AUR[@]}"
}
