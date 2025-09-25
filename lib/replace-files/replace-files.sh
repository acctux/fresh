#!/usr/bin/env bash
set -euo pipefail

# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/replace-files/generate-diffs.sh"
source "$(dirname "$0")/lib/replace-files/git-dots-etc.sh"

# ─────── Run Main ────── #
replace_files() {
    cd /etc
    sudo etckeeper init
    sudo etckeeper add .
    sudo etckeeper commit -m "/etc with no modifications"
    rm -f ~/.ssh/config
    ansible-galaxy collection install ansible.posix
    log INFO "Starting system setup"
    git_dots_etc
    handle_etc_files
    cd "$ETC_DOTS_DIR"
    ansible-playbook patch.yml --ask-become-pass
    sudo etckeeper add .
    sudo etckeeper commit -m "immediately after modifications"
}
