#!/bin/bash
# lib/backup.sh — Backup и restore операции

source "$(dirname "$0")/../config/paths.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/ui.sh"

ensure_backup_dir() {
    if [ ! -d "$ZML_BACKUP_DIR" ]; then
        mkdir -p "$ZML_BACKUP_DIR" || return 1
    fi
}

get_timestamp() {
    date '+%Y%m%d-%H%M%S'
}

backup_hosts() {
    local timestamp=$(get_timestamp)
    local backup_file="$ZML_BACKUP_DIR/hosts.$timestamp"

    ensure_backup_dir || return 1
    cp "$HOSTS_FILE" "$backup_file" || return 1

    log_info "Backup hosts: $backup_file"
    return 0
}

backup_strategy() {
    local timestamp=$(get_timestamp)
    local backup_file="$ZML_BACKUP_DIR/current.strategy.$timestamp"

    ensure_backup_dir || return 1

    if [ -f "$STRATEGY_FILE" ]; then
        cp "$STRATEGY_FILE" "$backup_file" || return 1
    fi

    log_info "Backup strategy: $backup_file"
    return 0
}

backup_meta() {
    local timestamp=$(get_timestamp)
    local backup_file="$ZML_BACKUP_DIR/current.meta.$timestamp"

    ensure_backup_dir || return 1
    cp "$META_FILE" "$backup_file" || return 1

    log_info "Backup meta: $backup_file"
    return 0
}

restore_hosts() {
    local backup_file="$1"

    if [ ! -f "$backup_file" ]; then
        log_error "Файл backup не найден: $backup_file"
        return 1
    fi

    cp "$backup_file" "$HOSTS_FILE" || return 1
    log_info "Restored hosts from: $backup_file"
    return 0
}

restore_strategy() {
    local backup_file="$1"

    if [ ! -f "$backup_file" ]; then
        log_error "Файл backup не найден: $backup_file"
        return 1
    fi

    cp "$backup_file" "$STRATEGY_FILE" || return 1
    log_info "Restored strategy from: $backup_file"
    return 0
}

list_backups() {
    ensure_backup_dir || return 1

    print_header "Доступные backup-файлы"

    local count=0
    while IFS= read -r file; do
        echo "$count) $(basename "$file")"
        ((count++))
    done < <(ls -t "$ZML_BACKUP_DIR" 2>/dev/null)

    return 0
}
