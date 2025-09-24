#!/usr/bin/env bash
set -euo pipefail

# ─────── Source Configuration ────── #
source "$(dirname "$0")/conf/conf_user.sh"

# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/groups-services/system-services.sh"
source "$(dirname "$0")/lib/groups-services/add-groups.sh"
source "$(dirname "$0")/lib/groups-services/user-services.sh"

# ─────── Run Main ────── #
setup_country() {
    add_groups
    system_services
    user_service
}
