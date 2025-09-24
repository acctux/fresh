choose_helper() {
    local helper repo_url tmpdir

    echo "Choose your preferred AUR helper:"
    select helper in paru yay; do
        echo "You chose: $helper"
        export AUR_HELPER="$helper"
        break
    done
}

install_via_git() {
    repo_url="https://aur.archlinux.org/$AUR_HELPER.git"

    tmpdir=$(mktemp -d)
    if ! git clone "$repo_url" "$tmpdir/$AUR_HELPER"; then
        echo "[ERROR] Failed to clone $AUR_HELPER from AUR."
        rm -rf "$tmpdir"
        return 1
    fi

    pushd "$tmpdir/$AUR_HELPER" >/dev/null || return 1
    if ! makepkg -si --noconfirm; then
        echo "[ERROR] Failed to build and install $AUR_HELPER from source."
        popd >/dev/null
        rm -rf "$tmpdir"
        return 1
    fi
    popd >/dev/null
    rm -rf "$tmpdir"
    return 0
}

aur_helper() {
    if [[ ! -z $AUR_HELPER ]]; then
        choose_helper
    fi
    if check_cmd $AUR_HELPER; then
        log INFO "Already installed your favorite AUR helper."
    else
        if sudo pacman -Sy --noconfirm "$AUR_HELPER"; then
            return 0
        else
            install_via_git
        fi
        return 1
    fi
}
