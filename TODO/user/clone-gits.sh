clone_gits() {
    mkdir -p "$GIT_DIR"
    cd "$GIT_DIR"

    ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null

    for repo in "${GIT_REPOS[@]}"; do
        [[ -d "$repo" ]] && { log INFO "$repo already exists."; continue; }
        git clone "git@github.com:$GIT_USER/$repo.git" && log INFO "Cloned $repo." ||
            log ERROR "Failed to clone $repo."
    done
}
