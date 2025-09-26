generate_target_list() {
    fd --type f --hidden --exclude .git . "$GIT_DIR/dotfiles" | sed "s|^$GIT_DIR/dotfiles/|$HOME/|" > /tmp/dotfiles-targets.txt
}

backup_conflicts() {
    local backup_dir="$HOME/dotcetera"

    while read -r target; do
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            local rel_path="${target#$HOME/}"
            local dest_dir="$backup_dir/$(dirname "$rel_path")"
            mkdir -p "$dest_dir"
            echo "[INFO] Moving '$target' to '$dest_dir/'"
            mv "$target" "$dest_dir/"
        fi
    done < /tmp/dotfiles-targets.txt
}

stow_dotfiles() {
    echo "[INFO] Stowing dotfiles..."
    if stow --no-folding -d "$GIT_DIR" -t "$HOME" dotfiles; then
        echo "[INFO] Stow succeeded."
    else
        echo "[ERROR] Stow failed."
        return 1
    fi
}

move_and_stow() {
    echo "[INFO] Generating target file list..."
    generate_target_list

    echo "[INFO] Backing up existing conflicts..."
    backup_conflicts

    stow_dotfiles
}
