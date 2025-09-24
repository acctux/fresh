#!/usr/bin/env bash
set -euo pipefail

# ─────── Source Configuration ────── #
source "$(dirname "$0")/conf/conf_user.sh"

# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/replace-files/diffs-make.sh"
source "$(dirname "$0")/lib/replace-files/git-dots-etc.sh"

# ─────── Run Main ────── #
replace_files() {
    log INFO "Starting system setup"
    git_dots_etc
    call_generate_diff
}
