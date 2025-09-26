# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/diffs/create-patches.sh"
source "$(dirname "$0")/lib/diffs/etckeeper.sh"
source "$(dirname "$0")/lib/diffs/ansterrible.sh"
# ─────── Run Main ────── #
apply_diffs() {
    if [ ! -d "/etc/.git" ]; then #    check permissions for the patch udev rules and sudoers
        log INFO "etckeeper not initialized. Running setup commands."
        cd /etc
        init_etckeeper
        log INFO "✅ etckeeper setup complete."
    fi
    log INFO "Creating diff patches"
    # create_patches
    # ansible_plugins
    log INFO "Applying patches."
    cd "$DIFFS_DIR"
    sudo python /home/nick/Lit/fresh/lib/diffs/diffs.py
    # apply_ansible
}
