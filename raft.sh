disk_setup() {
    mkdir -p /mnt
    sgdisk -Z ${DISK} # zap all on disk
    sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

    # create partitions
    sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # partition 1 (BIOS Boot Partition)
    sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # partition 2 (UEFI Boot Partition)
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # partition 3 (Root), default start, remaining
    if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
        sgdisk -A 1:set:2 ${DISK}
    fi
    partprobe ${DISK} # reread partition table to ensure it is correct
}
# make filesystems
echo -ne "
-------------------------------------------------------------------------
                    Creating Filesystems
-------------------------------------------------------------------------
"
# @description Creates the btrfs subvolumes. 
createsubvolumes () {
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@var
}

# @description Mount all btrfs subvolumes after root has been mounted.
mountallsubvol () {
    mount -o ${MOUNT_OPTIONS},subvol=@home ${partition3} /mnt/home
    mount -o ${MOUNT_OPTIONS},subvol=@var ${partition3} /mnt/var
}

# @description BTRFS subvolulme creation and mounting. 
subvolumesetup () {
    createsubvolumes     
# unmount root to remount with subvolume 
    umount /mnt
# mount @ subvolume
    mount -o ${MOUNT_OPTIONS},subvol=@ ${partition3} /mnt
# make directories home, .snapshots, var, tmp
    mkdir -p /mnt/{home,var,tmp,.snapshots}
# mount subvolumes
    mountallsubvol
}

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
subvolumesetup


# mount target
mkdir -p /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/
#____________________________________________________-

do_the_disk() {
  mkdir -p /mnt
  # Wipe and partition disk.
  wipefs -af "$DISK" &>/dev/null
  sgdisk -Z "$DISK" &>/dev/null
  sgdisk -n 1:0:+${EFI_SIZE} -t 1:ef00 -n 2:0:0 -t 2:8300 "$DISK" &>/dev/null
  partprobe "$DISK"
  sleep 3

  # Format partitions.
  prefix=$( [[ "$DISK" =~ (nvme|mmcblk|loop) ]] && echo "${DISK}p" || echo "$DISK" )
  mkfs.fat -F 32 "${prefix}1" &>/dev/null
  mkfs.btrfs -f "${prefix}2" &>/dev/null

  # Mount filesystems and create BTRFS subvolumes.
  mount "${prefix}2" /mnt
  btrfs subvolume create /mnt/@root &>/dev/null
  btrfs subvolume create /mnt/@home &>/dev/null
  umount /mnt
  mount -o subvol=@root,compress=zstd,noatime "${prefix}2" /mnt
  mkdir -p /mnt/home /mnt/boot
  mount -o subvol=@home,compress=zstd,noatime "${prefix}2" /mnt/home
  mount "${prefix}1" /mnt/boot
}
#________________________________________________-
setup_btrfs_filesystem () {
    local disk=$1
    local mount_options=$2  # Assumes MOUNT_OPTIONS is passed as a parameter

    # Determine partition names based on disk type (NVMe or not)
    local partition2
    local partition3
    if [[ "${disk}" =~ "nvme" ]]; then
        partition2="${disk}p2"
        partition3="${disk}p3"
    else
        partition2="${disk}2"
        partition3="${disk}3"
    fi

    # Create filesystems
    mkfs.vfat -F32 -n "EFIBOOT" "${partition2}"
    mkfs.btrfs -L ROOT "${partition3}" -f

    # Mount root partition temporarily to create subvolumes
    mount -t btrfs "${partition3}" /mnt

    # Create BTRFS subvolumes
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@var/log
    btrfs subvolume create /mnt/@var/cache/pacman/pkg

    # Unmount root to remount with subvolume
    umount /mnt

    # Mount @ subvolume
    mount -o "${mount_options},subvol=@" "${partition3}" /mnt

    # Create mount point directories
    mkdir -p /mnt/{home,var,tmp,.snapshots}
    mkdir -p /mnt/var/{log,cache/pacman/pkg}

    # Mount other subvolumes
    mount -o "${mount_options},subvol=@home" "${partition3}" /mnt/home
    mount -o "${mount_options},subvol=@var" "${partition3}" /mnt/var
    mount -o "${mount_options},subvol=@var/log" "${partition3}" /mnt/var/log
    mount -o "${mount_options},subvol=@var/cache/pacman/pkg" "${partition3}" /mnt/var/cache/pacman/pkg
}