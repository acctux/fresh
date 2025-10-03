#######################################
# Logging helpers
#######################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
info() { printf "${BLUE}[INFO]${NC} %s\n" "$*" | tee -a "$LOG_FILE"; }
success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$*" | tee -a "$LOG_FILE"; }
warning() { printf "${YELLOW}[WARNING]${NC} %s\n" "$*" | tee -a "$LOG_FILE"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*" | tee -a "$LOG_FILE"; }

fatal() {
  error "$*"
  exit 1
}

error_trap() {
  local exit_code=$?
  local line="$1"
  local cmd="$2"
  error "Command '${cmd}' failed at line ${line} with exit code ${exit_code}"
  exit "$exit_code"
}

#######################################
# Pre-flight checks
#######################################
require_root() {
  if [[ "$EUID" -ne 0 ]]; then
    fatal "This script must be run as root"
  fi
}

check_dependencies() {
  local deps=(lsblk curl sgdisk partprobe pacstrap arch-chroot numfmt)
  for cmd in "${deps[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      fatal "Required command '$cmd' not found"
    fi
  done
}

yes_no_prompt() {
  # Ask a yes/no question until the user enters y or n
  local prompt="$1"
  local reply
  while true; do
    if ! read -rp "$prompt [y/n]: " reply; then
      fatal "Input aborted"
    fi
    case "$reply" in
    [Yy]) return 0 ;;
    [Nn]) return 1 ;;
    esac
    warning "Please answer 'y' or 'n'."
  done
}

get_password() {
  local prompt="$1"
  local pass confirm
  while true; do
    if ! read -rsp "$prompt: " pass; then
      fatal "Input aborted"
    fi
    echo
    ((${#pass} >= 4)) || {
      warning "Password must be at least 4 characters long"
      continue
    }
    if ! read -rsp "Confirm password: " confirm; then
      fatal "Input aborted"
    fi
    echo
    [[ "$pass" == "$confirm" ]] || {
      warning "Passwords do not match"
      continue
    }
    echo "$pass"
    return 0
  done
}

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
      printf '%d) %s\n' "$((i + 1))" "${options[i]}" >&2
    done
    if ! read -rp "Select an option (1-${num}): " choice; then
      fatal "Input aborted"
    fi
    if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= num)); then
      echo "${options[$((choice - 1))]}"
      return 0
    fi
    warning "Invalid choice. Please select a number between 1 and ${num}." >&2
  done
}

unmount_mounted() {
  info "Unmounting filesystems"
  if mountpoint -q "mnt/boot"; then
    umount "/mnt/boot" || error "Failed to unmount mnt/boot"
  fi
  for sub in home var/log var/cache/pacman/pkg; do
    if mountpoint -q "mnt/$sub"; then
      umount "/mnt/$sub" || error "Failed to unmount /mnt/$sub"
    fi
  done
  if mountpoint -q "mnt"; then
    umount "/mnt" || error "Failed to unmount mnt"
  fi
  success "Filesystems unmounted successfully"
}
