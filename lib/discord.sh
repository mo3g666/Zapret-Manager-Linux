#!/bin/bash
# lib/discord.sh — Discord интеграция

source "$(dirname "$0")/../config/paths.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/ui.sh"
source "$(dirname "$0")/backup.sh"

install_discord_script() {
    local script_name="$1"

    if [ ! -d "$ZAPRET_CUSTOM_DIR" ]; then
        mkdir -p "$ZAPRET_CUSTOM_DIR" || return 1
    fi

    # URL для скрипта (примеры из OpenWrt версии)
    local script_url=""
    case "$script_name" in
        "50-stun4all") script_url="https://raw.githubusercontent.com/StressOzz/Zapret-Manager/main/scripts/50-stun4all" ;;
        "50-quic4all") script_url="https://raw.githubusercontent.com/StressOzz/Zapret-Manager/main/scripts/50-quic4all" ;;
        "50-discord-media") script_url="https://raw.githubusercontent.com/StressOzz/Zapret-Manager/main/scripts/50-discord-media" ;;
        "50-discord") script_url="https://raw.githubusercontent.com/StressOzz/Zapret-Manager/main/scripts/50-discord" ;;
        *) log_error "Unknown script: $script_name"; return 1 ;;
    esac

    print_info "Скачиваем Discord скрипт $script_name..."
    local tmp_file="/tmp/$script_name"

    if ! curl -sL -o "$tmp_file" "$script_url"; then
        log_error "Не удалось скачать $script_name"
        rm -f "$tmp_file"
        return 1
    fi

    # Удалить конфликтующие скрипты
    rm -f "$ZAPRET_CUSTOM_DIR"/50-* 2>/dev/null

    # Установить новый
    cp "$tmp_file" "$ZAPRET_CUSTOM_DIR/$script_name" || return 1
    chmod +x "$ZAPRET_CUSTOM_DIR/$script_name"
    rm -f "$tmp_file"

    log_info "Installed Discord script: $script_name"
    print_success "Скрипт $script_name установлен"
    return 0
}

remove_discord_script() {
    rm -f "$ZAPRET_CUSTOM_DIR"/50-* 2>/dev/null
    log_info "Removed Discord scripts"
    print_success "Discord скрипты удалены"
    return 0
}

add_discord_finland_hosts() {
    backup_hosts || return 1

    local marker_begin="# ZML_DISCORD_FINLAND_BEGIN"
    local marker_end="# ZML_DISCORD_FINLAND_END"

    if grep -q "$marker_begin" "$HOSTS_FILE"; then
        print_warning "Finland IPs уже добавлены"
        return 0
    fi

    print_info "Добавляем Finland IPs для Discord..."

    {
        echo ""
        echo "$marker_begin"
        for i in {0..199}; do
            printf "104.25.158.178 finland%05d.discord.media\n" $i
        done
        echo "$marker_end"
    } >> "$HOSTS_FILE"

    log_info "Added Discord Finland IPs"
    reload_dns_cache
    print_success "Finland IPs добавлены"
    return 0
}

remove_discord_finland_hosts() {
    backup_hosts || return 1

    sed -i "/^# ZML_DISCORD_FINLAND_BEGIN$/,/^# ZML_DISCORD_FINLAND_END$/d" "$HOSTS_FILE"

    log_info "Removed Discord Finland IPs"
    reload_dns_cache
    print_success "Finland IPs удалены"
    return 0
}

reload_dns_cache() {
    if command -v resolvectl &>/dev/null; then
        resolvectl flush-caches 2>/dev/null
    elif systemctl list-unit-files | grep -q "systemd-resolved"; then
        systemctl restart systemd-resolved 2>/dev/null
    fi
}
