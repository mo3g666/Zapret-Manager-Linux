#!/bin/bash
# lib/debug.sh — Функции диагностики и отладки

source "$(dirname "$0")/../config/paths.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/ui.sh"
source "$(dirname "$0")/meta.sh"

debug_show_strategy_files() {
    print_header "Диагностика стратегий"

    echo ""
    echo "=== Файлы состояния ==="

    # Показываем META_FILE
    echo ""
    echo "📄 META_FILE: $META_FILE"
    if [ -f "$META_FILE" ]; then
        echo "   Размер: $(stat -f%z "$META_FILE" 2>/dev/null || stat -c%s "$META_FILE" 2>/dev/null) байт"
        echo "   Содержимое:"
        sed 's/^/   /' "$META_FILE"
    else
        echo "   ❌ ФАЙЛ НЕ СУЩЕСТВУЕТ"
    fi

    # Показываем STRATEGY_FILE
    echo ""
    echo "📄 STRATEGY_FILE: $STRATEGY_FILE"
    if [ -f "$STRATEGY_FILE" ]; then
        local lines=$(wc -l < "$STRATEGY_FILE")
        echo "   Размер: $(stat -f%z "$STRATEGY_FILE" 2>/dev/null || stat -c%s "$STRATEGY_FILE" 2>/dev/null) байт ($lines строк)"
        echo "   Содержимое:"
        sed 's/^/   /' "$STRATEGY_FILE"
    else
        echo "   ❌ ФАЙЛ НЕ СУЩЕСТВУЕТ"
    fi

    # Показываем конфиг в zapret2
    echo ""
    echo "📄 ZAPRET_CONFIG_DIR: $ZAPRET_CONFIG_DIR"
    if [ -d "$ZAPRET_CONFIG_DIR" ]; then
        echo "   Файлы в директории:"
        ls -lah "$ZAPRET_CONFIG_DIR" 2>/dev/null | sed 's/^/   /'

        # Показываем содержимое config
        if [ -f "$ZAPRET_CONFIG_DIR/config" ]; then
            echo ""
            echo "   📄 config (первые 10 строк):"
            head -10 "$ZAPRET_CONFIG_DIR/config" | sed 's/^/      /'
        fi

        if [ -f "$ZAPRET_CONFIG_DIR/current.strategy" ]; then
            echo ""
            echo "   📄 current.strategy (первые 10 строк):"
            head -10 "$ZAPRET_CONFIG_DIR/current.strategy" | sed 's/^/      /'
        fi
    else
        echo "   ❌ ДИРЕКТОРИЯ НЕ СУЩЕСТВУЕТ"
    fi

    echo ""
    echo "=== Статус сервиса ==="
    systemctl status zapret2 2>&1 | head -10 | sed 's/^/   /'

    echo ""
    echo "=== Проверка логов ==="
    echo "   Последние 5 строк из $LOG_FILE:"
    tail -5 "$LOG_FILE" 2>/dev/null | sed 's/^/   /'

    pause_menu
}

debug_test_strategy_function() {
    print_header "Тест функции стратегии"

    echo ""
    echo "Введите номер стратегии (1-9):"
    read -p "Выбор: " num

    if [ -z "$num" ] || [ "$num" -lt 1 ] || [ "$num" -gt 9 ]; then
        print_error "Неверный номер"
        pause_menu
        return 1
    fi

    echo ""
    echo "Тестируем strategy_v$num:"
    echo ""

    local output
    output=$(strategy_v$num 2>&1)

    if [ -z "$output" ]; then
        print_error "Функция strategy_v$num вернула пустой результат!"
    else
        echo "Результат:"
        echo "$output" | sed 's/^/  /'

        echo ""
        print_success "Функция работает"
    fi

    pause_menu
}

debug_manual_apply_strategy() {
    print_header "Ручное применение стратегии"

    echo ""
    echo "Текущая стратегия в STRATEGY_FILE:"
    if [ -f "$STRATEGY_FILE" ]; then
        head -3 "$STRATEGY_FILE"
    else
        echo "Файл не существует"
    fi

    echo ""
    echo "Применяю стратегию..."

    if ! ensure_zapret_dirs; then
        print_error "Ошибка при создании директорий"
        pause_menu
        return 1
    fi

    if [ ! -f "$STRATEGY_FILE" ]; then
        print_error "STRATEGY_FILE не существует: $STRATEGY_FILE"
        pause_menu
        return 1
    fi

    echo "Копирую в /opt/zapret2/config/config..."
    if ! cp "$STRATEGY_FILE" "$ZAPRET_CONFIG_DIR/config"; then
        print_error "Ошибка копирования"
        pause_menu
        return 1
    fi
    print_success "Скопировано"

    echo "Перезапускаю zapret2..."
    if ! systemctl restart zapret2; then
        print_error "Ошибка при перезапуске"
        pause_menu
        return 1
    fi
    print_success "Перезапущен"

    echo ""
    echo "Проверяю статус..."
    systemctl status zapret2 | head -5

    pause_menu
}
