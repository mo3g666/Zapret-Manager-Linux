#!/bin/bash
# lib/strategies_builtin.sh — Встроенные стратегии v1-v9

source "$(dirname "$0")/../config/paths.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/meta.sh"
source "$(dirname "$0")/zapret_config.sh"

# Стратегии используют новый синтаксис nfqws2 (zapret2) с --lua-desync=
# Каждое правило — на одной строке, разделены через --new
# Именованные блобы (fake_default_tls, fake_default_quic) берутся из Lua-библиотеки zapret2

# v1: Multisplit без fake (простой)
strategy_v1() {
    echo "--filter-tcp=443 --filter-l7=tls --payload=tls_client_hello --lua-desync=multisplit:pos=1,midsld --new
--filter-udp=443 --filter-l7=quic --payload=quic_initial --lua-desync=fake:blob=fake_default_quic:repeats=4"
}

# v2: Fake + multidisorder (аналог config.default)
strategy_v2() {
    echo "--filter-tcp=80 --filter-l7=http --payload=http_req --lua-desync=fake:blob=fake_default_http:tcp_md5 --lua-desync=multisplit:pos=method+2 --new
--filter-tcp=443 --filter-l7=tls --payload=tls_client_hello --lua-desync=fake:blob=fake_default_tls:tcp_md5:tcp_seq=-10000 --lua-desync=multidisorder:pos=1,midsld --new
--filter-udp=443 --filter-l7=quic --payload=quic_initial --lua-desync=fake:blob=fake_default_quic:repeats=6"
}

# v3: Fake + multidisorder с tls_mod
strategy_v3() {
    echo "--filter-tcp=443 --filter-l7=tls --payload=tls_client_hello --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid --lua-desync=multidisorder:pos=1,midsld --new
--filter-udp=443 --filter-l7=quic --payload=quic_initial --lua-desync=fake:blob=fake_default_quic:repeats=4"
}

# v4: Fake + multisplit (базовый)
strategy_v4() {
    echo "--filter-tcp=443 --filter-l7=tls --payload=tls_client_hello --lua-desync=fake:blob=fake_default_tls:tcp_md5 --lua-desync=multisplit:pos=1,midsld --new
--filter-udp=443 --filter-l7=quic --payload=quic_initial --lua-desync=fake:blob=fake_default_quic:repeats=4"
}

# v5: Fake + multisplit с tls_mod
strategy_v5() {
    echo "--filter-tcp=443 --filter-l7=tls --payload=tls_client_hello --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid --lua-desync=multisplit:pos=1,midsld --new
--filter-udp=443 --filter-l7=quic --payload=quic_initial --lua-desync=fake:blob=fake_default_quic:repeats=6"
}

# v6: wssize (для DPI чувствительного к размеру окна)
strategy_v6() {
    echo "--filter-tcp=443 --filter-l7=tls --payload=tls_client_hello --lua-desync=wssize:wsize=1:scale=6 --lua-desync=fake:blob=fake_default_tls:tcp_md5 --new
--filter-udp=443 --filter-l7=quic --payload=quic_initial --lua-desync=fake:blob=fake_default_quic:repeats=4"
}

# v7: Fake + multisplit с tls_mod — РЕКОМЕНДУЕТСЯ
strategy_v7() {
    echo "--filter-tcp=443 --filter-l7=tls --payload=tls_client_hello --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid --lua-desync=multisplit:pos=1,midsld --new
--filter-udp=443 --filter-l7=quic --payload=quic_initial --lua-desync=fake:blob=fake_default_quic:repeats=6"
}

# v8: Полное покрытие HTTP+HTTPS+QUIC
strategy_v8() {
    echo "--filter-tcp=80 --filter-l7=http --payload=http_req --lua-desync=fake:blob=fake_default_http:tcp_md5 --lua-desync=multisplit:pos=method+2 --new
--filter-tcp=443 --filter-l7=tls --payload=tls_client_hello --lua-desync=fake:blob=fake_default_tls:tcp_md5:tls_mod=rnd,dupsid --lua-desync=multisplit:pos=1,midsld --new
--filter-udp=443 --filter-l7=quic --payload=quic_initial --lua-desync=fake:blob=fake_default_quic:repeats=6"
}

# v9: seqovl
strategy_v9() {
    echo "--filter-tcp=443 --filter-l7=tls --payload=tls_client_hello --lua-desync=fake:blob=fake_default_tls:tcp_md5 --lua-desync=multisplit:pos=1:seqovl=1 --new
--filter-udp=443 --filter-l7=quic --payload=quic_initial --lua-desync=fake:blob=fake_default_quic:repeats=4"
}

# === ВЫБОР И УСТАНОВКА ===

select_builtin_strategy() {
    while true; do
        print_header "Выбор стратегии v1-v9"

        local current=$(get_meta "MAIN_STRATEGY" "$DEFAULT_MAIN_STRATEGY")
        echo "Текущая стратегия: $current"
        echo ""

        echo "1) v1 - Split2 with seqovl"
        echo "2) v2 - Fake + disorder"
        echo "3) v3 - Fake + disorder (OK.ru)"
        echo "4) v4 - Google hostlist"
        echo "5) v5 - Fake + disorder with STUN"
        echo "6) v6 - Multisplit with sniext"
        echo "7) v7 - Fake + multisplit (РЕКОМЕНДУЕТСЯ)"
        echo "8) v8 - Fake + multisplit (TS fooling)"
        echo "9) v9 - Hostfakesplit"
        echo "0) Назад"
        echo ""

        read -p "Выбор: " choice

        case "$choice" in
            1) install_builtin_strategy "v1" && break ;;
            2) install_builtin_strategy "v2" && break ;;
            3) install_builtin_strategy "v3" && break ;;
            4) install_builtin_strategy "v4" && break ;;
            5) install_builtin_strategy "v5" && break ;;
            6) install_builtin_strategy "v6" && break ;;
            7) install_builtin_strategy "v7" && break ;;
            8) install_builtin_strategy "v8" && break ;;
            9) install_builtin_strategy "v9" && break ;;
            0) break ;;
            *) print_error "Неверный выбор" && pause_menu ;;
        esac
    done
}

install_builtin_strategy() {
    local version="$1"

    print_info "Устанавливаем стратегию $version..."

    local params
    params=$("strategy_$version")

    if [ -z "$params" ]; then
        print_error "Стратегия $version не найдена"
        return 1
    fi

    zml_remove_strategy_block "$version"

    if ! zml_write_strategy_block "$version" "$params"; then
        print_error "Не удалось записать стратегию"
        return 1
    fi

    set_meta "MAIN_STRATEGY" "$version" || return 1

    zml_apply_strategy || return 1

    print_success "Стратегия $version установлена"
    pause_menu
    return 0
}
