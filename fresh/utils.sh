#######################################
# Logging helpers
#######################################
log() {
    printf '%(%Y-%m-%d %H:%M:%S)T - %s\n' -1 "$*" | tee -a "$LOG_FILE"
}
info()    { printf "${BLUE}[INFO]${NC} %s\n"    "$*" | tee -a "$LOG_FILE"; }
success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$*" | tee -a "$LOG_FILE"; }
warning() { printf "${YELLOW}[WARNING]${NC} %s\n" "$*" | tee -a "$LOG_FILE"; }
error()   { printf "${RED}[ERROR]${NC} %s\n"   "$*" | tee -a "$LOG_FILE"; }

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