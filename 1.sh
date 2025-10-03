pacman -Sy --noconfirm archlinux-keyring
rm -rf ~/fresh
pacman -Sy --noconfirm --needed git
git clone https://github.com/acctux/fresh.git ~/fresh
exec ~/fresh/ark.sh
