#!/usr/bin/env bash

# Helpers
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

    echo -n "Select a partition number to mount: "
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

# Usage example:
device=$(select_usb_partition) || exit 1
echo "You selected device: $device"

copy_usb_files() {
    mountpoint -q "$MUSB" || { log ERROR "$MUSB not mounted."; return 1; }
    log INFO "Copying files from USB..."

    [[ -d "$MUSB/.ssh" ]] && cp -r "$MUSB/.ssh" "$HOME" && log INFO "Copied SSH keys." ||
        log WARNING "No .ssh found."
    [[ -f "$MUSB/wifi.sh" ]] && cp "$MUSB/wifi.sh" "$HOME" && log INFO "Copied wifi.sh." ||
        log WARNING "No wifi.sh found."
}

unmount_usb_device() {
    mountpoint -q "$MUSB" || return 0
    sudo umount -l "$MUSB" && log INFO "Unmounted USB."
    sudo rmdir "$MUSB" 2>/dev/null || true
}

usb_and_copy_keys() {
    trap 'unmount_usb_device' EXIT
    select_usb_device
    copy_usb_files
    unmount_usb_device
}
