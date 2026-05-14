# Архитектура Zapret Manager Linux

**Дата:** 2026-05-14  
**Статус:** Approved  
**Версия:** 1.0  

---

## 1. Обзор

Zapret Manager Linux — модульный менеджер для управления DPI-bypass инструментом `zapret` на серверах Ubuntu/Debian. Позволяет выбирать и комбинировать стратегии, тестировать их, управлять hosts и выполнять диагностику.

**Целевая платформа:**
- Debian 11+, 12+
- Ubuntu Server 20.04+, 22.04+, 24.04+
- Режим работы: local-only (gateway режим зарезервирован на будущее)
- Управление: SSH только (веб-интерфейс не требуется)

**Источники требований:**
- `/docs/zapret-manager-linux-tz.md` — техническое задание
- `/examples/Zapret-Manager-main/` — OpenWrt версия для справки
- Ограничение времени: нужен полный функционал быстро

---

## 2. Общая архитектура

### 2.1 Структура проекта

```
zapret-manager-linux/
├── zml.sh                          # Точка входа, главное меню
├── CLAUDE.md                        # Инструкции для разработки
├── config/
│   ├── paths.sh                     # Все пути (переиспользуемые везде)
│   ├── defaults.sh                  # Дефолтные значения
│   └── domains.sh                   # Группы доменов для hosts
├── lib/
│   ├── ui.sh                        # Меню, вывод, диалоги
│   ├── os.sh                        # Проверка OS, зависимостей
│   ├── service.sh                   # systemctl start/stop/restart
│   ├── meta.sh                      # Работа с current.meta
│   ├── zapret_config.sh             # Генерация конфига, применение
│   ├── strategies_builtin.sh        # v1-v9 стратегии
│   ├── strategies_flowseal.sh       # Flowseal импорт
│   ├── strategies_youtube.sh        # YouTube стратегии
│   ├── strategies_game.sh           # Game стратегии
│   ├── strategies_discord.sh        # Discord стратегии
│   ├── discord.sh                   # Discord скрипты + Finland IPs
│   ├── hosts.sh                     # Управление hosts
│   ├── tester.sh                    # Тестирование стратегий
│   ├── backup.sh                    # Backup/restore
│   ├── installer.sh                 # Установка zapret и зависимостей
│   ├── offload_diag.sh              # Диагностика
│   └── logger.sh                    # Логирование
├── systemd/
│   └── zapret-manager-update.service # (опционально)
└── var/examples/                    # Примеры конфигов
```

### 2.2 Жизненный цикл запуска

```
zml.sh (от root)
  ↓
config/paths.sh + config/defaults.sh
  ↓
lib/* (загрузить все модули)
  ↓
check_os() + check_root()
  ↓
check_dependencies() + check_zapret_installed()
  ↓
ensure_meta_defaults() (create current.meta if needed)
  ↓
show_main_menu() ← цикл до выхода
```

---

## 3. Файлы состояния

### 3.1 `/etc/zapret-manager/current.meta`

Состояние конфигурации в формате KEY=VALUE. Создаётся автоматически при первом запуске.

**Пример содержимого:**
```ini
MODE=local
MAIN_STRATEGY=v7
FLOWSEAL_STRATEGY=
YOUTUBE_STRATEGY=Yv03
GAME_STRATEGY=Gv1
DISCORD_STRATEGY=Dv1
DISCORD_SCRIPT=50-stun4all
RKN_BYPASS=0
WSSIZE_BLOCK=0
METHODEOL_BLOCK=0
DISCORD_FINLAND_IPS=1
HOSTS_GROUPS_ADDED=1
LAST_TEST_V=v7
LAST_TEST_FLOWSEAL=
LAST_TEST_DOMAIN=youtube.com
```

**Правила:**
- Отсутствующие ключи дополняются дефолтами из `config/defaults.sh`
- Изменения только через функции `get_meta()` и `set_meta()` (lib/meta.sh)
- Никакой парсинг напрямую из конфига zapret

### 3.2 `/etc/zapret-manager/current.strategy`

Активная стратегия в виде параметров `nfqws` с маркерами блоков.

**Пример:**
```
#v7
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake,multisplit
--dpi-desync-split-pos=2,sld
--dpi-desync-fake-tls=0x0F0F0F0F
...

#Yv03
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
...

#Dv1
--filter-udp=19294-19344
...

#Gv1
--filter-udp=1024-65535
...
```

**Правила:**
- Каждый блок имеет маркер: `#v7`, `#Yv03`, `#Dv1`, `#Gv1`, `#ZML_WSSIZE_BEGIN/END`, `#ZML_METHODEOL_BEGIN/END`
- Основная стратегия (v1-v9 или Flowseal) — ровно одна, маркер `#v7` или `#FS_*`
- YouTube, Game, Discord — опциональны, не конфликтуют
- При выборе новой YouTube/Game/Discord — заменяется её блок целиком
- Применяется через `zml_apply_strategy()` → копируется в zapret конфиг → `systemctl restart zapret`

### 3.3 Директория backup

```
/etc/zapret-manager/backup/
├── hosts.20260514-143025              # Дата-время в формате YYYYMMDD-HHMMSS
├── current.strategy.20260514-143025
├── current.meta.20260514-143025
└── full.20260514-143025.tar.gz        # Полный архив
```

**Правила:**
- Backup создаётся **перед любым опасным изменением** (hosts, стратегия, meta)
- Restore проверяет существование файла и применяет его
- После restore стратегии — `zml_apply_strategy()`
- После restore hosts — `reload_dns_cache()`

### 3.4 Директория логирования

```
/var/log/zapret-manager.log     # Все операции: старт, выбор стратегии, apply, ошибки
```

Логируется через `log_info()`, `log_warn()`, `log_error()` (lib/logger.sh).

---

## 4. Система стратегий

### 4.1 Основные стратегии (v1-v9)

**Модуль:** `lib/strategies_builtin.sh`

Каждая стратегия — функция, возвращающая строку параметров nfqws:

```bash
strategy_v1() { echo "--filter-tcp=443 --hostlist-exclude=... --dpi-desync=split2 ..."; }
strategy_v2() { echo "--filter-tcp=443 --hostlist-exclude=... --dpi-desync=fake,fakeddisorder ..."; }
# ... v3 до v9
```

**Операции:**
- `select_builtin_strategy()` — меню выбора v1-v9
- `install_builtin_strategy V` — установить выбранную (запись в current.strategy с маркером, update META, apply)

### 4.2 Flowseal стратегии

**Модуль:** `lib/strategies_flowseal.sh`

Импорт стратегий из внешних источников (GitHub Flowseal).

**Процесс:**
1. `update_flowseal_sources()` — скачать `.bat` файлы с Flowseal
2. `parse_flowseal_strategies()` — извлечь параметры nfqws, нормализовать пути
3. `list_flowseal_strategies()` — показать доступные
4. `install_flowseal_strategy NAME` — установить как основную стратегию

**Правила:**
- Сохранять нормализованные стратегии в `/var/lib/zapret-manager/flowseal/`
- Не сохранять `.bat` как исполняемые
- Заменять Windows-пути на Linux-пути (`/opt/zapret/...`)
- Маркер в current.strategy: `#FS_<name>` или `#<flowseal_id>`

### 4.3 YouTube стратегии

**Модуль:** `lib/strategies_youtube.sh`

Отдельные стратегии для YouTube (Yv01, Yv02, Yv03).

**Операции:**
- `strategy_yv01()`, `strategy_yv02()`, `strategy_yv03()` — функции
- `select_youtube_strategy()` — меню
- `install_youtube_strategy Y` — добавить блок `#YvXX` в current.strategy
- `remove_youtube_strategy_block()` — удалить старый блок `#YvXX`

**Правила:**
- YouTube стратегия не заменяет основную, а дополняет
- При выборе новой YouTube — удалить старый блок `#YvXX`, добавить новый
- `YOUTUBE_STRATEGY` в current.meta содержит текущую (Yv01, Yv02, Yv03 или пусто)

### 4.4 Game стратегии

**Модуль:** `lib/strategies_game.sh`

Стратегии для игр (Gv1).

**Операции:**
- `strategy_gv1()` — функция
- `select_game_strategy()` — меню
- `install_game_strategy()` — добавить блок `#Gv1`
- `remove_game_strategy_block()` — удалить блок `#Gv1`

**Правила:**
- Не конфликтует с основной стратегией (отдельный UDP портовый диапазон)
- `GAME_STRATEGY` в current.meta

### 4.5 Discord стратегии

**Модуль:** `lib/strategies_discord.sh`

Стратегии для discord.media (Dv1).

**Операции:**
- `strategy_dv1()` — функция
- `select_discord_strategy()` — меню
- `install_discord_strategy()` — добавить блок `#Dv1`
- `remove_discord_strategy_block()` — удалить блок `#Dv1`

**Правила:**
- `DISCORD_STRATEGY` в current.meta
- Отдельный блок в current.strategy

### 4.6 Дополнительные модификаторы

**WSSIZE (--wssize 1:6):**
- Блок между маркерами: `#ZML_WSSIZE_BEGIN` и `#ZML_WSSIZE_END`
- Идемпотентный (повторный запуск не создаёт дубли)
- Toggle функция: `toggle_wssize_block()`

**METHODEOL:**
- Блок между маркерами: `#ZML_METHODEOL_BEGIN` и `#ZML_METHODEOL_END`
- Идемпотентный
- Toggle функция: `toggle_methodeol_block()`

---

## 5. Управление hosts

### 5.1 Доменные группы

**Модуль:** `config/domains.sh`

Каждая группа — массив или ассоциативный массив с:
- `ID` — уникальный идентификатор
- `TITLE` — отображаемое имя
- `MARKER_BEGIN` — маркер начала блока
- `MARKER_END` — маркер конца блока
- `CONTENT` — содержимое (IP и доменов)

**Пример структуры:**
```bash
declare -A DOMAINS_NALOG=(
  [ID]="nalog"
  [TITLE]="nalog.ru"
  [MARKER_BEGIN]="# ZML_HOSTS_NALOG_BEGIN"
  [MARKER_END]="# ZML_HOSTS_NALOG_END"
  [CONTENT]="45.155.204.190 lkfl2.nalog.ru
45.155.204.181 lknpd.nalog.ru"
)
# ... ещё ~10 групп (rutor, ntc.party, Instagram, lib.rus.ec, AI, Twitch, Telegram Web, Spotify, Supercell, githubusercontent)
```

### 5.2 Операции

**Модуль:** `lib/hosts.sh`

- `add_hosts_group ID` — вставить блок в /etc/hosts между маркерами (+ backup)
- `remove_hosts_group ID` — удалить блок (+ backup)
- `list_hosts_groups()` — показать, какие добавлены
- `replace_hosts_geohide()` — заменить весь /etc/hosts на GeoHide (+ backup + проверка)
- `restore_hosts_backup()` — восстановить из backup
- `reload_dns_cache()` — `resolvectl flush-caches` или `systemctl restart systemd-resolved`

**Правила:**
- Всегда backup перед изменением
- Удаление группы удаляет только блок между маркерами, не трогает остальное
- Маркеры защищают от полного стирания /etc/hosts

---

## 6. Тестирование стратегий

**Модуль:** `lib/tester.sh`

### 6.1 Алгоритм теста

```
1. Сохранить текущую стратегию + current.meta
2. Для каждой стратегии в наборе:
   a. Применить стратегию (запись в current.strategy, systemctl restart zapret)
   b. Дождаться инициализации (sleep 2)
   c. Выполнить HTTP проверки (curl -I --max-time 15 https://domain)
   d. Записать результат (OK/FAIL/UNKNOWN)
3. Восстановить исходную стратегию
4. Сохранить результаты в файл
```

### 6.2 Функции

- `test_builtin_strategies()` — тестировать v1-v9
- `test_flowseal_strategies()` — тестировать Flowseal
- `test_all_strategies()` — тестировать v1-v9 + Flowseal
- `test_current_strategy()` — быстрый тест текущей
- `test_domain_strategies()` — тестировать по заданному домену
- `test_youtube_strategies()` — тестировать YouTube стратегии

### 6.3 Результаты

Файлы в `/var/lib/zapret-manager/`:
- `results_versions.txt` — результаты v1-v9
- `results_flowseal.txt` — результаты Flowseal
- `results_youtube.txt` — результаты YouTube
- `results_domain.txt` — результаты по домену
- `results_all.txt` — всё вместе

**Формат:**
```
v1: OK
v2: FAIL (timeout)
v3: FAIL (TLS error)
v4: OK
...
```

---

## 7. Discord интеграция

### 7.1 Скрипты

**Модуль:** `lib/discord.sh`

Установка custom скриптов в `/opt/zapret/init.d/custom.d/`:
- `50-stun4all` — основной STUN для Discord
- `50-quic4all` — QUIC для всех портов
- `50-discord-media` — специфически для discord.media
- `50-discord` — альтернативный Discord скрипт

**Операции:**
- `install_discord_script SCRIPT_NAME` — скачать, установить, `chmod +x`
- `remove_discord_script()` — удалить текущий скрипт
- `list_discord_scripts()` — показать установленные

**Правила:**
- Перед установкой удалить конфликтующие скрипты
- После установки `systemctl restart zapret`

### 7.2 Finland IPs

**Операции в lib/discord.sh:**
- `add_discord_finland_hosts()` — добавить 200 записей finland10000-10199 в /etc/hosts
- `remove_discord_finland_hosts()` — удалить Finland блок
- `toggle_discord_finland_hosts()` — toggle

**Правила:**
- Маркеры: `# ZML_DISCORD_FINLAND_BEGIN` и `# ZML_DISCORD_FINLAND_END`
- Не добавлять дубли
- Backup перед изменением
- Reload DNS кэша после изменения

---

## 8. Installer и зависимости

**Модуль:** `lib/installer.sh`

### 8.1 Проверки

- `check_os()` — Debian/Ubuntu версия
- `check_root()` — запуск от root
- `check_dependencies()` — bash, curl, apt, ca-certificates, grep, sed, gawk, coreutils, iproute2, dnsutils, unzip, jq
- `check_zapret_installed()` — `systemctl status zapret`

### 8.2 Установка

- `install_dependencies()` — `apt install ...`
- `install_or_update_zapret()` — скачать последнюю версию zapret, распаковать

**Правила:**
- Не ломать существующую установку zapret
- Если zapret уже установлен — предложить обновление

---

## 9. Диагностика

**Модуль:** `lib/offload_diag.sh`

**Функции:**
- `check_nft_flowtable()` — `nft list ruleset | grep -i flowtable`
- `check_iptables_flowoffload()` — `iptables-save | grep -i FLOWOFFLOAD`
- `check_nic_offloads()` — `ethtool -k $IFACE` для всех интерфейсов
- `disable_nic_offloads()` — `ethtool -K $IFACE gro off gso off tso off lro off` (с предупреждением)

**Правила:**
- Диагностика read-only (кроме отключения offloads)
- Отключение offloads — только по явному выбору (с предупреждением о снижении производительности)

---

## 10. UI и меню

**Модуль:** `lib/ui.sh`

### 10.1 Главное меню

```
Zapret Manager Linux

Сервис zapret: active/inactive/not installed
Режим: local
Используется стратегия: v7 / Yv03 / Dv1 / Gv1

1) Меню стратегий
2) Меню тестирования стратегий
3) Меню настройки Discord
4) Меню управления доменами в hosts
5) Управление сервисом zapret
6) Backup/restore
7) Диагностика system
8) Установка/обновление зависимостей
Enter) Выход
```

### 10.2 Меню стратегий

```
Меню стратегий

Используется стратегия: v7
Стратегия для YouTube: Yv03
Стратегия для игр: Gv1
Стратегия для Discord: Dv1

1) Выбрать и установить стратегию v1-v9
2) Выбрать и установить стратегию от Flowseal
3) Выбрать и установить стратегию для YouTube
4) Выбрать и установить стратегию для игр
5) Включить / Выключить обход по спискам РКН
6) Обновить список исключений
7) Включить / Выключить блок --wssize 1:6
8) Включить / Выключить блок --methodeol
Enter) Выход в главное меню
```

### 10.3 Меню тестирования

```
Меню тестирования стратегий

1) Тестировать стратегии v
2) Тестировать стратегии Flowseal
3) Тестировать v и Flowseal стратегии
4) Тестировать текущую стратегию
5) Тестировать стратегии по домену
6) Тестировать стратегии для YouTube
7) Показать результаты
8) Удалить результаты
Enter) Выход в главное меню
```

### 10.4 Правила UI

- Текстовый, shell-based интерфейс
- Управление через цифры и Enter
- Enter в подменю возвращает назад
- Критичные операции требуют подтверждение
- Ошибки — понятные сообщения
- Пригоден для запуска по SSH

---

## 11. Безопасность и обработка ошибок

### 11.1 Требования

- Все системные операции только от root
- Перед любым опасным изменением (hosts, стратегия) — backup
- Временные файлы через `mktemp`
- Скачанные файлы проверяются на непустоту
- Никаких `curl | sh` прямо
- Скачанные .bat файлы не запускаются
- Никакого `eval` для параметров стратегий
- Валидация пользовательского ввода (домены, пути)

### 11.2 Валидация домена

Функция `is_valid_domain()` (lib/meta.sh или общий модуль):

**Допустимо:**
- `example.com`, `sub.example.com`, `xn--example.com`

**Запрещено:**
- Пробелы, слеши, shell metacharacters: `; | & $ ` < >`

---

## 12. Логирование

**Модуль:** `lib/logger.sh`

**Функции:**
- `log_info MESSAGE` — информационный лог
- `log_warn MESSAGE` — предупреждение
- `log_error MESSAGE` — ошибка

**Логируется:**
- Запуск менеджера
- Выбор и применение стратегии
- Перезапуск сервиса
- Изменения hosts
- Backup/restore операции
- Ошибки загрузки модулей
- Результаты тестов

**Файл:** `/var/log/zapret-manager.log`

---

## 13. Этапы реализации (7-этапный план)

### Этап 1: Каркас проекта
**Модули:** zml.sh, config/paths.sh, config/defaults.sh, lib/ui.sh, lib/os.sh, lib/service.sh, lib/meta.sh, lib/backup.sh

**Результат:**
- Менеджер запускается, проверяет OS и root
- Главное меню работает
- Читает/пишет current.meta
- Показывает статус zapret

### Этап 2: Стратегии v1-v9
**Модули:** lib/strategies_builtin.sh, lib/zapret_config.sh, lib/installer.sh

**Результат:**
- Выбор v1-v9
- Запись в current.strategy
- Применение через systemd
- MAIN_STRATEGY обновляется

### Этап 3: Hosts
**Модули:** config/domains.sh, lib/hosts.sh

**Результат:**
- Добавление/удаление групп
- Маркеры работают
- Backup/restore

### Этап 4: Discord
**Модули:** lib/discord.sh, lib/strategies_discord.sh

**Результат:**
- Установка/удаление Discord скриптов
- Finland IPs toggle
- Discord стратегия (Dv1)

### Этап 5: Тестирование
**Модули:** lib/tester.sh

**Результат:**
- Тестирование v1-v9
- Тестирование текущей стратегии
- Результаты в файлы

### Этап 6: Flowseal / YouTube / Game
**Модули:** lib/strategies_flowseal.sh, lib/strategies_youtube.sh, lib/strategies_game.sh

**Результат:**
- Flowseal импорт
- YouTube/Game как отдельные блоки

### Этап 7: Диагностика и логирование
**Модули:** lib/offload_diag.sh, lib/logger.sh

**Результат:**
- Диагностика nft/iptables/offloads
- Полное логирование

---

## 14. Definition of Done

### На уровне модуля
1. `bash -n` без ошибок
2. Нет критичных shellcheck ошибок
3. Все функции с префиксом `zml_` или модулей имя
4. Пути из config/paths.sh, не захардкодены
5. Ошибки не игнорируются молча
6. Опасные операции делают backup
7. Повторный запуск не создаёт дубли (идемпотентность)
8. Меню return по Enter

### На уровне проекта
1. Запускается на чистом Ubuntu/Debian Server
2. Без OpenWRT зависимостей
3. Применяет стратегии через systemd
4. Управляет hosts-группами
5. Делает backup/restore
6. Не ломает zapret при ошибке
7. Все изменения обратимы

---

## 15. Примечания по реализации

1. Все стратегии отделены от UI (в функциях, не в меню)
2. UI не содержит длинные блоки параметров nfqws
3. Hosts-группы в config/domains.sh (данные)
4. Сервисные операции только в lib/service.sh
5. Работа с /etc/hosts только в lib/hosts.sh
6. Работа с current.meta только в lib/meta.sh
7. Работа со стратегией только через lib/zapret_config.sh
8. Любая системная функция возвращает код ошибки
9. Любая загрузка из интернета атомарна (temp файл → mv)
10. Все блоки в стратегии/hosts имеют маркеры для безопасного удаления

---

## 16. Техническая справка

### Пути по умолчанию (config/paths.sh)

```bash
ZML_DIR="/etc/zapret-manager"
ZML_STATE_DIR="/var/lib/zapret-manager"
ZML_BACKUP_DIR="/etc/zapret-manager/backup"
ZAPRET_DIR="/opt/zapret"
ZAPRET_CONFIG_DIR="/opt/zapret/config"
ZAPRET_IPSET_DIR="/opt/zapret/ipset"
ZAPRET_FAKE_DIR="/opt/zapret/files/fake"
ZAPRET_CUSTOM_DIR="/opt/zapret/init.d/custom.d"
STRATEGY_FILE="/etc/zapret-manager/current.strategy"
META_FILE="/etc/zapret-manager/current.meta"
HOSTS_FILE="/etc/hosts"
LOG_FILE="/var/log/zapret-manager.log"
```

### Дефолтные значения (config/defaults.sh)

```bash
DEFAULT_MAIN_STRATEGY="v7"
DEFAULT_MODE="local"
DEFAULT_RKN_BYPASS=0
DEFAULT_WSSIZE_BLOCK=0
DEFAULT_METHODEOL_BLOCK=0
DEFAULT_DISCORD_FINLAND_IPS=0
DEFAULT_DISCORD_SCRIPT=""
DEFAULT_HOSTS_GROUPS_ADDED=0
```

---

## 17. Заключение

Архитектура Zapret Manager Linux спроектирована как:
- **Модульная** — каждый модуль с одной ответственностью
- **Безопасная** — backup перед опасными операциями, маркеры для защиты
- **Расширяемая** — легко добавить новые стратегии или hosts-группы
- **Идемпотентная** — безопасно запускать повторно
- **Тестируемая** — каждый модуль тестируется отдельно
- **Linux-native** — systemd, apt, без OpenWrt зависимостей
- **Быстрая в реализации** — 7 этапов можно делать параллельно

Все 7 этапов реализуют полный функционал управления zapret, стратегиями, hosts, Discord, YouTube, Game, тестированием и диагностикой.
