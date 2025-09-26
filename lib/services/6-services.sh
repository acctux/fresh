#!/usr/bin/env bash
set -euo pipefail

# ─────── Source Configuration ────── #
source "$(dirname "$0")/conf/conf-user.sh"

# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/services/system-services.sh"
source "$(dirname "$0")/lib/services/user-services.sh"

# ─────── Run Main ────── #
handle_services() {
#    system_services
    user_services
}
