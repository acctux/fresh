#Tested working
pacman -Sy --noconfirm archlinux-keyring
pacman -Sy --noconfirm --needed git
# untested but likely working
rm -rf ~/fresh
git clone https://github.com/acctux/fresh.git ~/fresh

cd $HOME/fresh/fresh

exec ./fresh.sh
