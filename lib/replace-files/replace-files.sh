#!/usr/bin/env bash
set -euo pipefail

# ───────── Variables ──────── #
readonly LOG_FILE="$HOME/bootstrap.log"

# ─────── Source Configuration ────── #
source "$(dirname "$0")/conf/conf_user.sh"

# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/replace-files/diffs-make.sh"
source "$(dirname "$0")/lib/replace-files/git-dots-etc.sh"

# ─────── Run Main ────── #
setup_core() {
    log INFO "Starting system setup"
    call_generate_diff
    git_dots_etc
}
