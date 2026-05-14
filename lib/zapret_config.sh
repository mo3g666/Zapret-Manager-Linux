#!/bin/bash
# lib/zapret_config.sh — Генерация и применение стратегии

source "$(dirname "$0")/../config/paths.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/ui.sh"
source "$(dirname "$0")/service.sh"
source "$(dirname "$0")/meta.sh"

ensure_zapret_dirs() {
    mkdir -p "$ZML_DIR" "$ZML_STATE_DIR" "$ZML_BACKUP_DIR" "$ZAPRET_CONFIG_DIR" || return 1
    return 0
}

zml_apply_strategy() {
    print_info "Применяем стратегию..."

    if [ ! -f "$STRATEGY_FILE" ]; then
        log_error "Файл стратегии не найден: $STRATEGY_FILE"
        return 1
    fi

    ensure_zapret_dirs || return 1

    if ! cp "$STRATEGY_FILE" "$ZAPRET_CONFIG_DIR/current.strategy"; then
        log_error "Не удалось скопировать стратегию в zapret"
        return 1
    fi

    if ! zml_restart_zapret; then
        log_error "Не удалось применить стратегию"
        return 1
    fi

    log_info "Стратегия успешно применена"
    print_success "Стратегия применена"
    return 0
}

zml_write_strategy_block() {
    local marker="$1"
    local content="$2"

    ensure_zapret_dirs || return 1

    if [ ! -f "$STRATEGY_FILE" ]; then
        touch "$STRATEGY_FILE" || return 1
    fi

    # Если блок с таким маркером уже есть - удалить его
    if grep -q "^#$marker$" "$STRATEGY_FILE"; then
        sed -i "/^#$marker$/,/^#[A-Z]/{\
            /^#$marker$/!d;
            /^#[A-Z]/!d;
            /^#$marker$/d;
        }" "$STRATEGY_FILE"
    fi

    # Добавить новый блок
    {
        echo "#$marker"
        echo "$content"
    } >> "$STRATEGY_FILE"

    return 0
}

zml_remove_strategy_block() {
    local marker="$1"

    if [ ! -f "$STRATEGY_FILE" ]; then
        return 0
    fi

    sed -i "/^#$marker$/,/^#[A-Z]/d" "$STRATEGY_FILE"

    return 0
}
