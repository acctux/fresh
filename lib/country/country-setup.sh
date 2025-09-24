#!/usr/bin/env bash
set -euo pipefail

# ───────── Variables ──────── #
readonly LOG_FILE="$HOME/bootstrap.log"

# ─────── Source Configuration ────── #
source "$(dirname "$0")/conf/conf_user.sh"

# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/country/detect-country.sh"
source "$(dirname "$0")/lib/country/regdom-reflector.sh"

# ─────── Run Main ────── #
setup_country() {
    detect_country
    sudo pacman -S --needed reflector wireless-regdb
    regdom_reflector
}
