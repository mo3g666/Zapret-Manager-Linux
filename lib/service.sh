#!/bin/bash
# lib/service.sh — Управление zapret сервисом

source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/ui.sh"

zml_start_zapret() {
    print_info "Запускаем zapret..."
    if systemctl start zapret; then
        log_info "zapret запущен"
        print_success "zapret запущен"
        return 0
    else
        log_error "Не удалось запустить zapret"
        return 1
    fi
}

zml_stop_zapret() {
    print_info "Останавливаем zapret..."
    if systemctl stop zapret; then
        log_info "zapret остановлен"
        print_success "zapret остановлен"
        return 0
    else
        log_error "Не удалось остановить zapret"
        return 1
    fi
}

zml_restart_zapret() {
    print_info "Перезапускаем zapret..."
    if systemctl restart zapret; then
        log_info "zapret перезапущен"
        print_success "zapret перезапущен"
        sleep 1
        return 0
    else
        log_error "Не удалось перезапустить zapret"
        return 1
    fi
}

zml_status_zapret() {
    if systemctl is-active --quiet zapret; then
        echo "active"
        return 0
    else
        echo "inactive"
        return 1
    fi
}

zml_is_zapret_installed() {
    systemctl list-unit-files | grep -q "^zapret" 2>/dev/null
    return $?
}

zml_zapret_status_display() {
    if ! zml_is_zapret_installed; then
        echo "not installed"
        return 1
    fi
    zml_status_zapret
}
