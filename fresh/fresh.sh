pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm
pacman -S --noconfirm --needed git
rm -rf ~/fresh
git clone https://github.com/acctux/fresh.git ~/fresh
chmod +x fresh/fresh/main.sh
fresh/fresh/main.sh
