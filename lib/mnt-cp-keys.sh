#!/usr/bin/env bash
set -euo pipefail

# ────────── Global variable declaration ─────────── #
device=""
partitions=()
readonly KEYS_MOUNTPOINT="/mnt/keys"

# ─────────────────── Helpers ─────────────────── #
list_partitions() {
    log INFO "Detecting available partitions..."

    partitions=()
    local index=1

    while read -r name size fstype type mount rm; do
        [[ "$type" != "part" || -z "$name" || "$mount" =~ ^/ ]] && continue

        local dev="/dev/$name"
        partitions+=("$dev")
        local mount_status="${mount:-UNMOUNTED}"

        printf "%2d) %-12s Size: %-6s FS: %-6s Mounted: %-12s Removable: %s\n" \
            "$index" "$dev" "$size" "$fstype" "$mount_status" "$rm"

        ((index++))
    done < <(lsblk -rno NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT,RM --sort NAME)
}

# ─────────────────── Functions ─────────────────── #
check_existing_files() {
    # Check if .ssh directory or wifi.sh file already exists in $HOME
    if [[ -d "$HOME/.ssh" ]] || [[ -f "$HOME/wifi.sh" ]]; then
        log INFO "Skipping mounted device copy: .ssh directory or wifi.sh already exists in $HOME"
        return 1
    fi
    return 0
}

select_partition() {
    # Capture printed device paths into a local array
    mapfile -t partitions < <(list_partitions)

    if [[ ${#partitions[@]} -eq 0 ]]; then
        log ERROR "No partitions available for selection."
        exit 1
    fi

    printf "Select partition where keys can be located in the base directory: "
    read -r choice

    if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#partitions[@]} )); then
        log ERROR "Invalid selection: $choice"
        exit 1
    fi

    local device="${partitions[choice-1]}"
    sudo mkdir -p "$KEYS_MOUNTPOINT"
    sudo mount "$device" "$KEYS_MOUNTPOINT"
    log INFO "Mounted $device to $KEYS_MOUNTPOINT"
}

copy_key_files() {
    # Confirm mount point directory exists
    if [[ ! -d "$KEYS_MOUNTPOINT" ]]; then
        log ERROR "Mount point $KEYS_MOUNTPOINT not found"
        return 1
    fi

    log INFO "Copying files from mounted device..."

    # Copy .ssh directory if present
    if [[ -d "$KEYS_MOUNTPOINT/.ssh" ]]; then
        cp -r "$KEYS_MOUNTPOINT/.ssh" "$HOME/"
        log INFO "Copied .ssh directory"
    else
        log INFO ".ssh directory not found on mounted device"
    fi

    # Copy wifi.sh script if present
    if [[ -f "$KEYS_MOUNTPOINT/wifi.sh" ]]; then
        cp "$KEYS_MOUNTPOINT/wifi.sh" "$HOME/"
        log INFO "Copied wifi.sh script"
    else
        log INFO "wifi.sh not found on mounted device"
    fi
}

unmount_partition() {
    # Only attempt unmount if mount point is active
    if mountpoint -q "$KEYS_MOUNTPOINT"; then
        sudo umount "$KEYS_MOUNTPOINT"
        log INFO "Unmounted mounted device from $KEYS_MOUNTPOINT"
    fi

    # Remove the mount directory; ignore errors if it does not exist
    sudo rmdir "$KEYS_MOUNTPOINT" 2>/dev/null || true
}

# ─────────────────── Wrapper ─────────────────── #
mounted device_and_copy_keys() {
    if ! check_existing_files; then
       return 0  # Skip mounted device operations and continue main script
    fi
    select_partition
    # Validate that the selected device exists and is a block device
    if [[ -z "$device" || ! -b "$device" ]]; then
        log ERROR "Invalid or missing device: $device"
        exit 1
    fi
    mount_partition
    copy_key_files
    unmount_partition
}
