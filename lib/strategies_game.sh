#!/bin/bash
# lib/strategies_game.sh — Game стратегии

source "$(dirname "$0")/../config/paths.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/meta.sh"
source "$(dirname "$0")/zapret_config.sh"
source "$(dirname "$0")/ui.sh"

strategy_gv1() {
    echo "--filter-udp=1024-65535 --payload=stun,wireguard_initiation,wireguard_response,wireguard_cookie --lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=2"
}

install_game_strategy() {
    print_info "Устанавливаем Game стратегию Gv1..."

    zml_remove_strategy_block "Gv1"
    zml_write_strategy_block "Gv1" "$(strategy_gv1)" || return 1

    set_meta "GAME_STRATEGY" "Gv1" || return 1
    zml_apply_strategy || return 1

    print_success "Game стратегия Gv1 установлена"
    pause_menu
    return 0
}

remove_game_strategy() {
    print_info "Удаляем Game стратегию..."

    zml_remove_strategy_block "Gv1"
    set_meta "GAME_STRATEGY" "" || return 1
    zml_apply_strategy || return 1

    print_success "Game стратегия удалена"
    pause_menu
    return 0
}
