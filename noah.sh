pacman -Sy --noconfirm --needed git
rm -rf ~/fresh
git clone https://github.com/acctux/fresh.git ~/fresh

cd $HOME/fresh/fresh

exec ./fresh.sh
