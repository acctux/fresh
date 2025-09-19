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
    "fresh"
    "post"
    "scripts"
    "Templates"
)

KEY_FILES=(
    "id_ed25519"
    "id_ed25519.pub"
    "my-private-key.asc"
    "my-public-key.asc"
)

USER_GROUPS=(
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

HIDE_APP_FILES=(
    "/usr/share/applications/steam.desktop"
    "/usr/share/applications/octopi-cachecleaner.desktop"
    "/usr/share/applications/octopi-notifier.desktop"
    "/usr/share/applications/octopi-repoeditor.desktop"
    "/usr/share/applications/org.kde.filelight.desktop"
    "/usr/share/applications/jconsole-java-openjdk.desktop"
    "/usr/share/applications/jshell-java-openjdk.desktop"
    "/usr/share/applications/qv4l2.desktop"
    "/usr/share/applications/qvidcap.desktop"
    "/usr/share/applications/xgps.desktop"
    "/usr/share/applications/xgpsspeed.desktop"
    "/usr/share/applications/avahi-discover.desktop"
    "/usr/share/applications/mpv.desktop"
    "/usr/share/applications/bvnc.desktop"
    "/usr/share/applications/bssh.desktop"
)

# Items for Removal
CLEANUP_SUDO_ITEMS=(
    /usr/share/icons/capitaine-cursors
)

CLEANUP_USER_ITEMS=(
    "$HOME/Public"
    "$HOME/.cache"
    "$HOME/.cargo"
    "$HOME/.keychain"
    "$HOME/.parallel"
    "$HOME/.nv"
)
