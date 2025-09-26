# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/stow/clone-gits.sh"
source "$(dirname "$0")/lib/stow/move-and-stow.sh"
source "$(dirname "$0")/lib/stow/gtk-symlinks.sh"

# ─────── Run Main ────── #
replace_files() {
     sudo cp ~/.gitconfig /root
     clone_gits
     move_and_stow
     gtk_symlinks
}
