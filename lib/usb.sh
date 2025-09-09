#!/usr/bin/env bash

# Helpers
find_usb_partition() {
    lsblk -o NAME,FSTYPE,TYPE -n | awk '$3 == "part" && ($2 == "vfat" || $2 == "xfat") {print "/dev/" $1}' | while read -r device; do
        blkid -s TYPE "$device" &>/dev/null && echo "$device" && return
    done
    return 1
}

# Main
mount_usb_device() {
    log INFO "Looking for USB device..."
    device=""
    local attempts=12
    local delay=5

    for ((i=1; i<=attempts; i++)); do
        device=$(find_usb_partition) && break
        log INFO "Waiting for USB device (attempt $i/$attempts)..."
        sleep "$delay"
    done

    [[ -z "$device" ]] && { log ERROR "No USB device detected."; return 1; }

    sudo mkdir -p "$MUSB"

    if mountpoint -q "$MUSB"; then
        if [[ -d "$MUSB/.ssh" ]]; then
            log INFO "$MUSB is already mounted and contains .ssh — assuming correct USB."
            return 0
        else
            log ERROR "$MUSB is already mounted, but .ssh is missing — unexpected device?"
            return 1
        fi
    fi

    local fs_type
    fs_type=$(blkid -s TYPE -o value "$device") || { log ERROR "Failed to detect filesystem type."; return 1; }
    sudo mount -t "$fs_type" -o ro "$device" "$MUSB" &&
        log INFO "Mounted $device ($fs_type) at $MUSB." ||
        { log ERROR "Failed to mount USB."; return 1; }
}

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
    mount_usb_device
    copy_usb_files
    unmount_usb_device
}
