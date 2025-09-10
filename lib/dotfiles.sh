#!/usr/bin/env bash

backup_files_in_dir() {
    local src_dir="$1"
    local target_dir="$2"

    log INFO "Backing up existing files in $target_dir that overlap with $src_dir..."

    find "$src_dir" -type f | while read -r file; do
        # Compute relative path from source_dir
        local rel_path="${file#$src_dir/}"
        local target_file="$target_dir/$rel_path"
        local backup_target="$BACKUP_DIR/$rel_path"
        local BACKUP_DIR_path
        BACKUP_DIR_path=$(dirname "$backup_target")

        if [[ -f "$target_file" && ! -L "$target_file" ]]; then
            mkdir -p "$BACKUP_DIR_path"
            cp "$target_file" "$backup_target"
            log INFO "Backed up: $target_file -> $backup_target"
        fi
    done
}

stow_dotfiles() {
    log INFO "Backing up dotfiles before stowing..."
    backup_files_in_dir "$DOTFILES_DIR/Home" "$HOME"

    log INFO "Stowing dotfiles..."
    command -v stow >/dev/null || { log ERROR "stow not installed."; return 1; }

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
    if [[ ! -d "$src_dir" ]]; then
        log ERROR "Directory $src_dir not found."
        return 1
    fi

    backup_files_in_dir "$src_dir" "/etc"

    # Use find with process substitution to handle all files recursively
    while IFS= read -r -d '' file; do
        local dest="/${file#$src_dir/}"
        sudo mkdir -p "$(dirname "$dest")"
        if sudo cp "$file" "$dest"; then
            log INFO "Copied $file -> $dest"
        else
            log ERROR "Failed to copy $file -> $dest"
        fi
    done < <(find "$src_dir" -type f -print0)

    # These commands are now in the same process and will work correctly.
    sudo chown root:root /etc/sudoers.d/mysudo
    sudo chmod 440 /etc/sudoers.d/mysudo
}


setup_dotfiles_and_config() {
    stow_dotfiles
    copy_system_config
}
