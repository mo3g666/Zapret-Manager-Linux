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

    version=$(curl -s "https://api.github.com/repos/bol-van/zapret2/releases/latest" 2>/dev/null | jq -r '.tag_name' 2>/dev/null | sed 's/^v//')

    if [ -z "$version" ] || [ "$version" = "null" ]; then
        version="0.9.5.2"
    fi

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

    log_info "Получаю последнюю версию zapret2 из GitHub API..."
    log_info "Определена версия zapret: $version"
    log_info "=== Начало установки zapret v$version ==="
    print_info "Проверяем zapret v$version на GitHub..."

    # URL для скачивания из правильного репозитория bol-van/zapret2
    local download_url="https://github.com/bol-van/zapret2/releases/download/v${version}/zapret2-v${version}.tar.gz"
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
    local tmp_file="/tmp/zapret2_$version.tar.gz"
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

    if ! tar -xzf "$tmp_file" -C /opt/ 2>&1; then
        log_error "Ошибка: не удалось распаковать zapret"
        print_error "Не удалось распаковать zapret"
        rm -f "$tmp_file"
        log_info "=== Конец установки zapret (ОШИБКА) ==="
        return 1
    fi

    rm -f "$tmp_file"
    log_info "Временный файл удалён"

    # Переименовываем директорию zapret2-v* в zapret2
    log_info "Ищу распакованную директорию zapret2-v*"
    local extracted_dir
    extracted_dir=$(find /opt -maxdepth 1 -name "zapret2-v*" -type d 2>/dev/null | head -1)

    if [ -n "$extracted_dir" ] && [ -d "$extracted_dir" ]; then
        log_info "Найдена директория: $extracted_dir"
        log_info "Переименование в /opt/zapret2"
        rm -rf /opt/zapret2 2>/dev/null
        if ! mv "$extracted_dir" /opt/zapret2; then
            log_error "Ошибка: не удалось переименовать директорию"
            print_error "Не удалось переименовать директорию"
            log_info "=== Конец установки zapret (ОШИБКА) ==="
            return 1
        fi
        log_info "Директория успешно переименована в /opt/zapret2"
    else
        log_error "Ошибка: распакованная директория zapret2-v* не найдена в /opt"
        print_error "Распакованная директория не найдена"
        log_info "=== Конец установки zapret (ОШИБКА) ==="
        return 1
    fi

    # Проверяем успешность установки
    if [ ! -d /opt/zapret2 ]; then
        log_error "Ошибка: директория /opt/zapret2 не создана после распаковки"
        print_error "Директория /opt/zapret2 не создана"
        log_info "=== Конец установки zapret (ОШИБКА) ==="
        return 1
    fi

    log_info "Директория /opt/zapret2 найдена"

    # Инициализируем zapret2 конфигурацию
    log_info "Инициализация конфигурации zapret2"
    print_info "Настройка zapret2..."

    # Создаём config из config.default если не существует
    if [ ! -f /opt/zapret2/config ]; then
        if [ -f /opt/zapret2/config.default ]; then
            cp /opt/zapret2/config.default /opt/zapret2/config
            log_info "Config создан из config.default"
        else
            log_error "Ошибка: config.default не найден"
            print_error "Ошибка инициализации zapret2"
            log_info "=== Конец установки zapret (ОШИБКА) ==="
            return 1
        fi
    fi

    # Создаём необходимые директории
    mkdir -p /opt/zapret2/ipset /opt/zapret2/init.d/sysv/custom.d /opt/zapret2/tmp 2>/dev/null
    log_info "Директории созданы"

    # Создаём необходимые файлы user lists если не существуют
    [ -f /opt/zapret2/ipset/zapret-hosts-user-exclude.txt ] || \
        cp /opt/zapret2/ipset/zapret-hosts-user-exclude.txt.default /opt/zapret2/ipset/zapret-hosts-user-exclude.txt 2>/dev/null
    [ -f /opt/zapret2/ipset/zapret-hosts-user.txt ] || \
        echo "nonexistent.domain" > /opt/zapret2/ipset/zapret-hosts-user.txt
    [ -f /opt/zapret2/ipset/zapret-hosts-user-ipban.txt ] || \
        touch /opt/zapret2/ipset/zapret-hosts-user-ipban.txt

    log_info "User files инициализированы"

    # Выставляем права на исполнение для скриптов
    find /opt/zapret2 -type f -name "*.sh" -exec chmod +x {} \;
    find /opt/zapret2/binaries -type f -exec chmod +x {} \;
    chmod +x /opt/zapret2/init.d/sysv/zapret2 2>/dev/null
    log_info "Права на исполнение выставлены"

    # Устанавливаем systemd сервис
    log_info "Установка systemd сервиса"

    # Копируем оригинальный systemd файл из архива
    if [ -f /opt/zapret2/init.d/systemd/zapret2.service ]; then
        cp /opt/zapret2/init.d/systemd/zapret2.service /etc/systemd/system/zapret2.service
        chmod 644 /etc/systemd/system/zapret2.service
        log_info "Systemd файл zapret2.service установлен из архива"
    else
        log_warn "Внимание: systemd файл zapret2.service не найден в архиве"
    fi

    # Перезагружаем systemd
    if ! systemctl daemon-reload 2>/dev/null; then
        log_error "Ошибка: не удалось перезагрузить systemd"
    fi

    # Включаем сервис
    if ! systemctl enable zapret2 2>/dev/null; then
        log_warn "Не удалось включить сервис zapret2 в автозагрузку"
    fi

    log_info "Systemd сервис zapret2 установлен"

    print_success "zapret v$version успешно установлен в /opt/zapret2/"
    log_info "zapret v$version успешно установлен в /opt/zapret2/"
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
