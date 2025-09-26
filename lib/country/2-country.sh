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
