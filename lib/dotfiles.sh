#!/usr/bin/env bash

backup_dotfiles_dry_run() {
    local source_dir="$DOTFILES_DIR/Home"
    local backup_dir="$HOME/overwrittendots"

    log INFO "Dry run: checking which dotfiles would be backed up..."

    find "$source_dir" -type f | while read -r file; do
        # Get relative path from source_dir
        local rel_path="${file#$source_dir/}"
        local target="$HOME/$rel_path"
        local backup_target="$backup_dir/$rel_path"
        local backup_dir_path
        backup_dir_path=$(dirname "$backup_target")

        if [[ -f "$target" && ! -L "$target" ]]; then
            echo "Would create directory: $backup_dir_path"
            echo "Would move: $target -> $backup_target"
        fi
    done
}

stow_dotfiles() {
    log INFO "Stowing dotfiles..."
    command -v stow >/dev/null || { log ERROR "stow not installed."; return 1; }
    # "Home" refers to folder in DOTFILES_DIR
    stow --no-folding -d "$DOTFILES_DIR" -t "$HOME" Home ||
        { log ERROR "Failed to stow dotfiles."; return 1; }

    log INFO "Creating GTK theme symlinks..."
    local gtk_config_dir="$HOME/.config/gtk-4.0"
    mkdir -p "$gtk_config_dir"
    ln -sf "$HOME/.themes/Sweet-Ambar-Blue-Dark/gtk-4.0/gtk.css" "$gtk_config_dir/gtk.css"
    ln -sf "$HOME/.themes/Sweet-Ambar-Blue-Dark/gtk-4.0/gtk-dark.css" "$gtk_config_dir/gtk-dark.css"
    fc-cache -f || log WARNING "Failed to update font cache."
}

copy_system_config() {
    log INFO "Copying system config files..."
    local src_dir="$DOTFILES_DIR/etc"
    [[ -d "$src_dir" ]] || { log ERROR "Directory $src_dir not found."; return 1; }
    while IFS= read -r -d '' file; do
        local dest="/${file#$src_dir/}"
        sudo mkdir -p "$(dirname "$dest")"
        sudo cp "$file" "$dest" && log INFO "Copied $dest" ||
            log ERROR "Failed to copy $dest"
    done < <(find "$src_dir" -type f -print0)
    sudo chown root:root /etc/sudoers.d/mysudo
    sudo chmod 440 /etc/sudoers.d/mysudo
}

manage_services() {
    log INFO "Managing services..."
    for service in "${SERVENABLE[@]}"; do
        systemctl list-unit-files "$service.service" &>/dev/null &&
            sudo systemctl enable "$service" && log INFO "Enabled $service" ||
            log WARNING "Service $service not found."
    done
    for service in "${SERVDISABLE[@]}"; do
        systemctl list-unit-files "$service.service" &>/dev/null &&
            sudo systemctl disable "$service" && log INFO "Disabled $service" ||
            log WARNING "Service $service not found."
    done
    systemctl --user enable pipewire pipewire-pulse wireplumber ssh-agent 2>/dev/null ||
        log WARNING "Failed to enable user services."
}

cleanup_files() {
    log INFO "Cleaning up files..."
    for item in "${CLEANUP_USER_FILES[@]}"; do
        [[ -e "$item" ]] && rm -rf "$item" && log INFO "Removed $item" ||
            log WARNING "Item $item not found."
    done
    for file in "${CLEANUP_SYS_FILES[@]}"; do
        [[ -f "$file" ]] && sudo rm -f "$file" && log INFO "Removed $file" ||
            log WARNING "File $file not found."
    done
    for dir in "${CLEANUP_SYS_DIRS[@]}"; do
        [[ -d "$dir" ]] && sudo rm -rf "$dir" && log INFO "Removed $dir" ||
            log WARNING "Directory $dir not found."
    done
}

setup_dotfiles_and_config() {
    backup_existing_dotfiles
    stow_dotfiles
    copy_system_config
    manage_services
    cleanup_files
}
