#!/bin/bash
# lib/zapret_config.sh — Генерация и применение стратегии

source "$(dirname "$0")/../config/paths.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/ui.sh"
source "$(dirname "$0")/service.sh"
source "$(dirname "$0")/meta.sh"

ensure_zapret_dirs() {
    # Создаём директории для ZML, но НЕ для ZAPRET_CONFIG_DIR
    # т.к. /opt/zapret2/config это файл, а не директория!
    mkdir -p "$ZML_DIR" "$ZML_STATE_DIR" "$ZML_BACKUP_DIR" || return 1
    return 0
}

zml_apply_strategy() {
    print_info "Применяем стратегию..."

    if [ ! -f "$STRATEGY_FILE" ]; then
        log_error "Файл стратегии не найден: $STRATEGY_FILE"
        return 1
    fi

    if [ ! -s "$STRATEGY_FILE" ]; then
        log_error "Файл стратегии пустой"
        return 1
    fi

    ensure_zapret_dirs || return 1

    local zapret_config_file="/opt/zapret2/config"

    if [ ! -f "$zapret_config_file" ]; then
        log_error "Конфиг zapret2 не найден: $zapret_config_file"
        log_error "Установите zapret2 сначала (меню 8)"
        return 1
    fi

    # Бэкап конфига перед изменением
    cp "$zapret_config_file" "${zapret_config_file}.bak" 2>/dev/null || true

    # Включаем nfqws2
    if grep -q "^NFQWS2_ENABLE=" "$zapret_config_file"; then
        sed -i 's/^NFQWS2_ENABLE=[^ ]*/NFQWS2_ENABLE=1/' "$zapret_config_file"
    else
        echo "NFQWS2_ENABLE=1" >> "$zapret_config_file"
    fi

    # Обновляем NFQWS2_OPT, не трогая остальные настройки (FWTYPE, IFACE_WAN и др.)
    # Пропускаем строки-маркеры (#v7, #YOUTUBE и т.д.) и пустые строки
    local tmp_config
    tmp_config=$(mktemp) || return 1

    awk -v strat="$STRATEGY_FILE" '
        /^NFQWS2_OPT=/ {
            print "NFQWS2_OPT=\""
            while ((getline line < strat) > 0) {
                if (line !~ /^#/ && line != "") print line
            }
            close(strat)
            print "\""
            in_opt = 1
            next
        }
        in_opt { if (/^"$/) in_opt = 0; next }
        { print }
    ' "$zapret_config_file" > "$tmp_config" || { rm -f "$tmp_config"; return 1; }

    if ! mv "$tmp_config" "$zapret_config_file"; then
        log_error "Не удалось обновить $zapret_config_file"
        return 1
    fi

    log_info "NFQWS2_OPT обновлён в $zapret_config_file"

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
