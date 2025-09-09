#!/usr/bin/env bash
set -euo pipefail

# ────────── Global variable declaration ─────────── #
device=""
partitions=()
readonly KEYS_PARTITION_MOUNTPOINT="/mnt/keys_partition"

# ─────────────────── Helpers ─────────────────── #
list_and_store_partitions() {
    log INFO "Detecting available partitions..."

    partitions=()
    local index=1

    while IFS= read -r line; do
        # Split the line into individual fields according to spaces:
        #   name    - device name (e.g., sda1)
        #   size    - size of the partition (e.g., 16G)
        #   fstype  - filesystem type (e.g., ext4, vfat)
        #   type    - device type (e.g., part for partition)
        #   mount   - mount point (empty if not mounted)
        #   rm      - removable device flag (1 if removable, 0 otherwise)
        read -r name size fstype type mount rm <<<"$line"

        # Include only partitions not mounted under root-level directories (/, /home, /var, etc.)
        # Also exclude empty device names (as a precaution)
        if [[ -n "$name" ]] && [[ "$type" == "part" ]] && [[ ! "$mount" =~ ^/ ]]; then
            local dev="/dev/$name"

            # Append device path to the global partitions array
            partitions+=("$dev")

            # Prepare mount status for display; 'UNMOUNTED' if no mountpoint
            local mount_status="${mount:-UNMOUNTED}"

            # Print formatted partition info:
            # Index, device, size, filesystem type, mountpoint, and removable flag
            printf "%d) %-10s Size: %-6s FS: %-6s Mounted: %-12s Removable: %s\n" \
                "$index" "$dev" "$size" "$fstype" "$mount_status" "$rm"

            ((index++))
        fi
    done < <(lsblk -rno NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT,RM)
}

# ─────────────────── Functions ─────────────────── #
select_partition() {
    # Call list_and_store_partitions to populate partitions and display choices
    list_and_store_partitions

    if [[ ${#partitions[@]} -eq 0 ]]; then
        log ERROR "No partitions available for selection."
        exit 1
    fi

    printf "Select partition where keys can be located in the base directory: "
    read -r choice

    # Validate that choice is a number and within valid range
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#partitions[@]} )); then
        log ERROR "Invalid selection: $choice"
        exit 1
    fi

    # Set global device variable based on user selection
    declare -g device="${partitions[choice-1]}"
}

# Mount the selected partition at the predefined mount point.
mount_partition() {
    # Ensure mount directory exists
    sudo mkdir -p "$KEYS_PARTITION_MOUNTPOINT"

    # Attempt to mount the device; errors will exit the script due to 'set -e'
    sudo mount "$device" "$KEYS_PARTITION_MOUNTPOINT"
    log INFO "Mounted $device to $KEYS_PARTITION_MOUNTPOINT"
}

# Copy expected files (.ssh directory and wifi.sh) from mounted USB to user's home directory.
copy_usb_files() {
    # Confirm mount point directory exists
    if [[ ! -d "$KEYS_PARTITION_MOUNTPOINT" ]]; then
        log ERROR "Mount point $KEYS_PARTITION_MOUNTPOINT not found"
        return 1
    fi

    log INFO "Copying files from USB..."

    # Copy .ssh directory if present
    if [[ -d "$KEYS_PARTITION_MOUNTPOINT/.ssh" ]]; then
        cp -r "$KEYS_PARTITION_MOUNTPOINT/.ssh" "$HOME/"
        log INFO "Copied .ssh directory"
    else
        log INFO ".ssh directory not found on USB"
    fi

    # Copy wifi.sh script if present
    if [[ -f "$KEYS_PARTITION_MOUNTPOINT/wifi.sh" ]]; then
        cp "$KEYS_PARTITION_MOUNTPOINT/wifi.sh" "$HOME/"
        log INFO "Copied wifi.sh script"
    else
        log INFO "wifi.sh not found on USB"
    fi
}

# Unmount USB partition and clean up mount directory.
unmount_partition() {
    # Only attempt unmount if mount point is active
    if mountpoint -q "$KEYS_PARTITION_MOUNTPOINT"; then
        sudo umount "$KEYS_PARTITION_MOUNTPOINT"
        log INFO "Unmounted USB from $KEYS_PARTITION_MOUNTPOINT"
    fi

    # Remove the mount directory; ignore errors if it does not exist
    sudo rmdir "$KEYS_PARTITION_MOUNTPOINT" 2>/dev/null || true
}

# ─────────────────── Wrapper ─────────────────── #
usb_and_copy_keys() {
    # Ensure cleanup happens on script exit
    trap unmount_partition EXIT

    select_partition
    # Validate that the selected device exists and is a block device
    if [[ -z "$device" || ! -b "$device" ]]; then
        log ERROR "Invalid or missing device: $device"
        exit 1
    fi
    mount_partition
    copy_usb_files
}
