clone_git_repos() {

    cd "$GIT_DIR"

    ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null

    for repo in "${GIT_REPOS[@]}"; do
        [[ -d "$repo" ]] && { log INFO "$repo already exists."; continue; }
        git clone "git@github.com:$GIT_USER/$repo.git" && log INFO "Cloned $repo." ||
            log ERROR "Failed to clone $repo."
    done
}

stow_dotfiles() {
    log INFO "Stowing dotfiles..."
    if stow -v --no-folding -d "$GIT_DIR" -t "$HOME" dotfiles; then
       return 0
    fi
    log ERROR "Failed to stow dotfiles."
}

gtk_symlinks() {
    log INFO "Creating GTK theme symlinks..."
    local gtk_config_dir="$HOME/.config/gtk-4.0"
    mkdir -p "$gtk_config_dir"
    ln -sf "$HOME/.themes/Sweet-Ambar-Blue-Dark/gtk-4.0/gtk.css" "$gtk_config_dir/gtk.css"
    ln -sf "$HOME/.themes/Sweet-Ambar-Blue-Dark/gtk-4.0/gtk-dark.css" "$gtk_config_dir/gtk-dark.css"
}

git_dots_etc() {
    clone_git_repos
    stow_dotfiles
    gtk_symlinks
}
