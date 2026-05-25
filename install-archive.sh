#!/bin/bash
# Zapret Manager Linux - Простой установщик через архив
# Установка из архива GitHub (без отдельного скачивания файлов)

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}[ИНФО]${NC} $*"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $*"; }
log_err() { echo -e "${RED}[ОШИБКА]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[ВНИМАНИЕ]${NC} $*"; }

main() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  Zapret Manager Linux - Установка v2                   ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Проверка root
    if [[ $EUID -ne 0 ]]; then
        log_err "Требуется root доступ (используйте sudo)"
        exit 1
    fi

    # Проверка ОС
    if ! command -v apt-get &>/dev/null; then
        log_err "Требуется Debian/Ubuntu"
        exit 1
    fi
    log_ok "ОС: Debian/Ubuntu"

    # Установка необходимых команд
    log_info "Проверка зависимостей..."
    local missing=()
    for cmd in curl unzip file; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Установка: ${missing[*]}"
        apt-get update -qq
        apt-get install -y -qq "${missing[@]}"
    fi
    log_ok "Все зависимости есть"

    # Скачиваем архив
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    local archive="$temp_dir/repo.zip"
    local url="https://github.com/mo3g666/Zapret-Manager-Linux/archive/refs/heads/main.zip"

    log_info "Скачиваю архив проекта..."
    log_info "URL: $url"

    if ! curl -fsSL \
        --connect-timeout 10 \
        --max-time 120 \
        -L \
        -o "$archive" \
        "$url"; then
        log_err "Не удалось скачать архив"
        exit 1
    fi

    if ! file "$archive" | grep -q "Zip archive"; then
        log_err "Загруженный файл не является ZIP архивом"
        log_err "Проверьте интернет-соединение и доступность GitHub"
        exit 1
    fi

    log_ok "Архив скачан"

    # Распаковываем
    log_info "Распаковка архива..."
    if ! unzip -q "$archive" -d "$temp_dir"; then
        log_err "Не удалось распаковать архив"
        exit 1
    fi

    # Находим распакованную директорию
    local src_dir
    src_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "*Zapret-Manager-Linux*" | head -1)

    if [[ ! -d "$src_dir" ]]; then
        log_err "Распакованная директория не найдена"
        exit 1
    fi

    log_ok "Архив распакован"

    # Копируем файлы
    log_info "Копирование файлов..."
    local install_dir="/opt/zapret-manager"

    mkdir -p "$install_dir"
    cp -r "$src_dir/zml.sh" "$install_dir/"
    cp -r "$src_dir/config" "$install_dir/"
    cp -r "$src_dir/lib" "$install_dir/"

    chmod 755 "$install_dir/zml.sh"
    chmod 755 "$install_dir/config"/*.sh 2>/dev/null || true
    chmod 755 "$install_dir/lib"/*.sh 2>/dev/null || true

    log_ok "Файлы установлены в $install_dir"

    # Создаём ссылки
    log_info "Создание команд..."
    ln -sf "$install_dir/zml.sh" /usr/local/bin/zml
    ln -sf "$install_dir/zml.sh" /usr/local/bin/zms

    # Инициализируем директории
    log_info "Инициализация..."
    mkdir -p /etc/zapret-manager
    mkdir -p /var/lib/zapret-manager
    mkdir -p /var/lib/zapret-manager/flowseal
    mkdir -p /var/log

    # Успех
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  Установка завершена успешно!                             ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    log_ok "Команды: zml или zms"
    echo ""
    log_info "Для начала работы выполните:"
    echo "  zml"
    echo ""
}

main "$@"
