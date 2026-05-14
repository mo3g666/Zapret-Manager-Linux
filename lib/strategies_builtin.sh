#!/bin/bash
# lib/strategies_builtin.sh — Встроенные стратегии v1-v9

source "$(dirname "$0")/../config/paths.sh"
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/meta.sh"
source "$(dirname "$0")/zapret_config.sh"

# v1: Split2 with seqovl
strategy_v1() {
    echo "--filter-tcp=443
--hostlist-exclude=$ZAPRET_IPSET_DIR/zapret-hosts-user-exclude.txt
--dpi-desync=split2
--dpi-desync-split-seqovl=681
--dpi-desync-split-seqovl-pattern=$ZAPRET_FAKE_DIR/stun.bin"
}

# v2: Fake + disorder
strategy_v2() {
    echo "--filter-tcp=443
--hostlist-exclude=$ZAPRET_IPSET_DIR/zapret-hosts-user-exclude.txt
--dpi-desync=fake,fakeddisorder
--dpi-desync-split-pos=10,midsld
--dpi-desync-fake-tls=$ZAPRET_FAKE_DIR/tls_clienthello_www_google_com.bin
--dpi-desync-fake-tls-mod=rnd,dupsid,sni=fonts.google.com
--dpi-desync-fooling=badseq,badsum
--dpi-desync-badseq-increment=0
--new
--filter-udp=443
--dpi-desync=fake
--dpi-desync-repeats=4
--dpi-desync-fake-quic=$ZAPRET_FAKE_DIR/quic_initial_www_google_com.bin"
}

# v3: Similar to v2 with different fake
strategy_v3() {
    echo "--filter-tcp=443
--hostlist-exclude=$ZAPRET_IPSET_DIR/zapret-hosts-user-exclude.txt
--dpi-desync=fake,fakeddisorder
--dpi-desync-split-pos=10,midsld
--dpi-desync-fake-tls=$ZAPRET_FAKE_DIR/t2.bin
--dpi-desync-fake-tls-mod=rnd,dupsid,sni=m.ok.ru
--dpi-desync-fooling=badseq,badsum
--dpi-desync-badseq-increment=0
--new
--filter-udp=443
--dpi-desync=fake
--dpi-desync-repeats=4
--dpi-desync-fake-quic=$ZAPRET_FAKE_DIR/quic_initial_www_google_com.bin"
}

# v4: Google hostlist
strategy_v4() {
    echo "--filter-tcp=443
--hostlist=$ZAPRET_IPSET_DIR/zapret-hosts-google.txt
--dpi-desync=fake,multisplit
--dpi-desync-split-pos=2,sld
--dpi-desync-fake-tls=0x0F0F0F0F
--dpi-desync-fake-tls=$ZAPRET_FAKE_DIR/tls_clienthello_www_google_com.bin
--dpi-desync-fake-tls-mod=rnd,dupsid,sni=google.com
--dpi-desync-split-seqovl=2108
--dpi-desync-split-seqovl-pattern=$ZAPRET_FAKE_DIR/tls_clienthello_www_google_com.bin
--dpi-desync-fooling=badseq
--new
--filter-tcp=443
--hostlist-exclude=$ZAPRET_IPSET_DIR/zapret-hosts-user-exclude.txt
--dpi-desync=multisplit
--dpi-desync-split-seqovl=582
--dpi-desync-split-pos=1
--dpi-desync-split-seqovl-pattern=$ZAPRET_FAKE_DIR/stun.bin
--new
--filter-udp=443
--hostlist-exclude=$ZAPRET_IPSET_DIR/zapret-hosts-user-exclude.txt
--dpi-desync=fake
--dpi-desync-repeats=4
--dpi-desync-fake-quic=$ZAPRET_FAKE_DIR/quic_initial_www_google_com.bin"
}

# v5: Fake + disorder with STUN
strategy_v5() {
    echo "--filter-tcp=443
--hostlist-exclude=$ZAPRET_IPSET_DIR/zapret-hosts-user-exclude.txt
--dpi-desync=fake,fakeddisorder
--dpi-desync-split-pos=1
--dpi-desync-fake-tls=$ZAPRET_FAKE_DIR/stun.bin
--dpi-desync-fake-tls-mod=none
--dpi-desync-fakedsplit-pattern=$ZAPRET_FAKE_DIR/tls_clienthello_www_google_com.bin
--dpi-desync-fooling=badseq,badsum
--dpi-desync-badseq-increment=0
--new
--filter-udp=443
--hostlist-exclude=$ZAPRET_IPSET_DIR/zapret-hosts-user-exclude.txt
--dpi-desync=fake
--dpi-desync-repeats=6
--dpi-desync-fake-quic=$ZAPRET_FAKE_DIR/quic_initial_www_google_com.bin"
}

# v6: Multisplit with sniext
strategy_v6() {
    echo "--filter-tcp=443
--hostlist=$ZAPRET_IPSET_DIR/zapret-hosts-google.txt
--dpi-desync=multisplit
--dpi-desync-split-pos=1,sniext+1
--dpi-desync-split-seqovl=1
--new
--filter-tcp=443
--hostlist-exclude=$ZAPRET_IPSET_DIR/zapret-hosts-user-exclude.txt
--dpi-desync=hostfakesplit
--dpi-desync-hostfakesplit-mod=host=i2.photo.2gis.com
--dpi-desync-hostfakesplit-midhost=host-2
--dpi-desync-split-seqovl=726
--dpi-desync-fooling=badsum,badseq
--dpi-desync-badseq-increment=0"
}

# v7: Default - fake + multisplit with Google hostlist (РЕКОМЕНДУЕТСЯ)
strategy_v7() {
    echo "--filter-tcp=443
--hostlist=$ZAPRET_IPSET_DIR/zapret-hosts-google.txt
--dpi-desync=fake,multisplit
--dpi-desync-split-pos=2,sld
--dpi-desync-fake-tls=0x0F0F0F0F
--dpi-desync-fake-tls=$ZAPRET_FAKE_DIR/tls_clienthello_www_google_com.bin
--dpi-desync-fake-tls-mod=rnd,dupsid,sni=ggpht.com
--dpi-desync-repeats=6
--dpi-desync-split-seqovl=620
--dpi-desync-split-seqovl-pattern=$ZAPRET_FAKE_DIR/tls_clienthello_www_google_com.bin
--dpi-desync-fooling=badsum,badseq
--new
--filter-tcp=443
--hostlist-exclude=$ZAPRET_IPSET_DIR/zapret-hosts-user-exclude.txt
--dpi-desync=fake,multisplit
--dpi-desync-split-seqovl=654
--dpi-desync-split-pos=1
--dpi-desync-fooling=badseq,badsum
--dpi-desync-repeats=6
--dpi-desync-split-seqovl-pattern=$ZAPRET_FAKE_DIR/stun.bin
--dpi-desync-fake-tls=$ZAPRET_FAKE_DIR/stun.bin
--dpi-desync-badseq-increment=0"
}

# v8: Similar to v7 with different fooling
strategy_v8() {
    echo "--filter-tcp=443
--hostlist=$ZAPRET_IPSET_DIR/zapret-hosts-google.txt
--dpi-desync=fake,multisplit
--dpi-desync-split-pos=2,sld
--dpi-desync-fake-tls=0x0F0F0F0F
--dpi-desync-fake-tls=$ZAPRET_FAKE_DIR/tls_clienthello_www_google_com.bin
--dpi-desync-fake-tls-mod=rnd,dupsid,sni=ggpht.com
--dpi-desync-split-seqovl=620
--dpi-desync-split-seqovl-pattern=$ZAPRET_FAKE_DIR/tls_clienthello_www_google_com.bin
--dpi-desync-fooling=badsum,badseq
--new
--filter-tcp=443
--hostlist-exclude=$ZAPRET_IPSET_DIR/zapret-hosts-user-exclude.txt
--dpi-desync=fake
--dpi-desync-fooling=ts
--dpi-desync-fake-tls=$ZAPRET_FAKE_DIR/4pda.bin
--dpi-desync-fake-tls-mod=none"
}

# v9: Hostfakesplit
strategy_v9() {
    echo "--filter-tcp=443
--hostlist-exclude=$ZAPRET_IPSET_DIR/zapret-hosts-user-exclude.txt
--dpi-desync=hostfakesplit
--dpi-desync-fooling=badseq,badsum
--dpi-desync-hostfakesplit-mod=host=mapgl.2gis.com
--dpi-desync-badseq-increment=0"
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
