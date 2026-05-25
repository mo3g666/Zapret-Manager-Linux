#!/bin/bash
# Zapret Manager Linux - Скрипт установки
# Installation script for Zapret Manager on Linux (Debian/Ubuntu)

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
INSTALL_PREFIX="${INSTALL_PREFIX:-/opt/zapret-manager}"
BIN_PATH="/usr/local/bin"
ETC_DIR="/etc/zapret-manager"
VAR_DIR="/var/lib/zapret-manager"
REPO_URL="${REPO_URL:-https://raw.githubusercontent.com/mo3g666/Zapret-Manager-Linux/main}"

# Функции логирования
log_info() {
    echo -e "${CYAN}[ИНФО]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

log_error() {
    echo -e "${RED}[ОШИБКА]${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}[ВНИМАНИЕ]${NC} $*"
}

# Проверка прав root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Скрипт должен быть запущен от пользователя root"
        exit 1
    fi
}

# Проверка совместимости ОС
check_os() {
    if ! command -v apt-get &> /dev/null; then
        log_error "Требуется Debian/Ubuntu (apt-get не найден)"
        exit 1
    fi

    if [[ -f /etc/debian_version ]]; then
        log_success "Обнаружена система Debian/Ubuntu"
    else
        log_error "Неподдерживаемая ОС (требуется Debian/Ubuntu)"
        exit 1
    fi
}

# Проверка зависимостей
check_dependencies() {
    local missing=()
    for cmd in bash curl sed grep jq systemctl; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warning "Отсутствуют зависимости: ${missing[*]}"
        log_info "Установка отсутствующих зависимостей..."
        apt-get update
        apt-get install -y "${missing[@]}"
    fi
    log_success "Все зависимости установлены"
}

# Загрузка файлов из репозитория GitHub
download_file_with_retry() {
    local url="$1"
    local output="$2"
    local filename="$3"
    local retries=3
    local timeout=30

    for ((attempt=1; attempt<=retries; attempt++)); do
        log_info "Загружаю $filename (попытка $attempt/$retries)..."

        if curl -fsSL --connect-timeout 5 --max-time $timeout "$url" -o "$output" 2>/dev/null; then
            if [ -s "$output" ]; then
                log_info "✓ Загружен $filename"
                return 0
            else
                log_warning "Файл $filename пустой, повтор..."
            fi
        else
            log_warning "Ошибка загрузки $filename, повтор..."
        fi

        if [ $attempt -lt $retries ]; then
            sleep 2
        fi
    done

    log_error "Не удалось загрузить $filename после $retries попыток"
    return 1
}

download_files() {
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    log_info "Загрузка файлов из репозитория..."

    # Создание структуры временной директории
    mkdir -p "$temp_dir/config"
    mkdir -p "$temp_dir/lib"

    # Загрузка основного скрипта
    if ! download_file_with_retry "${REPO_URL}/zml.sh" "$temp_dir/zml.sh" "zml.sh"; then
        return 1
    fi
    chmod +x "$temp_dir/zml.sh"

    # Загрузка конфиг-файлов
    for file in defaults.sh domains.sh paths.sh; do
        if ! download_file_with_retry "${REPO_URL}/config/${file}" "$temp_dir/config/${file}" "config/${file}"; then
            return 1
        fi
    done

    # Загрузка файлов lib
    local lib_files=(
        "backup.sh" "discord.sh" "hosts.sh" "installer.sh"
        "logger.sh" "meta.sh" "offload_diag.sh" "os.sh"
        "service.sh" "strategies_builtin.sh" "strategies_discord.sh"
        "strategies_flowseal.sh" "strategies_game.sh" "strategies_youtube.sh"
        "tester.sh" "ui.sh" "updater.sh" "zapret_config.sh"
    )

    for file in "${lib_files[@]}"; do
        if ! download_file_with_retry "${REPO_URL}/lib/${file}" "$temp_dir/lib/${file}" "lib/${file}"; then
            return 1
        fi
    done

    log_success "Файлы загружены успешно"

    # Копирование в директорию установки
    mkdir -p "$INSTALL_PREFIX"
    cp -r "$temp_dir"/* "$INSTALL_PREFIX/"
    chmod 755 "$INSTALL_PREFIX/zml.sh"
    chmod 755 "$INSTALL_PREFIX/config"/*.sh
    chmod 755 "$INSTALL_PREFIX/lib"/*.sh

    log_success "Файлы установлены в ${INSTALL_PREFIX}"
}

# Создание символических ссылок
create_symlinks() {
    log_info "Создание символических ссылок команд..."

    # Создание ссылки zml
    if [[ -L "$BIN_PATH/zml" ]] || [[ -f "$BIN_PATH/zml" ]]; then
        rm -f "$BIN_PATH/zml"
    fi
    ln -s "$INSTALL_PREFIX/zml.sh" "$BIN_PATH/zml"
    log_success "Создана ссылка: zml -> ${INSTALL_PREFIX}/zml.sh"

    # Создание ссылки zms (как псевдоним zml)
    if [[ -L "$BIN_PATH/zms" ]] || [[ -f "$BIN_PATH/zms" ]]; then
        rm -f "$BIN_PATH/zms"
    fi
    ln -s "$INSTALL_PREFIX/zml.sh" "$BIN_PATH/zms"
    log_success "Создана ссылка: zms -> ${INSTALL_PREFIX}/zml.sh"
}

# Инициализация системных директорий
initialize_directories() {
    log_info "Инициализация системных директорий..."

    # Создание директории конфигурации
    if [[ ! -d "$ETC_DIR" ]]; then
        mkdir -p "$ETC_DIR"
        chmod 755 "$ETC_DIR"
        log_success "Создана директория конфигурации: ${ETC_DIR}"
    fi

    # Создание директории состояния
    if [[ ! -d "$VAR_DIR" ]]; then
        mkdir -p "$VAR_DIR"
        chmod 755 "$VAR_DIR"
        log_success "Создана директория состояния: ${VAR_DIR}"
    fi

    # Создание директории резервных копий
    local backup_dir="$VAR_DIR/backups"
    if [[ ! -d "$backup_dir" ]]; then
        mkdir -p "$backup_dir"
        chmod 755 "$backup_dir"
        log_success "Создана директория резервных копий: ${backup_dir}"
    fi

    # Инициализация файла метаданных
    if [[ ! -f "$ETC_DIR/current.meta" ]]; then
        cat > "$ETC_DIR/current.meta" << 'EOF'
MODE=local
MAIN_STRATEGY=v7
YOUTUBE_STRATEGY=
GAME_STRATEGY=
DISCORD_STRATEGY=
FLOWSEAL_STRATEGY=
RKN_BYPASS=0
WSSIZE_BLOCK=0
METHODEOF_BLOCK=0
DISCORD_SCRIPT=
DISCORD_FINLAND_IPS=0
HOSTS_GROUPS_ADDED=
EOF
        chmod 644 "$ETC_DIR/current.meta"
        log_success "Инициализирован файл метаданных: ${ETC_DIR}/current.meta"
    fi
}

# Проверка установки
verify_installation() {
    log_info "Проверка установки..."

    local errors=0

    # Проверка основного скрипта
    if [[ ! -f "$INSTALL_PREFIX/zml.sh" ]]; then
        log_error "zml.sh не найден"
        ((errors++))
    fi

    # Проверка символических ссылок
    if [[ ! -L "$BIN_PATH/zml" ]]; then
        log_error "Ссылка zml не создана"
        ((errors++))
    fi

    if [[ ! -L "$BIN_PATH/zms" ]]; then
        log_error "Ссылка zms не создана"
        ((errors++))
    fi

    # Проверка директорий
    if [[ ! -d "$ETC_DIR" ]]; then
        log_error "Директория конфигурации не создана"
        ((errors++))
    fi

    if [[ ! -d "$VAR_DIR" ]]; then
        log_error "Директория состояния не создана"
        ((errors++))
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "Установка проверена успешно"
        return 0
    else
        log_error "Проверка установки не прошла ($errors ошибок)"
        return 1
    fi
}

# Основной процесс установки
main() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  Zapret Manager Linux - Установка                       ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo

    log_info "Начало процесса установки..."
    log_info "Префикс установки: ${INSTALL_PREFIX}"
    echo

    check_root
    check_os
    check_dependencies
    download_files
    create_symlinks
    initialize_directories
    verify_installation

    if [[ $? -eq 0 ]]; then
        echo
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║${NC}  Установка завершена успешно!                             ${GREEN}║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo
        log_success "Теперь вы можете запустить: zml или zms"
        log_info "Для справки выполните: zml -h или zms -h"
        echo
        log_info "Расположения установки:"
        echo "  Скрипты:      ${INSTALL_PREFIX}"
        echo "  Конфигурация: ${ETC_DIR}"
        echo "  Состояние:    ${VAR_DIR}"
        echo "  Команды:      ${BIN_PATH}/zml, ${BIN_PATH}/zms"
        echo
        return 0
    else
        log_error "Установка не удалась!"
        return 1
    fi
}

# Run main installation
main "$@"
