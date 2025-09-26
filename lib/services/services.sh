# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/services/system-services.sh"
source "$(dirname "$0")/lib/services/user-services.sh"

# ─────── Run Main ────── #
handle_services() {
  system_services
  user_services
}
