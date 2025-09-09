#!/usr/bin/env bash

# Mount point
MUSB="/mnt/usb"

# Log messages
log() {
    echo "$1: $2"
}

# Select USB partition
select_usb_partition() {
    # List partitions
    mapfile -t devices < <(lsblk -o NAME,TYPE -n | awk '$2=="part" {print $1}')
    if [ ${#devices[@]} -eq 0 ]; then
        log "ERROR" "No USB partitions found."
        exit 1
    fi

    echo "Partitions:"
    for i in "${!devices[@]}"; do
        echo "$((i+1))) /dev/${devices[i]}"
    done

    echo -n "Select number: "
    read choice
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#devices[@]} ]; then
        log "ERROR" "Invalid choice."
        exit 1
    fi

    device="/dev/${devices[choice-1]}"  # Set global device variable
}

# Copy files
copy_files() {
    [ -d "$MUSB" ] || { log "ERROR" "Not mounted."; exit 1; }
    log "INFO" "Copying files..."

    [ -d "$MUSB/.ssh" ] && cp -r "$MUSB/.ssh" "$HOME" && log "INFO" "Copied .ssh." ||
        log "INFO" "No .ssh found."
    [ -f "$MUSB/wifi.sh" ] && cp "$MUSB/wifi.sh" "$HOME" && log "INFO" "Copied wifi.sh." ||
        log "INFO" "No wifi.sh found."
}

# Unmount USB
unmount_usb() {
    [ -d "$MUSB" ] && sudo umount "$MUSB" && log "INFO" "Unmounted."
    sudo rmdir "$MUSB" 2>/dev/null
}

# Main
sudo mkdir -p "$MUSB" || { log "ERROR" "Can't create $MUSB."; exit 1; }
trap 'unmount_usb' EXIT
select_usb_partition  # Call directly, no subshell
sudo mount "$device" "$MUSB" || { log "ERROR" "Can't mount $device."; exit 1; }
copy_files
