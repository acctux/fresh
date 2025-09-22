# User Configuration
readonly ROOT_LABEL="Arch"
readonly GIT_USER="acctux"
readonly GIT_LIT="$HOME/Lit"
readonly KEY_DIR="$HOME/.ssh"
readonly DEFAULT_COUNTRY_CODE="US"
readonly GPG_KEYFILE="$KEY_DIR/my-private-key.asc"
readonly MY_PASS="$KEY_DIR/recipes.asc"
readonly DOTFILES_DIR="$HOME/Lit/dotfiles"
readonly LOG_FILE="$HOME/bootstrap.log"
readonly BACKUP_DIR="$HOME/overwrittendots"

# ─────── IMPORTANT ────── #
# Needs DEFAULT_WIFI_SSID=""  DEFAULT_WIFI_SSID="" or won't be sourced
readonly WIFI_CREDENTIALS="$KEYS_MNT/.ssh/wifi.env"

readonly GIT_REPOS=(
    "docs"
    "dotfiles"
    "freshpy"
    "post"
)

readonly KEY_FILES=(
    "id_ed25519"
    "id_ed25519.pub"
    "my-private-key.asc"
    "my-public-key.asc"
)

readonly USER_GROUPS=(
    input
    audio
    video
    network
    storage
    rfkill
#    kvm
    docker
    games
    gamemode
    log
)

# Items for Removal
CLEANUP_SUDO_ITEMS=(
    /usr/share/icons/capitaine-cursors
)

CLEANUP_USER_ITEMS=(
    "$HOME/Desktop"
    "$HOME/Documents"
    "$HOME/Public"
    "$HOME/fresh"
    "$HOME/.cache"
    "$HOME/.cargo"
    "$HOME/.keychain"
    "$HOME/.parallel"
    "$HOME/.nv"
)
