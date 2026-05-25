#!/bin/bash
# lib/service.sh — Управление zapret сервисом

source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/ui.sh"

zml_start_zapret() {
    print_info "Запускаем zapret2..."
    if systemctl start zapret2; then
        log_info "zapret2 запущен"
        print_success "zapret2 запущен"
        return 0
    else
        log_error "Не удалось запустить zapret2"
        return 1
    fi
}

zml_stop_zapret() {
    print_info "Останавливаем zapret2..."
    if systemctl stop zapret2; then
        log_info "zapret2 остановлен"
        print_success "zapret2 остановлен"
        return 0
    else
        log_error "Не удалось остановить zapret2"
        return 1
    fi
}

zml_restart_zapret() {
    print_info "Перезапускаем zapret2..."
    if systemctl restart zapret2; then
        log_info "zapret2 перезапущен"
        print_success "zapret2 перезапущен"
        sleep 1
        return 0
    else
        log_error "Не удалось перезапустить zapret2"
        return 1
    fi
}

zml_status_zapret() {
    if systemctl is-active --quiet zapret2; then
        echo "active"
        return 0
    else
        echo "inactive"
        return 1
    fi
}

zml_is_zapret_installed() {
    # Проверяем несколькими способами

    # Способ 1: Файл сервиса существует
    if [ -f /etc/systemd/system/zapret2.service ]; then
        return 0
    fi

    # Способ 2: systemctl может найти сервис
    if systemctl show zapret2.service &>/dev/null 2>&1; then
        return 0
    fi

    # Способ 3: list-unit-files содержит zapret2
    if systemctl list-unit-files 2>/dev/null | grep -q "zapret2"; then
        return 0
    fi

    return 1
}

zml_zapret_status_display() {
    if ! zml_is_zapret_installed; then
        echo "not installed"
        return 1
    fi
    zml_status_zapret
}
