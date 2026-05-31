#!/bin/bash
# lib/strategies_discord.sh — Discord стратегии

source "$(dirname "$0")/../config/paths.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/meta.sh"
source "$(dirname "$0")/zapret_config.sh"
source "$(dirname "$0")/ui.sh"

strategy_dv1() {
    echo "--filter-udp=19294-19344,50000-50100 --filter-l7=discord,stun --payload=discord_ip_discovery,stun --lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=6 --new
--filter-tcp=2053,2083,2087,2096,8443 --filter-l7=tls --payload=tls_client_hello --lua-desync=multisplit:pos=2,seqovl=652"
}

install_discord_strategy() {
    print_info "Устанавливаем Discord стратегию Dv1..."

    local params
    params=$(strategy_dv1)

    zml_remove_strategy_block "Dv1"
    zml_write_strategy_block "Dv1" "$params" || return 1

    set_meta "DISCORD_STRATEGY" "Dv1" || return 1
    zml_apply_strategy || return 1

    print_success "Discord стратегия Dv1 установлена"
    pause_menu
    return 0
}
