#######################################
# Global configuration and constants
#######################################
readonly SCRIPT_NAME="archinstall"
readonly LOG_FILE="/tmp/${SCRIPT_NAME}.log"
readonly MOUNT_POINT="/mnt"
readonly FILESYSTEM_TYPE="btrfs"
readonly USERNAME="nick"
readonly HOSTNAME="arch"
readonly SWAP_SIZE="28G"
readonly EFI_SIZE="512M"
readonly LOCALE="en_US.UTF-8"
readonly DEFAULT_TIMEZONE="America/Eastern"
readonly EDITOR_CHOICE="nvim"
KEY_DIR="$MOUNT_POINT/.ssh"
KEY_FILES=(
    "my-private-key.asc"
    "id_ed25519"
    "my-public-key.asc"
    "id_ed25519.pub"
)

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Runtime variables (initially empty)
DISK=""
ROOT_PASSWORD=""
USER_PASSWORD=""
SWAP_PARTITION=""
TIMEZONE=""
BTRFS_MOUNT_OPTIONS="compress=zstd,noatime"
