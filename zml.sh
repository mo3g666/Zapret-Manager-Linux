#!/bin/bash
# zml.sh — Zapret Manager Linux, главный скрипт

set -o pipefail

# Определяем директорию скрипта (разрешаем symlink)
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_PATH" ]]; do
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Загружаем конфиг и модули
source config/paths.sh
source config/defaults.sh
source config/domains.sh
source lib/logger.sh
source lib/ui.sh
source lib/os.sh
source lib/service.sh
source lib/meta.sh
source lib/backup.sh
source lib/hosts.sh
source lib/zapret_config.sh
source lib/strategies_builtin.sh
source lib/strategies_discord.sh
source lib/strategies_youtube.sh
source lib/strategies_game.sh
source lib/strategies_flowseal.sh
source lib/discord.sh
source lib/tester.sh
source lib/offload_diag.sh
source lib/installer.sh
source lib/updater.sh

# === ГЛАВНОЕ МЕНЮ ===

show_main_menu() {
    while true; do
        print_header "Zapret Manager Linux v$ZAPRET_MANAGER_VERSION"

        # Статус
        local zapret_status
        zapret_status=$(zml_zapret_status_display 2>/dev/null)
        local main_strategy=$(get_meta "MAIN_STRATEGY" "$DEFAULT_MAIN_STRATEGY")

        show_status "Сервис zapret" "$zapret_status"
        show_status "Основная стратегия" "$main_strategy"
        show_status "Режим" "$(get_meta MODE local)"
        echo ""

        echo "1) Меню стратегий"
        echo "2) Меню тестирования стратегий"
        echo "3) Меню настройки Discord"
        echo "4) Меню управления доменами в hosts"
        echo "5) Управление сервисом zapret"
        echo "6) Backup/restore"
        echo "7) Диагностика системы"
        echo "8) Установка/обновление зависимостей"
        echo "q) Выход"
        echo ""

        read -p "Выбор: " choice

        case "$choice" in
            1) menu_strategies ;;
            2) menu_testing ;;
            3) menu_discord ;;
            4) menu_hosts ;;
            5) menu_service ;;
            6) menu_backup ;;
            7) menu_diagnostics ;;
            8) menu_installer ;;
            q|Q)
                print_info "До свидания"
                log_info "Менеджер завершён"
                break
                ;;
            *)
                print_error "Неверный выбор"
                pause_menu
                ;;
        esac
    done
}

# === МЕНЮ СТРАТЕГИЙ ===
menu_strategies() {
    while true; do
        print_header "Меню стратегий"

        local main=$(get_meta "MAIN_STRATEGY" "$DEFAULT_MAIN_STRATEGY")
        local youtube=$(get_meta "YOUTUBE_STRATEGY" "")
        local game=$(get_meta "GAME_STRATEGY" "")
        local discord=$(get_meta "DISCORD_STRATEGY" "")

        echo "Основная стратегия: $main"
        echo "YouTube: ${youtube:-(не установлена)}"
        echo "Игры: ${game:-(не установлена)}"
        echo "Discord: ${discord:-(не установлена)}"
        echo ""

        echo "1) Выбрать и установить стратегию v1-v9"
        echo "2) Установить стратегию Flowseal"
        echo "3) Выбрать и установить стратегию для YouTube"
        echo "4) Выбрать и установить стратегию для игр"
        echo "5) Включить / Выключить обход по спискам РКН"
        echo "6) Обновить список исключений"
        echo "7) Включить / Выключить блок --wssize 1:6"
        echo "8) Включить / Выключить блок --methodeol"
        echo "0) Назад в главное меню"
        echo ""

        read -p "Выбор: " choice

        case "$choice" in
            1) select_builtin_strategy ;;
            2) install_flowseal_strategy ;;
            3)
                print_header "YouTube стратегии"
                echo "1) YV01 - Fake TLS"
                echo "2) YV02 - Fake + multisplit (pos 1)"
                echo "3) YV03 - Fake + multisplit (pos 2, sld)"
                echo "0) Назад"
                read -p "Выбор: " yt_choice
                case "$yt_choice" in
                    1) install_youtube_strategy "yv01" ;;
                    2) install_youtube_strategy "yv02" ;;
                    3) install_youtube_strategy "yv03" ;;
                    0) ;;
                    *) print_error "Неверный выбор" && pause_menu ;;
                esac
                ;;
            4) install_game_strategy ;;
            5) print_info "РКН будет на Этап 2" && pause_menu ;;
            6) print_info "Обновление списков будет на Этап 2" && pause_menu ;;
            7) print_info "WSSIZE будет на Этап 2" && pause_menu ;;
            8) print_info "METHODEOL будет на Этап 2" && pause_menu ;;
            0) break ;;
            *) print_error "Неверный выбор" && pause_menu ;;
        esac
    done
}

# === МЕНЮ ТЕСТИРОВАНИЯ ===
menu_testing() {
    while true; do
        print_header "Меню тестирования стратегий"

        echo "1) Тестировать стратегии v1-v9"
        echo "2) Тестировать текущую стратегию"
        echo "3) Показать результаты последних тестов"
        echo "0) Назад"
        echo ""

        read -p "Выбор: " choice

        case "$choice" in
            1) test_builtin_strategies ;;
            2) test_current_strategy ;;
            3) show_test_results ;;
            0) break ;;
            *) print_error "Неверный выбор" && pause_menu ;;
        esac
    done
}

# === МЕНЮ DISCORD ===
menu_discord() {
    while true; do
        print_header "Меню настройки Discord"

        local discord_script=$(get_meta "DISCORD_SCRIPT" "(не установлен)")
        echo "Установленный скрипт: $discord_script"
        echo ""

        echo "1) Установить скрипт 50-stun4all"
        echo "2) Установить скрипт 50-quic4all"
        echo "3) Установить скрипт 50-discord-media"
        echo "4) Установить скрипт 50-discord"
        echo "5) Удалить Discord скрипты"
        echo "6) Добавить Finland IPs в hosts"
        echo "7) Удалить Finland IPs"
        echo "8) Установить Discord стратегию Dv1"
        echo "0) Назад"
        echo ""

        read -p "Выбор: " choice

        case "$choice" in
            1) install_discord_script "50-stun4all" && set_meta "DISCORD_SCRIPT" "50-stun4all" && pause_menu ;;
            2) install_discord_script "50-quic4all" && set_meta "DISCORD_SCRIPT" "50-quic4all" && pause_menu ;;
            3) install_discord_script "50-discord-media" && set_meta "DISCORD_SCRIPT" "50-discord-media" && pause_menu ;;
            4) install_discord_script "50-discord" && set_meta "DISCORD_SCRIPT" "50-discord" && pause_menu ;;
            5) remove_discord_script && set_meta "DISCORD_SCRIPT" "" && pause_menu ;;
            6) add_discord_finland_hosts && set_meta "DISCORD_FINLAND_IPS" "1" && pause_menu ;;
            7) remove_discord_finland_hosts && set_meta "DISCORD_FINLAND_IPS" "0" && pause_menu ;;
            8) install_discord_strategy ;;
            0) break ;;
            *) print_error "Неверный выбор" && pause_menu ;;
        esac
    done
}

# === МЕНЮ HOSTS ===
menu_hosts() {
    while true; do
        print_header "Меню управления доменами в hosts"

        list_hosts_groups
        echo ""

        echo " 0) Добавить nalog.ru"
        echo " 1) Удалить  rutor.info"
        echo " 2) Удалить  ntc.party"
        echo " 3) Удалить  Instagram & Facebook"
        echo " 4) Удалить  lib.rus.ec"
        echo " 5) Удалить  AI сервисы"
        echo " 6) Удалить  Twitch"
        echo " 7) Удалить  Telegram Web"
        echo " 8) Удалить  Spotify"
        echo " 9) Удалить  Supercell"
        echo "10) Удалить  githubusercontent.com"
        echo "11) Удалить все домены"
        echo "12) Восстановить hosts"
        echo "Enter) Выход в главное меню"
        echo ""

        read -p "Выбор: " choice

        case "$choice" in
            0) add_hosts_group "nalog" && pause_menu ;;
            1) remove_hosts_group "rutor" && pause_menu ;;
            2) remove_hosts_group "ntc" && pause_menu ;;
            3) remove_hosts_group "instagram" && pause_menu ;;
            4) remove_hosts_group "librusec" && pause_menu ;;
            5) remove_hosts_group "ai" && pause_menu ;;
            6) remove_hosts_group "twitch" && pause_menu ;;
            7) remove_hosts_group "telegram" && pause_menu ;;
            8) remove_hosts_group "spotify" && pause_menu ;;
            9) remove_hosts_group "supercell" && pause_menu ;;
            10) remove_hosts_group "github" && pause_menu ;;
            11)
                for group_id in nalog rutor ntc librusec ai instagram twitch telegram spotify supercell github; do
                    remove_hosts_group "$group_id" 2>/dev/null
                done
                pause_menu
                ;;
            12)
                list_backups
                read -p "Выбрать номер backup: " backup_num
                # Simple implementation - show files
                pause_menu
                ;;
            "") break ;;
            *) print_error "Неверный выбор" && pause_menu ;;
        esac
    done
}

# === МЕНЮ СЕРВИСА ===
menu_service() {
    while true; do
        print_header "Управление сервисом zapret"

        echo "1) Запустить zapret"
        echo "2) Остановить zapret"
        echo "3) Перезапустить zapret"
        echo "4) Показать статус"
        echo "5) Назад в главное меню"
        echo ""

        read -p "Выбор: " choice

        case "$choice" in
            1) zml_start_zapret && pause_menu ;;
            2) zml_stop_zapret && pause_menu ;;
            3) zml_restart_zapret && pause_menu ;;
            4)
                systemctl status zapret2 2>/dev/null || print_error "zapret2 не установлен"
                pause_menu
                ;;
            5) break ;;
            *) print_error "Неверный выбор" && pause_menu ;;
        esac
    done
}

# === МЕНЮ BACKUP/RESTORE ===
menu_backup() {
    while true; do
        print_header "Backup/restore"

        echo "1) Сделать backup hosts"
        echo "2) Сделать backup стратегии"
        echo "3) Сделать backup meta"
        echo "4) Восстановить hosts"
        echo "5) Восстановить стратегию"
        echo "6) Показать доступные backups"
        echo "0) Назад"
        echo ""

        read -p "Выбор: " choice

        case "$choice" in
            1) backup_hosts && print_success "Backup hosts создан" && pause_menu ;;
            2) backup_strategy && print_success "Backup стратегии создан" && pause_menu ;;
            3) backup_meta && print_success "Backup meta создан" && pause_menu ;;
            4) list_backups && pause_menu ;;
            5) list_backups && pause_menu ;;
            6) list_backups && pause_menu ;;
            0) break ;;
            *) print_error "Неверный выбор" && pause_menu ;;
        esac
    done
}

# === МЕНЮ ДИАГНОСТИКИ ===
menu_diagnostics() {
    while true; do
        print_header "Диагностика системы"

        echo "1) Проверить nftables flowtable"
        echo "2) Проверить iptables FLOWOFFLOAD"
        echo "3) Проверить NIC offloads"
        echo "4) Отключить NIC offloads"
        echo "0) Назад"
        echo ""

        read -p "Выбор: " choice

        case "$choice" in
            1) check_nft_flowtable ;;
            2) check_iptables_flowoffload ;;
            3) check_nic_offloads ;;
            4)
                read -p "Введите интерфейс: " iface
                disable_nic_offloads "$iface"
                ;;
            0) break ;;
            *) print_error "Неверный выбор" && pause_menu ;;
        esac
    done
}

# === МЕНЮ INSTALLER ===
menu_installer() {
    while true; do
        print_header "Установка/обновление зависимостей"

        echo "1) Проверить зависимости"
        echo "2) Установить зависимости"
        echo "3) Установить zapret (последняя версия)"
        echo "4) Обновить zapret"
        echo "5) Показать логи установки"
        echo "0) Назад в главное меню"
        echo ""

        read -p "Выбор: " choice

        case "$choice" in
            1)
                check_dependencies && print_success "Все зависимости установлены"
                pause_menu
                ;;
            2)
                install_dependencies && print_success "Зависимости установлены"
                pause_menu
                ;;
            3)
                local version
                version=$(get_latest_zapret_version)
                install_or_update_zapret "$version" && pause_menu
                ;;
            4)
                local version
                version=$(get_latest_zapret_version)
                install_or_update_zapret "$version" && pause_menu
                ;;
            5)
                show_install_log
                pause_menu
                ;;
            0) break ;;
            *) print_error "Неверный выбор" && pause_menu ;;
        esac
    done
}

# === ГЛАВНАЯ ФУНКЦИЯ ===

main() {
    # Проверки
    check_root || exit 1
    check_os || exit 1
    check_dependencies || exit 1

    # Инициализация
    ensure_log_file || exit 1
    ensure_meta_defaults || exit 1

    log_info "Запуск Zapret Manager Linux v$ZAPRET_MANAGER_VERSION"

    # Проверка обновлений (асинхронно в фоне)
    check_for_updates

    # Уведомление об обновлении (если доступно)
    notify_if_update_available

    # Главное меню
    show_main_menu
}

main "$@"
