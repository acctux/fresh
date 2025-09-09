#!/usr/bin/env bash

# Logging utilities
log() {
    local level="$1"; shift
    local color
    case "$level" in
        INFO) color="\033[32m" ;;  # Green
        WARNING) color="\033[33m" ;;  # Yellow
        ERROR) color="\033[31m" ;;  # Red
        *) color="\033[0m" ;;  # Reset
    esac
    printf "%s[%s] [%s] %s\033[0m\n" "$color" "$(date +'%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a "$LOG_FILE" >&2
}