# ------ User Configuration ------
readonly ROOT_LABEL="Arch"
readonly ICON_REPO="https://www.github.com/vinceliuice/WhiteSur-icon-theme.git"
ETC_DOTS_DIR="/home/nick/Lit/dotfiles/etc"     # Directory with reference files
DIFFS_DIR="$HOME/dotcetera"            # Directory to store diff files

# --------- Keys -----------
readonly KEY_DIR="$HOME/.ssh"
readonly GPG_KEYFILE="$KEY_DIR/my-private-key.asc"
readonly SSH_KEY="$KEY_DIR/id_ed25519"
readonly KEY_FILES=(
    "$GPG_KEYFILE"
    "$SSH_KEY"
    "my-public-key.asc"
    "id_ed25519.pub"
)

# --------- Git -----------
readonly GIT_USER="acctux"
readonly GIT_DIR="$HOME/Lit"
readonly DOTFILES_DIR="$GIT_DIR/dotfiles"
readonly BACKUP_DIR="$HOME/overwrittendots"
readonly GIT_REPOS=(
    "docs"
    "dotfiles"
    "fresh"
    "freshpy"
    "post"
)

# Items for Removal
CLEANUP_SUDO_ITEMS=(
    /usr/share/icons/capitaine-cursors
)

CLEANUP_USER_ITEMS=(
    "$HOME/.cargo/paru"
    "$HOME/.keychain"
    "$HOME/.parallel"
    "$HOME/.nv"
)
