setup_aur_helper() {
    local helper repo_url tmpdir

    echo "Choose your preferred AUR helper:"
    select choice in paru yay; do
        if [[ "$choice" == "paru" || "$choice" == "yay" ]]; then
            helper="$choice"
            break
        else
            echo "Invalid choice. Please choose again."
        fi
    done

    echo "[INFO] Attempting to install $helper via pacman..."
    if sudo pacman -Sy --noconfirm "$helper"; then
        export AUR_HELPER="$helper"
        return 0
    fi

    echo "[WARNING] Failed to install $helper via Chaotic Aur. Falling back to manual installation..."

    if [[ "$helper" == "paru" ]]; then
        repo_url="https://aur.archlinux.org/paru.git"
    else
        repo_url="https://aur.archlinux.org/yay.git"
    fi

    tmpdir=$(mktemp -d)
    if ! git clone "$repo_url" "$tmpdir/$helper"; then
        echo "[ERROR] Failed to clone $helper from AUR."
        rm -rf "$tmpdir"
        return 1
    fi

    pushd "$tmpdir/$helper" >/dev/null || return 1
    if ! makepkg -si --noconfirm; then
        echo "[ERROR] Failed to build and install $helper from source."
        popd >/dev/null
        rm -rf "$tmpdir"
        return 1
    fi
    popd >/dev/null
    rm -rf "$tmpdir"

    export AUR_HELPER="$helper"
    return 0
}

detect_or_setup_aur_helper() {
    if check_cmd paru || check_cmd yay; then
        if check_cmd paru; then
            export AUR_HELPER="paru"
            echo "[INFO] Using 'paru' as AUR helper."
        else
            export AUR_HELPER="yay"
            echo "[INFO] Using 'yay' as AUR helper."
        fi
    else
        echo "[INFO] No AUR helper found. Starting setup..."
        setup_aur_helper || {
            echo "[ERROR] Failed to set up AUR helper."
            return 1
        }
    fi
}

install_pacman_packages() {
    log INFO "Installing packages..."
    $AUR_HELPER -S --needed "${PACMAN[@]}" || {
        log ERROR "Failed to install Pacman packages."
        return 1
    }
}

install_aur_packages() {
    log INFO "Installing AUR packages with paru..."
    $AUR_HELPER -S --needed "${AUR[@]}" || {
        log ERROR "Failed to install AUR packages."
        return 1
    }
}

pacman_aur_packages() {
    detect_or_setup_aur_helper
    # Install pacman list with AUR helper in case of no chaotic or
    # incorrectly categorized packages
    install_pacman_packages
    install_aur_packages
}
