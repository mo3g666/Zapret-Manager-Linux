#!/bin/bash
# lib/updater.sh — Автоматическое обновление скрипта

source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/ui.sh"

REPO_URL="https://raw.githubusercontent.com/mo3g666/Zapret-Manager-Linux/main"
UPDATE_CHECK_FILE="/tmp/zml_update_check"
UPDATE_CHECK_INTERVAL=86400  # 24 часа в секундах

check_for_updates() {
    # Не проверяем часто (максимум раз в 24 часа)
    if [ -f "$UPDATE_CHECK_FILE" ]; then
        local last_check=$(stat -f%m "$UPDATE_CHECK_FILE" 2>/dev/null || stat -c%Y "$UPDATE_CHECK_FILE" 2>/dev/null)
        local now=$(date +%s)
        if [ $((now - last_check)) -lt $UPDATE_CHECK_INTERVAL ]; then
            return 0
        fi
    fi

    # Проверяем только если есть интернет (быстро и тихо)
    if ! curl -s --connect-timeout 2 -m 3 https://api.github.com/repos/mo3g666/Zapret-Manager-Linux/releases/latest &>/dev/null; then
        return 0
    fi

    # Запускаем проверку в фоне
    (
        local remote_version
        remote_version=$(curl -s "$REPO_URL/config/defaults.sh" 2>/dev/null | grep "ZAPRET_MANAGER_VERSION=" | cut -d'"' -f2)

        if [ -z "$remote_version" ]; then
            return 0
        fi

        # Сравниваем версии
        if [ "$remote_version" != "$ZAPRET_MANAGER_VERSION" ]; then
            log_info "Найдена новая версия: $remote_version (текущая: $ZAPRET_MANAGER_VERSION)"
            # Сохраняем информацию об обновлении
            echo "$remote_version" > "$UPDATE_CHECK_FILE.new_version"
        fi

        touch "$UPDATE_CHECK_FILE"
    ) &
    disown 2>/dev/null

    return 0
}

notify_if_update_available() {
    if [ -f "$UPDATE_CHECK_FILE.new_version" ]; then
        local new_version
        new_version=$(cat "$UPDATE_CHECK_FILE.new_version")

        print_info "Доступна новая версия Zapret Manager: $new_version"
        echo ""
        print_info "Для обновления выполните:"
        echo "  curl -fsSL https://raw.githubusercontent.com/mo3g666/Zapret-Manager-Linux/main/install.sh | sudo bash"
        echo ""

        rm -f "$UPDATE_CHECK_FILE.new_version"
        return 1
    fi

    return 0
}

auto_update() {
    # Автоматическое обновление (если включено в переменной окружения)
    if [ "$ZML_AUTO_UPDATE" != "yes" ]; then
        return 0
    fi

    if [ ! -f "$UPDATE_CHECK_FILE.new_version" ]; then
        return 0
    fi

    print_info "Обновляю Zapret Manager..."

    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    # Скачиваем новую версию
    if ! curl -fsSL "${REPO_URL}/install.sh" -o "$temp_dir/install.sh"; then
        log_error "Не удалось скачать обновление"
        return 1
    fi

    # Запускаем установщик с флагом обновления
    if bash "$temp_dir/install.sh"; then
        print_success "Обновление завершено"
        log_info "Обновлен Zapret Manager"
        rm -f "$UPDATE_CHECK_FILE.new_version"
        return 0
    else
        log_error "Обновление не удалось"
        return 1
    fi
}
