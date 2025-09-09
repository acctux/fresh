##!/usr/bin/env bash

# Mount point
MUSB="/mnt/usb"

# Logging helper
log() {
    echo "$(echo "$1" | tr '[:lower:]' '[:upper:]'): $2"
}

# Select USB partition
select_usb_partition() {
    # List partitions (focus on USB-like; adjust if needed)
    mapfile -t devices < <(lsblk -o NAME,TYPE -n | awk '$2=="part" {print $1}')

    if [ ${#devices[@]} -eq 0 ]; then
        log "ERROR" "No partitions found."
        return 1
    fi

    log "INFO" "Available partitions:"
    for i in "${!devices[@]}"; do
        echo "$((i+1))) /dev/${devices[i]}"
    done

    echo -n "Select partition number: "
    read -r choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#devices[@]} ]; then
        log "ERROR" "Invalid choice."
        return 1
    fi

    echo "/dev/${devices[choice-1]}"
}

# Copy files from USB
copy_usb_files() {
    if ! mountpoint -q "$MUSB"; then
        log "ERROR" "$MUSB not mounted."
        return 1
    fi

    log "INFO" "Copying files from USB..."

    if [ -d "$MUSB/.ssh" ]; then
        cp -r "$MUSB/.ssh" /root/
        log "INFO" "Copied .ssh to /root."
    else
        log "WARNING" "No .ssh found."
    fi

    if [ -f "$MUSB/wifi.sh" ]; then
        cp "$MUSB/wifi.sh" /root/
        log "INFO" "Copied wifi.sh to /root."
    else
        log "WARNING" "No wifi.sh found."
    fi
}

# Unmount USB
unmount_usb() {
    if mountpoint -q "$MUSB"; then
        umount -l "$MUSB" && log "INFO" "Unmounted $MUSB."
        rmdir "$MUSB" 2>/dev/null || true
    fi
}

# Main
main() {
    mkdir -p "$MUSB"

#    trap 'unmount_usb' EXIT

    local device
    device=$(select_usb_partition) || {
        log "ERROR" "Failed to select partition."
        exit 1
    }

    mount "$device" "$MUSB" || {
        log "ERROR" "Failed to mount $device."
        exit 1
    }

    copy_usb_files
}

main "$@"
