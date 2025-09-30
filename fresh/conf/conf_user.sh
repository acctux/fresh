#######################################
# Global configuration and constants
#######################################
readonly SCRIPT_NAME="fresh_arch"
readonly LOG_FILE="/tmp/${SCRIPT_NAME}.log"
readonly COUNTRY_NAME='United States'
readonly COUNTRY_CODE="US"
readonly MOUNT_POINT="/mnt"
readonly USERNAME="nick"
readonly HOSTNAME="arch"
readonly SWAP_SIZE="2G"
readonly EFI_SIZE="512M"
readonly LOCALE="en_US.UTF-8"
readonly MOUNT_USER="$MOUNT_POINT/home/$USERNAME"
readonly DEFAULT_TIMEZONE="America/Eastern"

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
