#!/bin/bash
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
}
get_disk_selection
# iso=$(curl -4 ifconfig.co/country-iso)
# timedatectl set-ntp true
# pacman -S --noconfirm archlinux-keyring # update keyrings to prevent package install failures
# pacman -S --noconfirm --needed pacman-contrib terminus-font
# setfont ter-v22b
# sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
# pacman -S --noconfirm --needed reflector rsync grub
# cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
# echo -ne "
# -------------------------------------------------------------------------
#                     Setting up $iso mirrors for faster downloads
# -------------------------------------------------------------------------
# "
# reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
echo "making mount directory"
mkdir /mnt &>/dev/null || true
echo "mount directory created"

# Disk prep
sgdisk -Z ${DISK} # Zap all on disk
sgdisk -a 2048 -o ${DISK} # New GPT disk with 2048 alignment

# Create partitions
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # BIOS Boot Partition
sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # UEFI Boot Partition
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # Root Partition, remaining space
if [[ ! -d "/sys/firmware/efi" ]]; then # Check for BIOS system
    sgdisk -A 1:set:2 ${DISK}
fi
partprobe ${DISK} # Reread partition table

# Make filesystems
echo -ne "
-------------------------------------------------------------------------
                    Creating Filesystems
-------------------------------------------------------------------------
"
if [[ "${DISK}" =~ "nvme" ]]; then
    partition2=${DISK}p2
    partition3=${DISK}p3
else
    partition2=${DISK}2
    partition3=${DISK}3
fi

mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
mkfs.btrfs -L ROOT ${partition3} -f
mount -t btrfs ${partition3} /mnt

# Create btrfs subvolumes
createsubvolumes () {
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@tmp
    btrfs subvolume create /mnt/@.snapshots
}

# Mount btrfs subvolumes
mountallsubvol () {
    mount -o ${MOUNT_OPTIONS},subvol=@home ${partition3} /mnt/home
    mount -o ${MOUNT_OPTIONS},subvol=@tmp ${partition3} /mnt/tmp
    mount -o ${MOUNT_OPTIONS},subvol=@var ${partition3} /mnt/var
    mount -o ${MOUNT_OPTIONS},subvol=@.snapshots ${partition3} /mnt/.snapshots
}

# Set up btrfs subvolumes and mount
subvolumesetup () {
    createsubvolumes
    umount /mnt
    mount -o ${MOUNT_OPTIONS},subvol=@ ${partition3} /mnt
    mkdir -p /mnt/{home,var,tmp,.snapshots}
    mountallsubvol
}

subvolumesetup

# Mount EFI partition
mkdir -p /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/efi

# Verify mount
if ! grep -qs '/mnt' /proc/mounts; then
    echo "Drive is not mounted, cannot continue"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now
fi
echo -ne "
-------------------------------------------------------------------------
                    Arch Install on Main Drive
-------------------------------------------------------------------------
"
pacstrap /mnt base base-devel linux linux-firmware vim nano sudo archlinux-keyring wget libnewt --noconfirm --needed
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp -R ${SCRIPT_DIR} /mnt/root/ArchTitus
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

genfstab -L /mnt >> /mnt/etc/fstab
echo "
  Generated /etc/fstab:
"
cat /mnt/etc/fstab
echo -ne "
-------------------------------------------------------------------------
                    GRUB BIOS Bootloader Install & Check
-------------------------------------------------------------------------
"
if [[ ! -d "/sys/firmware/efi" ]]; then
    grub-install --boot-directory=/mnt/boot ${DISK}
else
    pacstrap /mnt efibootmgr --noconfirm --needed
fi
