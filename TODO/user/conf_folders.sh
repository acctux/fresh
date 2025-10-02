readonly BOOKMARKS="$HOME/.local/bin/bookmarks"

declare -A CUSTOM_FOLDERS=(
    ["$HOME/Games"]="folder-games"
    ["$GIT_DIR"]="folder-github"
    ["$BOOKMARKS"]="folder-favorites"
)

REMOVE_XDG_DIRS=(
    "XDG_PUBLICSHARE_DIR"
    "XDG_DOCUMENTS_DIR"
    "XDG_DESKTOP_DIR"
)

# Custom XDG entries to add (format: KEY="VALUE")
CUSTOM_XDG_ENTRIES=(
    'XDG_LIT_DIR="$HOME/Lit"'
)
