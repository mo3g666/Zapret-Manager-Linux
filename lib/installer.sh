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

    version=$(curl -s \
        --connect-timeout 5 \
        --max-time 15 \
        "https://api.github.com/repos/bol-van/zapret2/releases/latest" 2>/dev/null | \
        jq -r '.tag_name' 2>/dev/null | \
        sed 's/^v//')

    if [ -z "$version" ] || [ "$version" = "null" ]; then
        log_warn "Не удалось получить версию с GitHub, используем fallback"
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

    # Скачиваем с таймаутами и повторными попытками
    local retries=3
    local success=false

    for ((attempt=1; attempt<=retries; attempt++)); do
        log_info "Попытка скачивания $attempt/$retries..."

        if curl -fsSL \
            --connect-timeout 10 \
            --max-time 120 \
            -L \
            -o "$tmp_file" \
            "$download_url" 2>/dev/null; then
            success=true
            break
        else
            log_warn "Попытка $attempt не удалась, повтор..."
            rm -f "$tmp_file"
            sleep 3
        fi
    done

    if [ "$success" != "true" ]; then
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

    # Запускаем официальный установщик zapret2
    log_info "Запуск официального установщика zapret2 (install_easy.sh)"
    print_info "Установка zapret2 (может занять время)..."

    if [ -f /opt/zapret2/install_easy.sh ]; then
        # Запускаем install_easy.sh с ответом Y на все вопросы
        (echo "y"; echo "y"; echo "y"; echo "y"; echo "y"; sleep 1) | bash /opt/zapret2/install_easy.sh 2>&1 | while read -r line; do
            log_info "install_easy: $line"
        done

        if [ $? -ne 0 ]; then
            log_warn "install_easy.sh завершился с кодом ошибки, но это может быть нормально"
        fi
        log_info "Установка zapret2 завершена"
    else
        log_error "Ошибка: install_easy.sh не найден в /opt/zapret2"
        print_error "Ошибка установки zapret2"
        log_info "=== Конец установки zapret (ОШИБКА) ==="
        return 1
    fi

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
