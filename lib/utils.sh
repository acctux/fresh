log() {
    local level="$1"; shift
    printf "[%s] [%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a "$LOG_FILE" >&2
}

reboot_prompt() {
    read -p "Reboot now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      log "INFO" "Rebooting system..."
      sudo reboot
    fi
}
