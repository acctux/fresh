#!/usr/bin/env bash
set -euo pipefail

# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/replace-files/diffs-make.sh"
source "$(dirname "$0")/lib/replace-files/git-dots-etc.sh"

# ─────── Run Main ────── #
replace_files() {
#    log INFO "Starting system setup"
#    git_dots_etc
    generate_diffs
}
