# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/packages/chaotic-repo.sh"
source "$(dirname "$0")/lib/packages/aur-helper.sh"

# ─────── Run Main ────── #
package_setup() {
# wrap in one sudo	
    chaotic_repo
    aur_helper
    $AUR_HELPER -S --needed "${PACMAN[@]}"
    $AUR_HELPER -S --needed "${AUR[@]}"
}
