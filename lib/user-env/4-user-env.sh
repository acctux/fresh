# ─────── Source Functions ────── #
source "$(dirname "$0")/lib/utils.sh"
source "$(dirname "$0")/lib/user-env/setup-folders.sh"
source "$(dirname "$0")/lib/user-env/install-icons.sh"
source "$(dirname "$0")/lib/user-env/mariadb.sh"
source "$(dirname "$0")/lib/user-env/user-setup.sh"

# ─────── Run Main ────── #
user_env() {
   user_setup
   setup_folders
   install_icons
#   mariadb
}
