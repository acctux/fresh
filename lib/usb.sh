#!/usr/bin/env bash

MUSB="/mnt/usb"

log() {
    echo "$1: $2"
}

list_usb_partitions() {
    lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT,RM -n |
        awk '$4 == "part" {
            printf "%s) /dev/%s  Size: %s  FS: %s  Mounted: %s  Removable: %s\n", ++i, $1, $2, $3, $5, $6
        }'
}

get_usb_devices_array() {
    lsblk -o NAME,TYPE -n | awk '$2 == "part" { print "/dev/" $1 }'
}

prompt_partition_selection() {
    echo "Available partitions:"
    list_usb_partitions

    echo -n "Select number: "
    read -r choice

    mapfile -t devices < <(get_usb_devices_array)

    if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#devices[@]} )); then
        log "ERROR" "Invalid choice."
        exit 1
    fi

    # Set the global variable
    declare -g device="${devices[choice-1]}"
}

copy_files() {
    local mount_path="$1"

    [ -d "$mount_path" ] || { log "ERROR" "Not mounted."; return 1; }

    log "INFO" "Copying files..."

    if [ -d "$mount_path/.ssh" ]; then
        cp -r "$mount_path/.ssh" "$HOME"
        log "INFO" "Copied .ssh."
    else
        log "INFO" "No .ssh found."
    fi

    if [ -f "$mount_path/wifi.sh" ]; then
        cp "$mount_path/wifi.sh" "$HOME"
        log "INFO" "Copied wifi.sh."
    else
        log "INFO" "No wifi.sh found."
    fi
}

unmount_usb() {
    [ -d "$MUSB" ] && sudo umount "$MUSB" && log "INFO" "Unmounted."
    sudo rmdir "$MUSB" 2>/dev/null
}

### --- MAIN --- ###

sudo mkdir -p "$MUSB" || { log "ERROR" "Can't create $MUSB."; exit 1; }
trap 'unmount_usb' EXIT

prompt_partition_selection
sudo mount "$device" "$MUSB" || { log "ERROR" "Can't mount $device."; exit 1; }

copy_files "$MUSB"
