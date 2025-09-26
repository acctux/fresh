# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/replace-files/generate-diffs.sh"
source "$(dirname "$0")/lib/replace-files/move-and-stow.sh"
source "$(dirname "$0")/lib/replace-files/clone-gits.sh"
source "$(dirname "$0")/lib/replace-files/gtk-symlinks.sh"
source "$(dirname "$0")/lib/replace-files/create-patches.sh"

# ─────── Run Main ────── #
replace_files() {
    clone_gits
    move_and_stow
    gtk_symlinks
    cd /etc
    sudo etckeeper init
    sudo etckeeper commit -m "/etc with no modifications"
    ansible-galaxy collection install ansible.posix
    log INFO "Creating diff patches"
    create_patches
    cp "$HOME/fresh/patch.yml" "$DIFFS_DIR"
    cd "$DIFFS_DIR"
    ansible-playbook patch.yml --ask-become-pass
    sudo etckeeper commit -m "immediately after modifications"
}
