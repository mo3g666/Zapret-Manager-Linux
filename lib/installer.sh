#!/bin/bash
# lib/installer.sh — Установка zapret и зависимостей

source "$(dirname "$0")/../config/paths.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/ui.sh"

install_dependencies() {
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

install_or_update_zapret() {
    local version="$1"

    if [ -z "$version" ]; then
        print_error "Версия zapret не указана"
        return 1
    fi

    print_info "Проверяем zapret на GitHub..."

    local download_url="https://github.com/remittor/zapret-openwrt/releases/download/v${version}/zapret_v${version}_linux-amd64.tar.gz"

    if ! curl -sL -I "$download_url" 2>/dev/null | grep -q "200 OK"; then
        log_error "Версия $version не найдена"
        return 1
    fi

    print_info "Скачиваем zapret v$version..."
    local tmp_file="/tmp/zapret_$version.tar.gz"

    if ! curl -sL -o "$tmp_file" "$download_url"; then
        log_error "Не удалось скачать zapret"
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

    if [ -f /opt/zapret/init.d/zapret ]; then
        chmod +x /opt/zapret/init.d/zapret
    fi

    print_success "zapret v$version установлен"
    log_info "Установлен zapret v$version"
    return 0
}

get_latest_zapret_version() {
    local version
    version=$(curl -s "https://api.github.com/repos/remittor/zapret-openwrt/releases/latest" 2>/dev/null | grep '"tag_name"' | head -1 | cut -d'"' -f4 | sed 's/v//')

    if [ -z "$version" ]; then
        version="0.20.12"
    fi

    echo "$version"
}
