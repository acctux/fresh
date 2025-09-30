
pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm git
git clone https://github.com/acctux/fresh.git
cd fresh/fresh
./fresh.sh
