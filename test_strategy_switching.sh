#!/bin/bash
# Скрипт для тестирования переключения стратегий

set -o pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}[ℹ]${NC} $*"; }
log_ok() { echo -e "${GREEN}[✓]${NC} $*"; }
log_err() { echo -e "${RED}[✗]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $*"; }

# Функция для печати заголовка
print_section() {
    echo ""
    echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
}

# === ПРОВЕРКА ПРЕДУСЛОВИЙ ===
print_section "1. Проверка предусловий"

# Требуется root
if [[ $EUID -ne 0 ]]; then
    log_err "Требуется root доступ (используйте sudo bash test_strategy_switching.sh)"
    exit 1
fi
log_ok "Права root получены"

# Проверяем zapret2
if ! systemctl is-active --quiet zapret2; then
    log_warn "Сервис zapret2 не запущен"
    log_info "Попытаюсь запустить..."
    systemctl start zapret2 || {
        log_err "Не удалось запустить zapret2"
        exit 1
    }
fi
log_ok "Сервис zapret2 запущен"

# Проверяем конфиг
if [[ ! -f /opt/zapret2/config ]]; then
    log_err "/opt/zapret2/config не существует"
    exit 1
fi
log_ok "/opt/zapret2/config существует"

# === СОСТОЯНИЕ ПЕРЕД ТЕСТОМ ===
print_section "2. Состояние системы ДО тестирования"

log_info "Текущие параметры zapret2:"
echo "───────────────────────────────────────────────────────────"
head -5 /opt/zapret2/config || log_warn "Не удалось прочитать конфиг"
echo "───────────────────────────────────────────────────────────"

# === ЗАГРУЗКА ZML МОДУЛЕЙ ===
print_section "3. Загрузка модулей ZML"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

source config/paths.sh || {
    log_err "Не удалось загрузить config/paths.sh"
    exit 1
}
log_ok "Загружен config/paths.sh"

source lib/logger.sh || {
    log_err "Не удалось загрузить lib/logger.sh"
    exit 1
}
log_ok "Загружен lib/logger.sh"

source lib/ui.sh || {
    log_err "Не удалось загрузить lib/ui.sh"
    exit 1
}
log_ok "Загружен lib/ui.sh"

source lib/meta.sh || {
    log_err "Не удалось загрузить lib/meta.sh"
    exit 1
}
log_ok "Загружен lib/meta.sh"

source lib/zapret_config.sh || {
    log_err "Не удалось загрузить lib/zapret_config.sh"
    exit 1
}
log_ok "Загружен lib/zapret_config.sh"

source lib/service.sh || {
    log_err "Не удалось загрузить lib/service.sh"
    exit 1
}
log_ok "Загружен lib/service.sh"

source lib/strategies_builtin.sh || {
    log_err "Не удалось загрузить lib/strategies_builtin.sh"
    exit 1
}
log_ok "Загружены встроенные стратегии"

# Инициализируем логирование
ensure_log_file || {
    log_err "Не удалось инициализировать логирование"
    exit 1
}
log_ok "Логирование инициализировано"

# === ТЕСТ 1: Проверка функций стратегий ===
print_section "4. Тест функций стратегий"

for v in 1 2 3 4 5 6 7 8 9; do
    params=$("strategy_v$v" 2>&1) || {
        log_err "strategy_v$v вернула ошибку"
        continue
    }

    if [[ -z "$params" ]]; then
        log_err "strategy_v$v вернула пустой результат"
    else
        lines=$(echo "$params" | wc -l)
        log_ok "strategy_v$v: $lines строк параметров"
    fi
done

# === ТЕСТ 2: Переключение на v7 ===
print_section "5. Тестирование переключения на v7"

log_info "Вызов install_builtin_strategy v7..."

# Перенаправляем вывод функций
{
    install_builtin_strategy "v7" 2>&1
} | grep -v "^Выбор:" | head -20

sleep 1

# === ПРОВЕРКА РЕЗУЛЬТАТА ===
print_section "6. Проверка результата применения"

if [[ ! -f "$STRATEGY_FILE" ]]; then
    log_err "STRATEGY_FILE не создан: $STRATEGY_FILE"
else
    log_ok "STRATEGY_FILE существует"
    log_info "Размер: $(stat -f%z "$STRATEGY_FILE" 2>/dev/null || stat -c%s "$STRATEGY_FILE" 2>/dev/null) байт"

    # Проверяем что v7 находится в файле
    if grep -q "^#v7$" "$STRATEGY_FILE"; then
        log_ok "Маркер #v7 найден в STRATEGY_FILE"
    else
        log_warn "Маркер #v7 НЕ найден в STRATEGY_FILE"
        log_info "Содержимое STRATEGY_FILE:"
        head -10 "$STRATEGY_FILE" | sed 's/^/  /'
    fi
fi

# Проверяем /opt/zapret2/config
log_info "Содержимое /opt/zapret2/config:"
head -5 /opt/zapret2/config | sed 's/^/  /'

# Проверяем метаданные
current_strategy=$(get_meta "MAIN_STRATEGY" "unknown")
log_info "Текущая стратегия в meta: $current_strategy"
if [[ "$current_strategy" == "v7" ]]; then
    log_ok "Метаданные правильно установлены на v7"
else
    log_warn "Метаданные показывают: $current_strategy (ожидается v7)"
fi

# === ПРОВЕРКА СЕРВИСА ===
print_section "7. Проверка статуса сервиса"

if systemctl is-active --quiet zapret2; then
    log_ok "Сервис zapret2 активен"
    systemctl status zapret2 2>&1 | head -5 | sed 's/^/  /'
else
    log_warn "Сервис zapret2 НЕ активен после применения"
    log_info "Попытаюсь перезапустить..."
    systemctl restart zapret2 || log_err "Не удалось перезапустить"
fi

# === ИТОГОВЫЙ ОТЧЕТ ===
print_section "8. Итоговый отчет"

if [[ -f "$STRATEGY_FILE" ]] && grep -q "^#v7$" "$STRATEGY_FILE" && \
   [[ $(get_meta "MAIN_STRATEGY" "") == "v7" ]] && \
   systemctl is-active --quiet zapret2; then

    echo ""
    log_ok "УСПЕХ: Переключение стратегии работает корректно!"
    echo ""
    log_info "Что произошло:"
    echo "  1. Стратегия v7 была загена в STRATEGY_FILE"
    echo "  2. Файл был скопирован в /opt/zapret2/config"
    echo "  3. Метаданные обновлены"
    echo "  4. Сервис zapret2 перезапущен"
    echo ""
else
    echo ""
    log_err "ПРОБЛЕМА: Есть ошибки в процессе переключения"
    echo ""

    [[ ! -f "$STRATEGY_FILE" ]] && log_err "  - STRATEGY_FILE не создан"
    ! grep -q "^#v7$" "$STRATEGY_FILE" 2>/dev/null && log_err "  - Стратегия не записана в STRATEGY_FILE"
    [[ $(get_meta "MAIN_STRATEGY" "") != "v7" ]] && log_err "  - Метаданные не обновлены"
    ! systemctl is-active --quiet zapret2 && log_err "  - Сервис zapret2 не запущен"

    log_warn "Запустите 'zml' для ручной диагностики (меню 9)"
fi

echo ""
log_info "Полная диагностика доступна в меню zml -> опция 9"
echo ""
