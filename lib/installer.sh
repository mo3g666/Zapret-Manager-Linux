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

    log_info "=== Начало установки зависимостей ==="
    print_info "Обновляем список пакетов..."
    log_info "Выполняю: apt-get update"

    if ! apt-get update &>/dev/null; then
        log_error "Ошибка: apt-get update не удалось выполнить"
        return 1
    fi

    print_info "Устанавливаем зависимости: ${deps[*]}"
    log_info "Установка зависимостей: ${deps[*]}"

    if ! apt-get install -y "${deps[@]}" &>/dev/null; then
        log_error "Ошибка: не удалось установить зависимости"
        return 1
    fi

    print_success "Зависимости установлены"
    log_info "Зависимости успешно установлены"
    log_info "=== Конец установки зависимостей ==="
    return 0
}

check_zapret_installed() {
    systemctl list-unit-files 2>/dev/null | grep -q "^zapret"
}

get_latest_zapret_version() {
    local version

    log_info "Получаю последнюю версию zapret из GitHub API..."

    version=$(curl -s "https://api.github.com/repos/remittor/zapret/releases/latest" 2>/dev/null | jq -r '.tag_name' 2>/dev/null | sed 's/^v//')

    if [ -z "$version" ] || [ "$version" = "null" ]; then
        log_warn "Не удалось получить версию из GitHub, используется по умолчанию: 0.20.12"
        version="0.20.12"
    fi

    log_info "Определена версия zapret: $version"
    echo "$version"
}

install_or_update_zapret() {
    local version="$1"

    check_root || {
        log_error "Ошибка: установка требует прав root"
        return 1
    }

    if [ -z "$version" ]; then
        log_error "Ошибка: версия zapret не указана"
        print_error "Версия zapret не указана"
        return 1
    fi

    log_info "=== Начало установки zapret v$version ==="
    print_info "Проверяем zapret v$version на GitHub..."

    # URL для скачивания из правильного репозитория remittor/zapret
    local download_url="https://github.com/remittor/zapret/releases/download/v${version}/zapret-linux-amd64.tar.gz"
    log_info "URL скачивания: $download_url"

    # Проверяем, что /opt существует
    if [ ! -d /opt ]; then
        log_info "Создание директории /opt"
        mkdir -p /opt || {
            log_error "Ошибка: не удалось создать /opt"
            return 1
        }
    fi

    print_info "Скачиваем zapret v$version..."
    local tmp_file="/tmp/zapret_$version.tar.gz"
    log_info "Скачивание в: $tmp_file"

    if ! curl -fsSL -o "$tmp_file" "$download_url" 2>/dev/null; then
        log_error "Ошибка: не удалось скачать zapret v$version с URL: $download_url"
        log_error "Проверьте: интернет-соединение, номер версии, доступность GitHub"
        print_error "Не удалось скачать zapret v$version"
        rm -f "$tmp_file"
        log_info "=== Конец установки zapret (ОШИБКА) ==="
        return 1
    fi

    log_info "Загрузка завершена"

    # Проверяем размер файла
    local file_size
    file_size=$(stat -f%z "$tmp_file" 2>/dev/null || stat -c%s "$tmp_file" 2>/dev/null)
    log_info "Размер скачанного файла: $file_size байт"

    if [ ! -f "$tmp_file" ] || [ ! -s "$tmp_file" ]; then
        log_error "Ошибка: скачанный файл пуст или повреждён"
        print_error "Скачанный файл пуст или повреждён"
        rm -f "$tmp_file"
        log_info "=== Конец установки zapret (ОШИБКА) ==="
        return 1
    fi

    print_info "Распаковываем zapret..."
    log_info "Распаковка в /opt"

    if ! tar -xzf "$tmp_file" -C /opt/ 2>&1 | while read -r line; do log_info "tar: $line"; done; then
        log_error "Ошибка: не удалось распаковать zapret"
        print_error "Не удалось распаковать zapret"
        rm -f "$tmp_file"
        log_info "=== Конец установки zapret (ОШИБКА) ==="
        return 1
    fi

    rm -f "$tmp_file"
    log_info "Временный файл удалён"

    # Проверяем успешность установки
    if [ ! -d /opt/zapret ]; then
        log_error "Ошибка: директория /opt/zapret не создана после распаковки"
        print_error "Директория /opt/zapret не создана"
        log_info "=== Конец установки zapret (ОШИБКА) ==="
        return 1
    fi

    log_info "Директория /opt/zapret найдена"

    # Выставляем права на исполнение
    if [ -f /opt/zapret/init.d/zapret ]; then
        chmod +x /opt/zapret/init.d/zapret
        log_info "Прав доступа выставлены на /opt/zapret/init.d/zapret"
    fi

    # Проверяем основные файлы
    if [ ! -f /opt/zapret/nfqws ]; then
        log_warn "Внимание: /opt/zapret/nfqws не найден"
    fi

    log_info "Список файлов в /opt/zapret:"
    ls -la /opt/zapret/ 2>&1 | while read -r line; do log_info "ls: $line"; done

    print_success "zapret v$version успешно установлен в /opt/zapret/"
    log_info "zapret v$version успешно установлен в /opt/zapret/"
    log_info "=== Конец установки zapret (УСПЕХ) ==="
    return 0
}

show_install_log() {
    if [ ! -f "$LOG_FILE" ]; then
        print_error "Лог-файл не найден: $LOG_FILE"
        return 1
    fi

    print_header "Логи zapret-manager"
    echo ""
    echo "Последние 50 строк логов:"
    echo "────────────────────────────────────────────────────────────"
    tail -50 "$LOG_FILE"
    echo "────────────────────────────────────────────────────────────"
    echo ""
    print_info "Полный путь к лог-файлу: $LOG_FILE"
}

show_install_log_filtered() {
    local pattern="$1"

    if [ ! -f "$LOG_FILE" ]; then
        print_error "Лог-файл не найден: $LOG_FILE"
        return 1
    fi

    print_header "Логи установки zapret (по запросу: $pattern)"
    echo ""
    grep "$pattern" "$LOG_FILE" || print_info "Совпадений не найдено"
    echo ""
}
