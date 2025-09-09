#!/usr/bin/env bash

# Global variable for the mount point
MUSB="/mnt/usb"

# Helper function for logging messages
log() {
    local type=$1
    local message=$2
    echo "$type: $message"
}

select_usb_partition() {
    # Get all partitions and filter out those with specific mount points
    mapfile -t devices < <(lsblk -o NAME,FSTYPE,TYPE,SIZE,MOUNTPOINT -n | awk '$3=="part" && $5!~"(/boot|/home|/var/log)" {print $0}')

    if [ "${#devices[@]}" -eq 0 ]; then
        log "ERROR" "No suitable partitions found."
        return 1
    fi

    log "INFO" "Available partitions:"
    for i in "${!devices[@]}"; do
        echo "$((i+1))) ${devices[i]}"
    done

    echo -n "Select a partition number to mount: "
    read -r choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#devices[@]} )); then
        log "ERROR" "Invalid choice."
        return 1
    fi

    local selected_line="${devices[choice-1]}"
    local dev_name
    dev_name=$(awk '{print $1}' <<< "$selected_line")
    echo "/dev/$dev_name"
}

copy_usb_files() {
    mountpoint -q "$MUSB" || { log "ERROR" "$MUSB not mounted."; return 1; }
    log "INFO" "Copying files from USB..."

    [[ -d "$MUSB/.ssh" ]] && cp -r "$MUSB/.ssh" "$HOME" && log "INFO" "Copied SSH keys." ||
        log "WARNING" "No .ssh found."
    [[ -f "$MUSB/wifi.sh" ]] && cp "$MUSB/wifi.sh" "$HOME" && log "INFO" "Copied wifi.sh." ||
        log "WARNING" "No wifi.sh found."
}

unmount_usb_device() {
    mountpoint -q "$MUSB" || return 0
    sudo umount -l "$MUSB" && log "INFO" "Unmounted USB."
    sudo rmdir "$MUSB" 2>/dev/null || true
}

# The main execution block
main() {
    # Ensure the mount point exists and is owned by the user
    sudo mkdir -p "$MUSB"
    sudo chown "$USER:$USER" "$MUSB"

    # Set up a trap to ensure unmounting happens on script exit or error
    trap 'unmount_usb_device' EXIT

    local device
    device=$(select_usb_partition) || { log "ERROR" "Failed to select partition. Exiting."; exit 1; }

    # Mount the selected device
    sudo mount "$device" "$MUSB" || { log "ERROR" "Failed to mount $device."; exit 1; }

    copy_usb_files

    # The trap will handle the unmounting when the script finishes
}

main
