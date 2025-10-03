readonly LOG_FILE="/tmp/noah.log"

readonly USERNAME="nick"
readonly HOSTNAME="arch"
readonly EFI_SIZE="512M"
readonly TIMEZONE="US/Eastern"
readonly LOCALE="en_US.UTF-8"
readonly HOME_MNT="mnt/home/$USERNAME"
KEY_DIR="$HOME_MNT/.ssh"
MOUNT_OPTIONS="noatime,compress=zstd,ssd,commit=120"
KEY_FILES=(
  "my-private-key.asc"
  "id_ed25519"
  "my-public-key.asc"
  "id_ed25519.pub"
)
