select_from_menu() {
    # Generic menu selection helper
    local prompt="$1"
    shift
    local options=("$@")
    local num="${#options[@]}"
    local choice
    while true; do
        info "$prompt" >&2
        for i in "${!options[@]}"; do
            printf '%d) %s\n' "$((i+1))" "${options[i]}" >&2
        done
        if ! read -rp "Select an option (1-${num}): " choice; then
            fatal "Input aborted"
        fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= num )); then
            echo "${options[$((choice-1))]}"
            return 0
        fi
        warning "Invalid choice. Please select a number between 1 and ${num}." >&2
    done
}
#######################################
# Prompt helpers
#######################################

validate_disk() {
    local disk="$1"
    if [[ ! -b "$disk" ]]; then
        fatal "Disk $disk does not exist or is not a block device"
    fi

    if [[ $(lsblk -dn -o TYPE "$disk") != "disk" ]]; then
        fatal "Target $disk is not a disk device"
    fi

    if lsblk -rno MOUNTPOINT "$disk" | grep -qE '\S'; then
        fatal "Disk $disk has mounted partitions. Please unmount them before proceeding."
    fi

    success "Disk $disk validated"
}

validate_disk_size() {
    local disk_bytes efi_bytes swap_bytes root_min bytes_required
    disk_bytes=$(lsblk -b -dn -o SIZE "$DISK")
    efi_bytes=$(numfmt --from=iec "$EFI_SIZE")
    swap_bytes=$(numfmt --from=iec "$SWAP_SIZE")
    root_min=$((1 * 1024 * 1024 * 1024))
    bytes_required=$((efi_bytes + swap_bytes + root_min))
    if (( disk_bytes < bytes_required )); then
        fatal "Disk size $(numfmt --to=iec $disk_bytes) is smaller than required $(numfmt --to=iec $bytes_required)"
    fi
    success "Disk has sufficient capacity: $(numfmt --to=iec $disk_bytes)"
}

#######################################
# User input functions
#######################################
get_disk_selection() {
    info "Detecting available disks..."
    local disks=()
    local labels=()

    while IFS= read -r line; do
        line="${line% disk}"
        local name size model
        name=$(awk '{print $1}' <<< "$line")
        size=$(awk '{print $2}' <<< "$line")
        model=$(cut -d' ' -f3- <<< "$line")
        if [[ -b "/dev/$name" ]]; then
            disks+=("/dev/$name")
            labels+=("$name ($size) - $model")
        fi
    done < <(lsblk -dn -o NAME,SIZE,MODEL,TYPE | grep 'disk$')

    if [[ ${#disks[@]} -eq 0 ]]; then
        fatal "No suitable disks found"
    fi

    local selection
    selection=$(select_from_menu "Available disks:" "${labels[@]}")
    local index
    for i in "${!labels[@]}"; do
        if [[ "${labels[i]}" == "$selection" ]]; then
            index="$i"
            break
        fi
    done
    DISK="${disks[$index]}"
    info "Selected disk: $DISK (${labels[$index]})"
    validate_disk "$DISK"

    yes_no_prompt "WARNING: All data on $DISK will be destroyed. Continue?" || fatal "Installation cancelled by user"
}


Only edit below this line, what can be replaced by the above?
──────────────────────────────────
DEVICE=""
CHOICE=""
PARTITIONS=()
KEYS_MNT=$(mktemp -d)

# ─────────────────── Helpers ─────────────────── #
list_and_store_PARTITIONS() {
    log INFO "Detecting available PARTITIONS..."

    # Reset PARTITIONS=()
    PARTITIONS=()
    local index=1

    while read -r line; do
        # Parse using eval
        eval "$line"

        # Check if it's an unmounted partition
        if [[ "$TYPE" == "part" && -z "$MOUNTPOINT" ]]; then
            local dev="/dev/$NAME"
            PARTITIONS+=("$dev")

            local mount_status="UNMOUNTED"

            printf "%d) %-10s Size: %-6s FS: %-6s Mounted: %-12s Removable: %s\n" \
                "$index" "$dev" "$SIZE" "$FSTYPE" "$mount_status" "$RM"

            ((index++))
        fi
    done < <(lsblk -P -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT,RM)
}

# ─────────────────── Functions ─────────────────── #
existing_keys() {
    for key_file in "${KEY_FILES[@]}"; do
        if [[ ! -f "$KEY_DIR/$key_file" ]]; then
            log INFO "$KEY_DIR/$key_file not found."
            return 1
        fi
    done
    log info "Keys already found."
    return 0
}

make_choice() {
    while true; do
        list_and_store_PARTITIONS

        if [[ ${#PARTITIONS[@]} -gt 0 ]]; then
            break  # Partitions found, exit loop
        fi

        echo "No partitions detected. Please insert your device and press Enter to retry..."
        read -r  # Wait for user to press Enter
    done

    printf "Select partition where keys can be located in the base directory: "
    read -r CHOICE
}

validate_choice() {
    # Validate that 'CHOICE' is a positive integer and within the valid range of PARTITIONS array
    if [[ ! "$CHOICE" =~ ^[0-9]+$ ]]; then
        # Check if 'CHOICE' is not a valid number (contains non-digits)
        log ERROR "Invalid selection: '$CHOICE' is not a valid number"
        exit 1
    elif (( CHOICE < 1 || CHOICE > ${#PARTITIONS[@]} )); then
        # Check if 'CHOICE' is outside the valid range (less than 1 or greater than the number of partitions)
        log ERROR "Invalid selection: '$CHOICE' is out of range (1 to ${#PARTITIONS[@]})"
        exit 1
    fi
    DEVICE="${PARTITIONS[CHOICE-1]}"
}

validate_partition() {
    # check if zero "-z" or not a block device
    if [[ -z "$DEVICE" || ! -b "$DEVICE" ]]; then
        log ERROR "Invalid or missing DEVICE: $DEVICE"
        exit 1
    fi
}

mount_CHOICE() {
    sudo mkdir -p "$KEYS_MNT"
    sudo mount "$DEVICE" "$KEYS_MNT"
    log INFO "Mounted $DEVICE to $KEYS_MNT"
}