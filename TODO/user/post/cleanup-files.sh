# Items for Removal
CLEANUP_SUDO_ITEMS=(
    /usr/share/icons/capitaine-cursors
)

CLEANUP_USER_ITEMS=(
    "$HOME/.cargo"
    "$HOME/.cache/paru"
    "$HOME/.keychain"
    "$HOME/.parallel"
    "$HOME/.nv"
)

cleanup_files() {
    log INFO "Cleaning up user files..."
    for item in "${CLEANUP_USER_ITEMS[@]}"; do
        if [[ -e "$item" ]]; then
            rm -rf "$item"
            log INFO "Removed: $item"
        else
            log WARNING "Item not found: $item"
        fi
    done

    log INFO "Cleaning up system files (sudo)..."
    for item in "${CLEANUP_SUDO_ITEMS[@]}"; do
        if [[ -e "$item" ]]; then
            sudo rm -rf "$item"
            log INFO "Removed (sudo): $item"
        else
            log WARNING "Item not found (sudo): $item"
        fi
    done
}
