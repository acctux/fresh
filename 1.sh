pacman -Sy --noconfirm archlinux-keyring
rm -rf ~/fresh
pacman -Sy --noconfirm --needed git
git clone https://github.com/acctux/fresh.git ~/fresh
echo "Executing ArchTitus Script"

cd $HOME/fresh

echo "please run ./ark.sh"
exit 0