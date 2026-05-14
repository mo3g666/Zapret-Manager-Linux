#!/bin/bash
# lib/os.sh — Проверка ОС и зависимостей

source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/ui.sh"

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Этот скрипт должен быть запущен от root"
        log_error "Попытка запуска не от root"
        return 1
    fi
    return 0
}

check_os() {
    local os_id="" os_version=""

    if [ -f /etc/os-release ]; then
        source /etc/os-release
        os_id="$ID"
        os_version="$VERSION_ID"
    else
        log_error "Не удалось определить ОС"
        return 1
    fi

    case "$os_id" in
        debian)
            if [[ $(echo "$os_version" | cut -d. -f1) -lt 11 ]]; then
                log_error "Требуется Debian 11 или выше"
                return 1
            fi
            ;;
        ubuntu)
            if [[ $(echo "$os_version" | cut -d. -f1) -lt 20 ]]; then
                log_error "Требуется Ubuntu 20.04 или выше"
                return 1
            fi
            ;;
        *)
            log_error "Поддерживаются только Debian и Ubuntu"
            return 1
            ;;
    esac

    print_success "ОС: $os_id $os_version (поддерживается)"
    return 0
}

check_dependencies() {
    local deps=("bash" "curl" "apt" "systemctl" "sed" "grep" "jq")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Отсутствуют зависимости: ${missing[*]}"
        return 1
    fi

    print_success "Все зависимости установлены"
    return 0
}
