#!/usr/bin/env bash

# Mount point
MUSB="/mnt/usb"

# Logging helper
log() {
    echo "$1: $2"
}

# Select USB partition
select_usb_partition() {
    mapfile -t devices < <(lsblk -o NAME,TYPE -n | awk '$2=="part" {print $1}')
    [ ${#devices[@]} -eq 0 ] && { log "ERROR" "No partitions found."; exit 1; }

    echo "Partitions:"
    for i in "${!devices[@]}"; do
        echo "$((i+1))) /dev/${devices[i]}"
    done

    echo -n "Select number: "
    read -r choice
    [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#devices[@]} ] && {
        log "ERROR" "Invalid choice."; exit 1
    }

    echo "/dev/${devices[choice-1]}"
}

# Copy files
copy_files() {
    if ! mountpoint -q "$MUSB"; then
        log "ERROR" "Not mounted."; exit 1
    fi
    log "INFO" "Copying files..."

    [ -d "$MUSB/.ssh" ] && sudo cp -r "$MUSB/.ssh" "$HOME" && log "INFO" "Copied .ssh." ||
        log "INFO" "No .ssh found."
    [ -f "$MUSB/wifi.sh" ] && sudo cp "$MUSB/wifi.sh" "$HOME" && log "INFO" "Copied wifi.sh." ||
        log "INFO" "No wifi.sh found."
}

# Unmount USB
unmount_usb() {
    if mountpoint -q "$MUSB"; then
        sudo umount -l "$MUSB" && log "INFO" "Unmounted."
        sudo rmdir "$MUSB" 2>/dev/null || true
    fi
}

# Main
sudo mkdir -p "$MUSB" || { log "ERROR" "Can't create $MUSB."; exit 1; }
trap 'unmount_usb' EXIT
device=$(select_usb_partition)
sudo mount "$device" "$MUSB" || { log "ERROR" "Can't mount $device."; exit 1; }
copy_files
