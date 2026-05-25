#!/bin/bash
# lib/hosts.sh — Управление hosts

source "$(dirname "$0")/../config/paths.sh"
source "$(dirname "$0")/../config/domains.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/ui.sh"
source "$(dirname "$0")/backup.sh"

add_hosts_group() {
    local group_id="$1"
    local group_ref="DOMAINS_${group_id^^}"

    if [ -z "${!group_ref}" ]; then
        print_error "Группа $group_id не найдена"
        return 1
    fi

    backup_hosts || return 1

    local -n group="$group_ref"
    local marker_begin="${group[MARKER_BEGIN]}"
    local marker_end="${group[MARKER_END]}"
    local content="${group[CONTENT]}"

    if grep -q "$marker_begin" "$HOSTS_FILE"; then
        print_warning "Группа $group_id уже добавлена"
        return 0
    fi

    {
        echo ""
        echo "$marker_begin"
        echo "$content"
        echo "$marker_end"
    } >> "$HOSTS_FILE"

    log_info "Added hosts group: $group_id"
    reload_dns_cache
    print_success "Группа $group_id добавлена в hosts"
    return 0
}

remove_hosts_group() {
    local group_id="$1"
    local group_ref="DOMAINS_${group_id^^}"

    if [ -z "${!group_ref}" ]; then
        print_error "Группа $group_id не найдена"
        return 1
    fi

    backup_hosts || return 1

    local -n group="$group_ref"
    local marker_begin="${group[MARKER_BEGIN]}"
    local marker_end="${group[MARKER_END]}"

    if ! grep -q "$marker_begin" "$HOSTS_FILE"; then
        print_warning "Группа $group_id не добавлена"
        return 0
    fi

    sed -i "/$marker_begin/,/$marker_end/d" "$HOSTS_FILE"

    log_info "Removed hosts group: $group_id"
    reload_dns_cache
    print_success "Группа $group_id удалена из hosts"
    return 0
}

toggle_hosts_group() {
    local group_id="$1"
    local group_ref="DOMAINS_${group_id^^}"

    if [ -z "${!group_ref}" ]; then
        print_error "Группа $group_id не найдена"
        return 1
    fi

    local -n group="$group_ref"
    local marker_begin="${group[MARKER_BEGIN]}"

    if grep -q "$marker_begin" "$HOSTS_FILE" 2>/dev/null; then
        remove_hosts_group "$group_id"
    else
        add_hosts_group "$group_id"
    fi
}

list_hosts_groups() {
    print_header "Добавленные группы в hosts"

    for group_id in "${!DOMAINS_LIST[@]}"; do
        local group_ref="DOMAINS_${group_id^^}"
        local -n group="$group_ref"
        local marker="${group[MARKER_BEGIN]}"

        if grep -q "$marker" "$HOSTS_FILE" 2>/dev/null; then
            echo "✓ ${group[TITLE]}"
        fi
    done
}

reload_dns_cache() {
    if command -v resolvectl &>/dev/null; then
        resolvectl flush-caches 2>/dev/null
    elif systemctl list-unit-files | grep -q "systemd-resolved"; then
        systemctl restart systemd-resolved 2>/dev/null
    elif systemctl list-unit-files | grep -q "dnsmasq"; then
        systemctl restart dnsmasq 2>/dev/null
    fi
}
