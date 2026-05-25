#!/bin/bash
# lib/installer.sh — Установка zapret и зависимостей

source "$(dirname "$0")/../config/paths.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/ui.sh"
source "$(dirname "$0")/os.sh"

install_dependencies() {
    check_root || return 1

    local deps=(
        "bash" "curl" "wget" "ca-certificates" "grep" "sed" "gawk"
        "coreutils" "iproute2" "dnsutils" "unzip" "jq"
    )

    print_info "Обновляем список пакетов..."
    if ! apt-get update &>/dev/null; then
        log_error "Не удалось обновить список пакетов"
        return 1
    fi

    print_info "Устанавливаем зависимости..."
    if ! apt-get install -y "${deps[@]}" &>/dev/null; then
        log_error "Не удалось установить зависимости"
        return 1
    fi

    print_success "Зависимости установлены"
    return 0
}

check_zapret_installed() {
    systemctl list-unit-files 2>/dev/null | grep -q "^zapret"
}

get_latest_zapret_version() {
    local version
    version=$(curl -s "https://api.github.com/repos/remittor/zapret/releases/latest" 2>/dev/null | jq -r '.tag_name' 2>/dev/null | sed 's/^v//')

    if [ -z "$version" ] || [ "$version" = "null" ]; then
        version="0.20.12"
    fi

    echo "$version"
}

install_or_update_zapret() {
    local version="$1"

    check_root || return 1

    if [ -z "$version" ]; then
        print_error "Версия zapret не указана"
        return 1
    fi

    print_info "Проверяем zapret v$version на GitHub..."

    # URL для скачивания из правильного репозитория remittor/zapret
    local download_url="https://github.com/remittor/zapret/releases/download/v${version}/zapret-linux-amd64.tar.gz"

    # Проверяем, что /opt существует
    if [ ! -d /opt ]; then
        mkdir -p /opt || return 1
    fi

    print_info "Скачиваем zapret v$version..."
    local tmp_file="/tmp/zapret_$version.tar.gz"

    if ! curl -fsSL -o "$tmp_file" "$download_url" 2>/dev/null; then
        log_error "Не удалось скачать zapret v$version"
        log_error "Проверьте интернет-соединение или номер версии"
        rm -f "$tmp_file"
        return 1
    fi

    # Проверяем размер файла
    if [ ! -f "$tmp_file" ] || [ ! -s "$tmp_file" ]; then
        log_error "Скачанный файл пуст или повреждён"
        rm -f "$tmp_file"
        return 1
    fi

    print_info "Распаковываем zapret..."
    if ! tar -xzf "$tmp_file" -C /opt/ 2>/dev/null; then
        log_error "Не удалось распаковать zapret"
        rm -f "$tmp_file"
        return 1
    fi

    rm -f "$tmp_file"

    # Проверяем успешность установки
    if [ ! -d /opt/zapret ]; then
        log_error "Директория /opt/zapret не создана после распаковки"
        return 1
    fi

    if [ -f /opt/zapret/init.d/zapret ]; then
        chmod +x /opt/zapret/init.d/zapret
    fi

    print_success "zapret v$version успешно установлен в /opt/zapret/"
    log_info "Установлен zapret v$version"
    return 0
}
