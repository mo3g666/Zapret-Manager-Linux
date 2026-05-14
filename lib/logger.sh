#!/bin/bash
# lib/logger.sh — Функции логирования

source "$(dirname "$0")/../config/paths.sh"

log_info() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $message" | tee -a "$LOG_FILE"
}

log_warn() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] $message" | tee -a "$LOG_FILE" >&2
}

log_error() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $message" | tee -a "$LOG_FILE" >&2
    return 1
}

# Убедиться, что лог-файл создан
ensure_log_file() {
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE" 2>/dev/null || {
            echo "Не удалось создать лог-файл $LOG_FILE" >&2
            return 1
        }
    fi
}
