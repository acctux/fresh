pacman -Sy --noconfirm archlinux-keyring
[[ -d ~/fresh ]] || pacman -S --needed git && git clone https://github.com/acctux/fresh.git ~/fresh
exec ~/fresh/ark.sh
