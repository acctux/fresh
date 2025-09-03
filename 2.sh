#!/usr/bin/env bash
set -euo pipefail

#Check and create necessary environment

ROOT_LABEL="Root"
source "$HOME/wifi.sh"

wifi_auto_connect() {
    ping -c3 -i1 1.1.1.1 &>/dev/null && return 0
    local default_ssid="${DEFAULT_WIFI_SSID:-}" default_pass="${DEFAULT_WIFI_PASS:-}"
    if [[ -n "$default_ssid" && -n "$default_pass" ]]; then
        wifi_connect "$default_ssid" "$default_pass" && export WIFI_SSID="$default_ssid" WIFI_PASS="$default_pass" && return 0
    fi
    nmcli -f SSID,SIGNAL,BARS device wifi list | awk 'NR>1 {printf "  %-30s %3s%%  %s\n", $1,$2,$3}'
    read -rp "Enter SSID: " WIFI_SSID
    read -rsp "Enter Password: " WIFI_PASS
    echo
    [[ -n "$WIFI_SSID" && -n "$WIFI_PASS" ]]
    wifi_connect "$WIFI_SSID" "$WIFI_PASS"
    export WIFI_SSID WIFI_PASS
}

install_nec() {
    sudo sed -i 's/timeout 3/timeout 1/' /boot/loader/loader.conf
    sudo pacman -S --needed reflector xdg-user-dirs base-devel
    sudo reflector --verbose --latest 10 --country 'United States' --sort rate --save /etc/pacman.d/mirrorlist
}

ensure_root_label() {
    local mount_point="/" current_label
    current_label=$(blkid -s LABEL -o value "$(findmnt -n -o SOURCE "$mount_point")" 2>/dev/null || true)
    [[ "$current_label" != "$ROOT_LABEL" ]] && sudo btrfs filesystem label "$mount_point" "$ROOT_LABEL" || true
}

setup_dirs() {
    xdg-user-dirs-update
    local games_dir="$HOME/Games"
    local lit_dir="$HOME/Lit"
    mkdir -p "$games_dir"
    echo -e "[Desktop Entry]\nIcon=folder-games" > "$games_dir/.directory"
    mkdir -p "$lit_dir"
    echo -e "[Desktop Entry]\nIcon=folder-github" > "$lit_dir/.directory"
}

create_git() {
    cd ~/Lit
    git clone https://github.com/acctux/scripts.git
    git clone https://github.com/acctux/dotfiles.git
    git clone https://github.com/acctux/Templates.git
    cd "$HOME/Lit/scripts"
    git clone https://github.com/acctux/fresh.git
    cp -r "$HOME/Lit/Templates" "$HOME/Templates"
}

main(){
    wifi_auto_connect
    install_nec
    ensure_root_label
    setup_dirs
    create_git
    cd "$HOME/Lit/dotfiles" && sh ./main.sh & exit 0
}
main
