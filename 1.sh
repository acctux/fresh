#!/usr/bin/env bash
set -euo pipefail

find_usb_partition() {
    local usb_disks disk part

    # Loop through all disk names with transport type 'usb'
    while read -r name tran; do
        if [[ "$tran" == "usb" ]]; then
            usb_disks+=("$name")
        fi
    done < <(lsblk -S -o NAME,TRAN -n)

    # Check each USB disk for its first partition
    for disk in "${usb_disks[@]}"; do
        while read -r part_name; do
            if [[ "$part_name" != "$disk" ]]; then
                part="/dev/$part_name"
                echo "$part"
                return 0
            fi
        done < <(lsblk -ln -o NAME "/dev/$disk")
    done

    # No USB partition found
    return 1
}


device=$(find_usb_partition)
musb="/mnt/usb"

if [ -n "$device" ]; then
    sudo mkdir -p "$musb"
    sudo mount "$device" "$musb"
    chmod +x "$HOME/fresh/2.sh"
    echo "Mounted $device to $musb"
else
    echo "No suitable USB device found."
fi

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    cd $musb
    mkdir -p "$HOME/.ssh"
    cp -r ".ssh" "$HOME/.ssh"
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
    cp wifi.sh "$HOME"
else
    echo "No USB folder found."
fi
cd "$HOME/fresh"
./2.sh & exit 0
