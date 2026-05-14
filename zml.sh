#!/bin/bash
# zml.sh — Zapret Manager Linux, главный скрипт

set -o pipefail

# Переходим в директорию скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
    print_header "Меню стратегий"
    print_info "Будет реализовано на Этап 2"
    pause_menu
}

# === МЕНЮ ТЕСТИРОВАНИЯ ===
menu_testing() {
    print_header "Меню тестирования стратегий"
    print_info "Будет реализовано на Этап 5"
    pause_menu
}

# === МЕНЮ DISCORD ===
menu_discord() {
    print_header "Меню настройки Discord"
    print_info "Будет реализовано на Этап 4"
    pause_menu
}

# === МЕНЮ HOSTS ===
menu_hosts() {
    print_header "Меню управления доменами в hosts"
    print_info "Будет реализовано на Этап 3"
    pause_menu
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
                systemctl status zapret 2>/dev/null || print_error "zapret не установлен"
                pause_menu
                ;;
            5) break ;;
            *) print_error "Неверный выбор" && pause_menu ;;
        esac
    done
}

# === МЕНЮ BACKUP/RESTORE ===
menu_backup() {
    print_header "Backup/restore"
    print_info "Будет реализовано на Этап 3"
    pause_menu
}

# === МЕНЮ ДИАГНОСТИКИ ===
menu_diagnostics() {
    print_header "Диагностика системы"
    print_info "Будет реализовано на Этап 7"
    pause_menu
}

# === МЕНЮ INSTALLER ===
menu_installer() {
    print_header "Установка/обновление зависимостей"
    print_info "Будет реализовано на Этап 2"
    pause_menu
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

    # Главное меню
    show_main_menu
}

main "$@"
