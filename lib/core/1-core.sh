# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/core/wifi-connect.sh"
source "$(dirname "$0")/lib/core/mnt-cp-keys.sh"
source "$(dirname "$0")/lib/core/import-personal-keys.sh"

# ─────── Run Main ────── #
setup_core() {
    log INFO "Starting system setup"
    wifi_connect
    mnt_cp_keys
    sudo pacman -Syu --needed base-devel keychain openssh
    import_personal_keys
}
