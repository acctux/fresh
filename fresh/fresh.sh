
pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm
pacman -S --noconfirm git
if ! git clone https://github.com/acctux/fresh.git; then
    pacman-key --refresh-keys
    pacman -S --noconfirm git
    git clone https://github.com/acctux/fresh.git
fi
cd fresh/fresh
./fresh.sh
