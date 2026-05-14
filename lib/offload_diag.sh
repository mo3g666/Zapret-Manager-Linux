#!/bin/bash
# lib/offload_diag.sh — Диагностика offload/fast-path

source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/ui.sh"

check_nft_flowtable() {
    print_header "Проверка nftables flowtable"

    if ! command -v nft &>/dev/null; then
        print_warning "nft не установлен"
        pause_menu
        return 1
    fi

    if nft list ruleset 2>/dev/null | grep -qi flowtable; then
        print_success "nftables flowtable найден"
        log_info "nftables flowtable detected"
    else
        print_info "nftables flowtable не используется"
        log_info "nftables flowtable not configured"
    fi

    pause_menu
}

check_iptables_flowoffload() {
    print_header "Проверка iptables FLOWOFFLOAD"

    if ! command -v iptables-save &>/dev/null; then
        print_warning "iptables не установлен"
        pause_menu
        return 1
    fi

    if iptables-save 2>/dev/null | grep -qi FLOWOFFLOAD; then
        print_success "FLOWOFFLOAD найден"
        log_info "iptables FLOWOFFLOAD detected"
    else
        print_info "FLOWOFFLOAD не используется"
        log_info "iptables FLOWOFFLOAD not configured"
    fi

    pause_menu
}

check_nic_offloads() {
    print_header "Проверка NIC offloads"

    if ! command -v ethtool &>/dev/null; then
        print_warning "ethtool не установлен"
        pause_menu
        return 1
    fi

    local found_offloads=0
    for iface in $(ip link 2>/dev/null | grep "^[0-9]" | cut -d: -f2 | xargs); do
        local iface_clean=${iface## }
        if [ -z "$iface_clean" ]; then
            continue
        fi

        local offloads_output
        offloads_output=$(ethtool -k "$iface_clean" 2>/dev/null | grep -E "generic-receive-offload|generic-segmentation-offload|tcp-segmentation-offload")

        if [ -n "$offloads_output" ]; then
            echo "Interface: $iface_clean"
            echo "$offloads_output"
            found_offloads=1
        fi
    done

    if [ $found_offloads -eq 0 ]; then
        print_info "Информация об offloads недоступна"
    fi

    pause_menu
}

disable_nic_offloads() {
    print_header "Отключить NIC offloads"
    print_warning "Это может снизить производительность сети!"

    local iface=$1
    if [ -z "$iface" ]; then
        read -p "Введите интерфейс (например, eth0): " iface
    fi

    if [ -z "$iface" ]; then
        print_error "Интерфейс не указан"
        pause_menu
        return 1
    fi

    if ! command -v ethtool &>/dev/null; then
        print_error "ethtool не установлен"
        pause_menu
        return 1
    fi

    if ethtool -K "$iface" gro off gso off tso off lro off 2>/dev/null; then
        print_success "Offloads отключены для $iface"
        log_info "Disabled offloads for $iface"
    else
        print_error "Не удалось отключить offloads для $iface"
        log_error "Failed to disable offloads for $iface"
    fi

    pause_menu
}
