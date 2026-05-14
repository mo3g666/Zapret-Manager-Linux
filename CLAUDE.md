# Zapret Manager Linux - Инструкции для Claude Code

## Язык общения
**Все ответы только на русском языке.** Не переходить на английский в объяснениях кода, комментариях или описаниях.

## Проект
Разработка Zapret Manager для Ubuntu/Debian Server на основе технического задания в `/docs/zapret-manager-linux-tz.md` и существующей OpenWrt-версии в `/examples/Zapret-Manager-main/`.

### Целевое состояние
- Полнофункциональный shell-менеджер для управления zapret на Linux
- Модульная архитектура (config/, lib/, systemd/)
- Управление стратегиями, hosts, тестирование, backup/restore
- Поддержка systemd вместо init.d
- Использование apt вместо opkg

## Рекомендуемый порядок реализации (из спеца)
1. **Этап 1**: Каркас (zml.sh, config/paths.sh, lib/ui.sh, lib/service.sh, lib/meta.sh)
2. **Этап 2**: Стратегии v1-v9 (lib/strategies_builtin.sh, lib/zapret_config.sh)
3. **Этап 3**: Hosts (config/domains.sh, lib/hosts.sh)
4. **Этап 4**: Discord (lib/discord.sh, lib/strategies_discord.sh)
5. **Этап 5**: Тестирование (lib/tester.sh)
6. **Этап 6**: Flowseal/YouTube/Game стратегии
7. **Этап 7**: Диагностика (lib/offload_diag.sh)

## Требования кода
- Все пути в `config/paths.sh` (не захардкодить в логике)
- Префикс функций: `zml_` или понятное имя модуля
- Перед опасными операциями: backup
- Идемпотентность: повторный запуск не создаёт дубли
- Меню: return по Enter
- Bash syntax check: `bash -n`
- Без eval для параметров стратегий
- Маркеры для всех блоков в files (для безопасного удаления)

## Запреты
- Не переписывать проект целиком без необходимости
- Не использовать uci, opkg, apk, OpenWRT зависимости
- Не использовать `curl | sh`
- Не исполнять скачанные .bat файлы
- Не очищать /etc/hosts без backup
- Не автоматически отключать NIC offloads

## Проверка после изменений
```bash
bash -n zml.sh
find lib config -name '*.sh' -print0 | xargs -0 -n1 bash -n
shellcheck zml.sh lib/*.sh config/*.sh  # если установлен
```

## Definition of Done для модуля
1. bash -n без ошибок
2. Нет критичных shellcheck ошибок
3. Все функции с префиксом zml_
4. Пути не захардкодены (если есть config/paths.sh)
5. Ошибки не игнорируются молча
6. Опасные операции делают backup
7. Повторный запуск не создаёт дубли
8. Меню корректно возвращается по Enter
