#!/bin/bash

# Define the PACMAN array (as provided)
source "$(dirname "$0")/conf/conf-pac.sh"

# Create a clean, sorted list
#!/bin/bash

packages_to_json() {
    # Create a clean, sorted list and convert to JSON array
    packages_json=$(printf '%s\n' "${PACMAN[@]}" | grep -v '^#' | grep -v '^$' | sort | jq -R . | jq -s .)
    # Update the packages array in fresh.json
    jq ".packages = $packages_json" fresh_setup.json > tmp.json

    echo "Updated fresh.json with new packages array"
}
disk_identify() {
    for disk in /dev/nvme*n[0-1]; do
        if lsblk -f "$disk" | grep -q "FAT32"; then
            # Update the JSON file directly with the found disk
            jq ".disk_config.device_modifications[0].device = \"$disk\"" tmp.json > fresh.json
            echo "Updated fresh.json with device: $disk"
            exit 0
        fi
    done
    echo "No NVMe drive with FAT32 partition found"
    exit 1
}

create_proper_json() {
    packages_to_json
    disk_identify
    archinstall --config "fresh.json" --creds "fresh_user.json"
}
create_proper_json
