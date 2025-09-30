
sudo pacman -Syu --noconfirm --needed git
rm -rf ~/fresh
git clone https://github.com/acctux/fresh.git
chmod +x fresh/fresh/main.sh
fresh/fresh/main.sh
