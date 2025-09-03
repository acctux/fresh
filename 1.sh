#!/usr/bin/env bash
set -euo pipefail

sudo mkdir -p /mnt/usb
sudo mount /dev/sdb1 /mnt/usb
cd /mnt/usb
mkdir -p "$HOME/.ssh"
cp -r "ssh" "$HOME/.ssh"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cp wifi.sh "$HOME"
./2.sh & exit 0
