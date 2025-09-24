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

    git clone "$repo_url" "$tmpdir/$AUR_HELPER"
    pushd "$tmpdir/$AUR_HELPER" >/dev/null
    makepkg -si --noconfirm
    popd >/dev/null
    rm -rf "$tmpdir"
    return 0
}

aur_helper() {
    if ! check_cmd paru; then
	if ! chek_cmd yay; then
	    choose_helper
	else
	    AUR_HELPER="yay"
	fi
    else
	AUR_HELPER="paru"
    fi
    if ! sudo pacman -Sy --needed "$AUR_HELPER"; then
	install_via_git
    fi
}
