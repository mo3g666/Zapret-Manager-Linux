#!/bin/bash
# lib/tester.sh — Тестирование стратегий

source "$(dirname "$0")/../config/paths.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/ui.sh"
source "$(dirname "$0")/zapret_config.sh"

test_builtin_strategies() {
    local current_strategy
    current_strategy=$(cat "$STRATEGY_FILE" 2>/dev/null || echo "")
    local results_file="$RESULTS_DIR/results_versions.txt"

    print_header "Тестирование стратегий v1-v9"

    # Создать директорию результатов если её нет
    mkdir -p "$RESULTS_DIR"

    # Очистить старые результаты
    > "$results_file"

    for v in v1 v2 v3 v4 v5 v6 v7 v8 v9; do
        print_info "Тестируем $v..."

        # Временно установить стратегию
        if ! zml_write_strategy_block "$v" "$(strategy_$v 2>/dev/null || echo '')" 2>/dev/null; then
            echo "$v: ERROR (strategy function not found)" | tee -a "$results_file"
            log_error "Strategy $v not found"
            continue
        fi

        if ! zml_apply_strategy 2>/dev/null; then
            echo "$v: ERROR (failed to apply strategy)" | tee -a "$results_file"
            log_error "Failed to apply strategy $v"
            continue
        fi

        sleep 2

        # Тестировать доступность
        if curl -sI --connect-timeout 5 --max-time 15 https://google.com 2>/dev/null | grep -q "HTTP"; then
            echo "$v: OK" | tee -a "$results_file"
            print_success "$v: OK"
        else
            echo "$v: FAIL" | tee -a "$results_file"
            print_error "$v: FAIL"
        fi
    done

    # Восстановить оригинальную стратегию
    if [ -n "$current_strategy" ]; then
        echo "$current_strategy" > "$STRATEGY_FILE"
        zml_apply_strategy 2>/dev/null
        print_success "Восстановлена оригинальная стратегия"
    fi

    print_info "Результаты сохранены в $results_file"
    pause_menu
}

test_current_strategy() {
    print_header "Тестирование текущей стратегии"
    print_info "Проверяем доступность https://google.com..."

    if curl -sI --connect-timeout 5 --max-time 15 https://google.com 2>/dev/null | grep -q "HTTP"; then
        print_success "Стратегия работает!"
    else
        print_error "Стратегия не работает"
    fi

    pause_menu
}

show_test_results() {
    local results_file="$RESULTS_DIR/results_versions.txt"

    if [ -f "$results_file" ]; then
        print_header "Результаты последних тестов"
        cat "$results_file"
    else
        print_info "Результатов еще нет"
    fi

    pause_menu
}
