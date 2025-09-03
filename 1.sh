#!/usr/bin/env bash
set -euo pipefail

device=$(lsblk -o NAME,TYPE -nr | grep 'part' | grep -v '^sda' | awk '{print "/dev/" $1}' | head -n 1)
musb="/mnt/usb"

if [ -n "$device" ]; then
    sudo mkdir -p "$musb"
    sudo mount "$device" "$musb"
    echo "Mounted $device to $musb"
else
    echo "No suitable USB device found."
fi

if [ -d "$musb" ]; then
    cd $musb
    mkdir -p "$HOME/.ssh"
    cp -r "ssh" "$HOME/.ssh"
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
    cp wifi.sh "$HOME"
else
    echo "No USB folder found."
fi

./2.sh & exit 0
