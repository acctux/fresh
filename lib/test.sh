#!/usr/bin/env bash

# This function no longer mounts the drive, it only selects it and prints the command to do so
select_usb_partition() {
    mapfile -t devices < <(lsblk -o NAME,FSTYPE,TYPE,RM,SIZE,MOUNTPOINT -n | awk '$3=="part" {print $0}')

    if [ "${#devices[@]}" -eq 0 ]; then
        echo "No partitions found."
        return 1
    fi

    echo "Available partitions:"
    for i in "${!devices[@]}"; do
        echo "$((i+1))) ${devices[i]}"
    done

    echo -n "Select a partition number: "
    read -r choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#devices[@]} )); then
        echo "Invalid choice."
        return 1
    fi

    local selected_line="${devices[choice-1]}"
    local dev_name
    dev_name=$(awk '{print $1}' <<< "$selected_line")
    echo "/dev/$dev_name"
}

copy_usb_files() {
    mountpoint -q "$MUSB" || { echo "ERROR: $MUSB not mounted."; return 1; }
    echo "INFO: Copying files from USB..."

    [[ -d "$MUSB/.ssh" ]] && cp -r "$MUSB/.ssh" "$HOME" && echo "INFO: Copied SSH keys." ||
        echo "WARNING: No .ssh found."
    [[ -f "$MUSB/wifi.sh" ]] && cp "$MUSB/wifi.sh" "$HOME" && echo "INFO: Copied wifi.sh." ||
        echo "WARNING: No wifi.sh found."
}

unmount_usb_device() {
    mountpoint -q "$MUSB" || return 0
    sudo umount -l "$MUSB" && echo "INFO: Unmounted USB."
    sudo rmdir "$MUSB" 2>/dev/null || true
}

MUSB="/mnt/usb"

# Call the functions
device=$(select_usb_partition) || exit 1

if [ -n "$device" ]; then
    echo "Please run the following command to mount the device and then run this script again:"
    echo "sudo mount $device $MUSB && ./usb.sh"
else
    echo "No device selected."
fi
