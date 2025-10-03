#!/bin/bash
#
readonly LOG_FILE="/tmp/noah.log"

readonly USERNAME="nick"
readonly HOSTNAME="arch"
readonly EFI_SIZE="512M"
readonly MOUNT_POINT="/mnt"
readonly TIMEZONE="US/Eastern"
LOCALE="en_US.UTF-8"

readonly HOME_MNT="$MOUNT_POINT/home/$USERNAME"
KEY_DIR="$HOME_MNT/.ssh"
KEY_FILES=(
    "my-private-key.asc"
    "id_ed25519"
    "my-public-key.asc"
    "id_ed25519.pub"
)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
info()    { printf "${BLUE}[INFO]${NC} %s\n"    "$*" | tee -a "$LOG_FILE"; }
success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$*" | tee -a "$LOG_FILE"; }
warning() { printf "${YELLOW}[WARNING]${NC} %s\n" "$*" | tee -a "$LOG_FILE"; }
error()   { printf "${RED}[ERROR]${NC} %s\n"   "$*" | tee -a "$LOG_FILE"; }

SCRIPT_DIR="$(dirname "$0")"
PARENT_DIR="$(dirname "${SCRIPT_DIR}")"

MOUNT_OPTIONS="noatime,compress=zstd,ssd,commit=120"
source "$PARENT_DIR/utils.sh"


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

iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm archlinux-keyring # update keyrings to prevent package install failures
pacman -S --noconfirm --needed pacman-contrib

sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -ne "
-------------------------------------------------------------------------
                    Setting up $iso mirrors for faster downloads
-------------------------------------------------------------------------
"
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

echo "making mount directory"
mkdir /mnt &>/dev/null || true
echo "mount directory created"

# Disk prep
sgdisk -Z ${DISK} # Zap all on disk
sgdisk -a 2048 -o ${DISK} # New GPT disk with 2048 alignment

# Create partitions
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # BIOS Boot Partition
sgdisk -n 2::+600M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # UEFI Boot Partition
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
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@.snapshots

# Set up btrfs subvolumes and mount
umount /mnt
mount -o ${MOUNT_OPTIONS},subvol=@ ${partition3} /mnt
mkdir -p /mnt/{home,var,tmp,.snapshots}

# Mount btrfs subvolumes
mount -o ${MOUNT_OPTIONS},subvol=@home ${partition3} /mnt/home
mount -o ${MOUNT_OPTIONS},subvol=@tmp ${partition3} /mnt/tmp
mount -o ${MOUNT_OPTIONS},subvol=@var ${partition3} /mnt/var
mount -o ${MOUNT_OPTIONS},subvol=@.snapshots ${partition3} /mnt/.snapshots

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

pacstrap /mnt \
    amd-ucode \
    base \
    base-devel \
    btrfs-progs \
    linux \
    reflector \
    linux-firmware \
    neovim-lspconfig
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp -R ${SCRIPT_DIR} /mnt/root/Noah
if [[ ! -d /mnt/root/Noah ]]; then
    echo "MISTAKE!!!"
    exit 1
fi
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
