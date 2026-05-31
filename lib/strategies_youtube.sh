#!/bin/bash
# lib/strategies_youtube.sh — YouTube стратегии

source "$(dirname "$0")/../config/paths.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/meta.sh"
source "$(dirname "$0")/zapret_config.sh"
source "$(dirname "$0")/ui.sh"

strategy_yv01() {
    echo "--filter-tcp=443 --filter-l7=tls --hostlist=$ZAPRET_IPSET_DIR/zapret-hosts-google.txt --payload=tls_client_hello --lua-desync=fake:blob=fake_default_tls:tcp_md5:repeats=5"
}

strategy_yv02() {
    echo "--filter-tcp=443 --filter-l7=tls --hostlist=$ZAPRET_IPSET_DIR/zapret-hosts-google.txt --payload=tls_client_hello --lua-desync=fake:blob=fake_default_tls:tcp_md5 --lua-desync=multisplit:pos=1:repeats=4"
}

strategy_yv03() {
    echo "--filter-tcp=443 --filter-l7=tls --hostlist=$ZAPRET_IPSET_DIR/zapret-hosts-google.txt --payload=tls_client_hello --lua-desync=fake:blob=fake_default_tls:tcp_md5 --lua-desync=multisplit:pos=2,sld:repeats=6"
}

install_youtube_strategy() {
    local version="${1:-yv03}"
    print_info "Устанавливаем YouTube стратегию $version..."

    zml_remove_strategy_block "YV01"
    zml_remove_strategy_block "YV02"
    zml_remove_strategy_block "YV03"

    local params
    params=$("strategy_$version" 2>/dev/null)
    if [ -z "$params" ]; then
        print_error "Стратегия $version не найдена"
        pause_menu
        return 1
    fi

    local block_name
    block_name=$(echo "$version" | tr '[:lower:]' '[:upper:]')

    zml_write_strategy_block "$block_name" "$params" || return 1

    set_meta "YOUTUBE_STRATEGY" "$block_name" || return 1
    zml_apply_strategy || return 1

    print_success "YouTube стратегия установлена"
    pause_menu
    return 0
}

remove_youtube_strategy() {
    print_info "Удаляем YouTube стратегию..."

    zml_remove_strategy_block "YV01"
    zml_remove_strategy_block "YV02"
    zml_remove_strategy_block "YV03"

    set_meta "YOUTUBE_STRATEGY" "" || return 1
    zml_apply_strategy || return 1

    print_success "YouTube стратегия удалена"
    pause_menu
    return 0
}
