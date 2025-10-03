pacman -Sy --noconfirm archlinux-keyring
rm -rf ~/fresh
pacman -S --needed git
git clone https://github.com/acctux/fresh.git ~/fresh
exec ~/fresh/noah.sh
