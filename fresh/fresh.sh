
pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm
pacman -S --noconfirm git
git clone https://github.com/acctux/fresh.git
cd fresh/fresh
./fresh.sh
