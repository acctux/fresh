
pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm
pacman -S --noconfirm git
git clone https://github.com/acctux/fresh.git
chmod +x fresh/fresh/fresh.sh
fresh/fresh/fresh.sh
