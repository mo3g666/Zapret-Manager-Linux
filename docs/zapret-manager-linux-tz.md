# Техническое задание: Zapret Manager Linux для Ubuntu/Debian Server

## 1. Назначение проекта

Разработать отдельный shell-менеджер для управления `zapret` на Ubuntu/Debian Server.

Проект не должен быть прямым портом OpenWRT-версии. Нужно создать самостоятельную Linux-версию, использующую:

- `bash`;
- `systemd`;
- обычные конфигурационные файлы;
- `/etc/hosts`;
- `apt`;
- `curl/wget`;
- `nftables/iptables` при необходимости;
- установленный Linux-вариант `zapret`.

Основная цель — дать пользователю меню для выбора, применения, тестирования и комбинирования стратегий `zapret`, а также для управления Discord-скриптами и доменными группами в `/etc/hosts`.

---

## 2. Целевая платформа

Поддерживаемые ОС:

- Debian 11+;
- Debian 12+;
- Ubuntu Server 20.04+;
- Ubuntu Server 22.04+;
- Ubuntu Server 24.04+.

Минимальные требования:

- root-доступ;
- `systemd`;
- `bash`;
- доступ к интернету для загрузки списков, стратегий и зависимостей;
- установленный или устанавливаемый `zapret`.

Поддерживаемые режимы работы:

```text
local   — zapret применяется только к трафику самого сервера;
gateway — сервер является шлюзом для клиентов LAN.
```

В MVP допускается реализовать только `local`-режим, но архитектура должна предусматривать `gateway`-режим.

---

## 3. Что не переносить из OpenWRT-версии

Запрещено тащить в Linux-версию OpenWRT-специфичные механизмы:

```text
opkg
apk
.ipk/.apk packages
uci
/etc/config/*
/etc/init.d/*
fw4
LuCI
OpenWRT firewall config
OpenWRT flow offloading fix
OpenWRT model/arch detection
OpenWRT dnsmasq restart logic as единственный вариант
Podkop/OpenWRT AWG-интеграции
```

Linux-версия должна использовать собственный слой абстракции:

```text
меню → state/config files → генератор конфига zapret → systemctl restart zapret
```

---

## 4. Рекомендуемая структура проекта

```text
zapret-manager-linux/
├── zml.sh
├── README.md
├── LICENSE
├── config/
│   ├── defaults.sh
│   ├── paths.sh
│   └── domains.sh
├── lib/
│   ├── backup.sh
│   ├── discord.sh
│   ├── hosts.sh
│   ├── installer.sh
│   ├── meta.sh
│   ├── offload_diag.sh
│   ├── os.sh
│   ├── service.sh
│   ├── strategies_builtin.sh
│   ├── strategies_discord.sh
│   ├── strategies_flowseal.sh
│   ├── strategies_game.sh
│   ├── strategies_youtube.sh
│   ├── tester.sh
│   ├── ui.sh
│   └── zapret_config.sh
├── systemd/
│   └── zapret-manager-update.service
└── var/
    └── examples/
```

Главный исполняемый файл:

```text
zml.sh
```

Он должен:

- проверять root-доступ;
- загружать модули из `config/` и `lib/`;
- проверять зависимости;
- показывать главное меню;
- вызывать подменю.

---

## 5. Основные пути

Все пути должны быть вынесены в `config/paths.sh`.

```sh
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
```

Пути должны быть изменяемыми через конфиг.

---

## 6. Файлы состояния

### 6.1. `/etc/zapret-manager/current.meta`

Файл хранит состояние для отображения в меню.

Пример:

```ini
MODE=local
MAIN_STRATEGY=v7
FLOWSEAL_STRATEGY=
YOUTUBE_STRATEGY=Yv03
DISCORD_STRATEGY=Dv1
GAME_STRATEGY=Gv1
RKN_BYPASS=0
WSSIZE_BLOCK=0
METHODEOL_BLOCK=0
DISCORD_SCRIPT=50-stun4all
DISCORD_FINLAND_IPS=1
HOSTS_GROUPS_ADDED=1
LAST_TEST_V=v
LAST_TEST_FLOWSEAL=Flowseal
LAST_TEST_DOMAIN=Domain
```

Требования:

- файл должен создаваться автоматически при первом запуске;
- отсутствующие ключи должны дополняться дефолтами;
- изменение значений должно выполняться через функции `get_meta` и `set_meta`;
- нельзя парсить меню напрямую из активного `nfqws`-конфига.

### 6.2. `/etc/zapret-manager/current.strategy`

Файл хранит активную стратегию в формате параметров `nfqws`.

Пример:

```text
#v7
--filter-tcp=443
--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt
--dpi-desync=fake,multisplit
--dpi-desync-split-pos=2,sld
--dpi-desync-fooling=badseq,badsum
--dpi-desync-repeats=8
--new
#Yv03
--filter-tcp=443
--hostlist=/opt/zapret/ipset/zapret-hosts-google.txt
--dpi-desync=fake,multisplit
--dpi-desync-split-pos=1
```

Требования:

- каждая стратегия должна иметь маркер: `#v7`, `#Yv03`, `#Dv1`, `#Gv1`;
- дополнительные блоки должны иметь маркеры;
- файл должен применяться через генератор конфига zapret;
- после применения нужен `systemctl restart zapret`.

---

## 7. Управление сервисом

Модуль: `lib/service.sh`.

Обязательные функции:

```sh
zml_start_zapret()
zml_stop_zapret()
zml_restart_zapret()
zml_status_zapret()
zml_is_zapret_active()
```

Реализация:

```sh
systemctl start zapret
systemctl stop zapret
systemctl restart zapret
systemctl status zapret
systemctl is-active --quiet zapret
```

Требования:

- не использовать `/etc/init.d/zapret`;
- перед restart проверять наличие сервиса;
- при ошибке выводить понятное сообщение;
- не скрывать stderr полностью, если пользователь запускает debug-режим.

---

## 8. Генерация и применение стратегии

Модуль: `lib/zapret_config.sh`.

Основная функция:

```sh
zml_apply_strategy()
```

Она должна:

1. проверить наличие `STRATEGY_FILE`;
2. создать нужные директории;
3. сгенерировать рабочий конфиг для Linux-версии `zapret`;
4. перезапустить сервис `zapret`;
5. обновить состояние в `current.meta`.

Пример упрощённой реализации:

```sh
zml_apply_strategy() {
  install -d "$ZML_DIR" "$ZAPRET_CONFIG_DIR"
  cp "$STRATEGY_FILE" "$ZAPRET_CONFIG_DIR/nfqws.strategy"
  zml_restart_zapret
}
```

Фактический путь назначения должен зависеть от структуры установленного `zapret`.

---

## 9. Главное меню

Главное меню должно содержать минимум:

```text
Zapret Manager Linux

Сервис zapret: active/inactive/not installed
Режим: local/gateway
Используется стратегия: v7 / Yv03 / Dv1
Стратегия для игр: Gv1

1) Меню стратегий
2) Меню тестирования стратегий
3) Меню настройки Discord
4) Меню управления доменами в hosts
5) Управление сервисом zapret
6) Backup/restore
7) Диагностика системы
8) Установка/обновление зависимостей
Enter) Выход
```

---

## 10. Меню стратегий

Меню должно соответствовать оригинальной логике OpenWRT-менеджера.

```text
Меню стратегий

Используется стратегия: v7 / Yv03 / Dv1
Стратегия для игр: Gv1

1) Выбрать и установить стратегию v1-v9
2) Выбрать и установить стратегию от Flowseal
3) Выбрать и установить стратегию для YouTube
4) Выбрать и установить стратегию для игр
5) Включить обход по спискам РКН
6) Обновить список исключений
7) Добавить в стратегию блок с --wssize 1:6
8) Добавить в стратегию блок с --methodeol
Enter) Выход в главное меню
```

### 10.1. Стратегии v1-v9

Модуль: `lib/strategies_builtin.sh`.

Обязательные функции:

```sh
strategy_v1()
strategy_v2()
strategy_v3()
strategy_v4()
strategy_v5()
strategy_v6()
strategy_v7()
strategy_v8()
strategy_v9()
select_builtin_strategy()
install_builtin_strategy()
```

Требования:

- стратегии должны возвращать только параметры `nfqws`;
- не использовать `uci`;
- не писать напрямую в `/etc/config/zapret`;
- выбор стратегии должен обновлять `MAIN_STRATEGY`;
- после выбора должен выполняться `zml_apply_strategy`.

### 10.2. Flowseal-стратегии

Модуль: `lib/strategies_flowseal.sh`.

Нужно реализовать:

```sh
update_flowseal_sources()
parse_flowseal_strategies()
list_flowseal_strategies()
install_flowseal_strategy()
```

Логика:

1. скачать актуальные стратегии Flowseal;
2. извлечь параметры из `.bat`/конфигов;
3. заменить Windows-пути на Linux-пути;
4. сохранить нормализованные стратегии в `/var/lib/zapret-manager/flowseal/`;
5. дать выбрать стратегию;
6. установить выбранную стратегию как основную или как отдельный блок;
7. обновить `FLOWSEAL_STRATEGY`.

Требования:

- не использовать Windows-команды;
- не сохранять `.bat` как исполняемые скрипты;
- извлекать только параметры `nfqws`;
- нормализовать пути к fake-файлам и hostlist.

### 10.3. YouTube-стратегии

Модуль: `lib/strategies_youtube.sh`.

Нужно реализовать:

```sh
strategy_yv01()
strategy_yv02()
strategy_yv03()
select_youtube_strategy()
install_youtube_strategy()
remove_youtube_strategy_block()
```

Требования:

- YouTube-стратегия должна быть отдельным блоком с маркером `#YvXX`;
- при выборе новой YouTube-стратегии старый `#YvXX`-блок должен удаляться;
- `YOUTUBE_STRATEGY` должен обновляться в `current.meta`.

### 10.4. Игровые стратегии

Модуль: `lib/strategies_game.sh`.

Нужно реализовать:

```sh
strategy_gv1()
select_game_strategy()
install_game_strategy()
remove_game_strategy_block()
```

Требования:

- игровая стратегия должна быть отдельным блоком с маркером `#GvX`;
- стратегия не должна ломать основную стратегию;
- `GAME_STRATEGY` должен обновляться в `current.meta`.

### 10.5. РКН-режим

Нужно реализовать переключатель:

```sh
toggle_rkn_bypass()
```

Логика:

- обычный режим использует `--hostlist-exclude=/opt/zapret/ipset/zapret-hosts-user-exclude.txt`;
- РКН-режим использует `--hostlist=/opt/zapret/ipset/zapret-hosts-user.txt`;
- состояние хранится в `RKN_BYPASS`.

### 10.6. Обновление списка исключений

Нужно реализовать:

```sh
update_exclude_list()
```

Файл назначения:

```text
/opt/zapret/ipset/zapret-hosts-user-exclude.txt
```

Требования:

- перед обновлением делать backup старого списка;
- скачивать список атомарно: сначала во временный файл, затем `mv`;
- при ошибке не портить существующий файл.

### 10.7. Блок `--wssize 1:6`

Нужно реализовать:

```sh
add_wssize_block()
remove_wssize_block()
toggle_wssize_block()
```

Блок должен быть идемпотентным и иметь маркеры:

```text
#ZML_WSSIZE_BEGIN
--new
--filter-tcp=443
--wssize 1:6
#ZML_WSSIZE_END
```

### 10.8. Блок `--methodeol`

Нужно реализовать:

```sh
add_methodeol_block()
remove_methodeol_block()
toggle_methodeol_block()
```

Блок должен быть идемпотентным и иметь маркеры:

```text
#ZML_METHODEOL_BEGIN
--new
--filter-tcp=80,443
--methodeol
#ZML_METHODEOL_END
```

---

## 11. Меню тестирования стратегий

Меню:

```text
Меню тестирования стратегий

Используется стратегия: v7 / Yv03 / Dv1
Тест пройден: v | Flowseal | Domain

1) Тестировать стратегии v
2) Тестировать стратегии Flowseal
3) Тестировать v и Flowseal стратегии
4) Тестировать текущую стратегию
5) Тестировать стратегии по домену
6) Тестировать стратегии для YouTube
Enter) Выход в главное меню
```

Модуль: `lib/tester.sh`.

Обязательные функции:

```sh
test_builtin_strategies()
test_flowseal_strategies()
test_all_strategies()
test_current_strategy()
test_domain_strategies()
test_youtube_strategies()
```

Безопасный алгоритм теста:

1. сохранить текущую стратегию и `current.meta`;
2. применить тестовую стратегию;
3. перезапустить `zapret`;
4. выполнить HTTP(S)-проверки;
5. сохранить результат;
6. перейти к следующей стратегии;
7. восстановить исходную стратегию;
8. перезапустить `zapret`.

Файлы результатов:

```text
/var/lib/zapret-manager/results_versions.txt
/var/lib/zapret-manager/results_flowseal.txt
/var/lib/zapret-manager/results_all.txt
/var/lib/zapret-manager/results_domain.txt
/var/lib/zapret-manager/results_youtube.txt
```

Минимальная проверка доступности:

```sh
curl -I --connect-timeout 5 --max-time 15 https://example.com
```

Для теста по домену пользователь вводит домен, например:

```text
youtube.com
discord.com
rutracker.org
```

Критерии результата:

```text
OK      — curl получил HTTP-код или TLS-соединение успешно установлено;
FAIL    — timeout, reset, TLS error, connection refused;
UNKNOWN — неоднозначная ошибка.
```

---

## 12. Меню Discord

Меню:

```text
Меню настройки Discord

Установлен скрипт: 50-stun4all
Финские IP для Discord: включены
Стратегия для discord.media: Dv1

1) Установить скрипт 50-stun4all
2) Установить скрипт 50-quic4all
3) Установить скрипт 50-discord-media
4) Установить скрипт 50-discord
5) Удалить скрипт
6) Удалить Финские IP из hosts
7) Выбрать и установить стратегию для discord.media
Enter) Выход в главное меню
```

Модуль: `lib/discord.sh` и `lib/strategies_discord.sh`.

### 12.1. Discord custom scripts

Путь установки:

```text
/opt/zapret/init.d/custom.d/
```

Поддерживаемые скрипты:

```text
50-stun4all
50-quic4all
50-discord-media
50-discord
```

Функции:

```sh
install_discord_script()
remove_discord_script()
list_discord_scripts()
```

Требования:

- перед установкой удалять конфликтующий старый Discord-скрипт;
- выставлять `chmod +x`;
- обновлять `DISCORD_SCRIPT`;
- после установки перезапускать `zapret`.

### 12.2. Финские IP для Discord

Нужно реализовать:

```sh
add_discord_finland_hosts()
remove_discord_finland_hosts()
toggle_discord_finland_hosts()
```

Записи должны добавляться в `/etc/hosts` только внутри маркеров:

```text
# ZML_DISCORD_FINLAND_BEGIN
104.25.158.178 finland10000.discord.media
104.25.158.178 finland10001.discord.media
...
104.25.158.178 finland10199.discord.media
# ZML_DISCORD_FINLAND_END
```

Требования:

- не добавлять дубли;
- перед изменением делать backup `/etc/hosts`;
- после изменения сбрасывать DNS-кэш;
- обновлять `DISCORD_FINLAND_IPS`.

### 12.3. Стратегия для `discord.media`

Нужно реализовать:

```sh
strategy_dv1()
select_discord_strategy()
install_discord_strategy()
remove_discord_strategy_block()
```

Требования:

- стратегия должна быть отдельным блоком `#DvX`;
- при выборе новой Discord-стратегии старый `#DvX`-блок должен удаляться;
- состояние хранится в `DISCORD_STRATEGY`.

---

## 13. Меню управления доменами в hosts

Меню:

```text
Меню управления доменами в hosts

Домены в hosts: добавлены

 0) Добавить nalog.ru
 1) Удалить  rutor.info
 2) Удалить  ntc.party
 3) Удалить  Instagram & Facebook
 4) Удалить  lib.rus.ec
 5) Удалить  AI сервисы
 6) Удалить  Twitch
 7) Удалить  Telegram Web
 8) Удалить  Spotify
 9) Удалить  Supercell
10) Удалить  githubusercontent.com
11) Удалить все домены
12) Заменить hosts на GeoHide hosts
13) Восстановить hosts
Enter) Выход в главное меню
```

Модуль: `lib/hosts.sh` и `config/domains.sh`.

### 13.1. Общие требования

- все изменения `/etc/hosts` выполнять только с backup;
- группы должны быть обёрнуты в маркеры;
- удаление группы должно удалять только блок между маркерами;
- нельзя очищать весь `/etc/hosts` без backup;
- после изменений нужно сбрасывать DNS-кэш.

Пример группы:

```text
# ZML_HOSTS_AI_BEGIN
45.155.204.190 chatgpt.com
45.155.204.190 auth.openai.com
45.155.204.190 platform.openai.com
# ZML_HOSTS_AI_END
```

### 13.2. Доменные группы

Нужно реализовать группы:

```text
nalog.ru
rutor.info
ntc.party
Instagram & Facebook
lib.rus.ec
AI сервисы
Twitch
Telegram Web
Spotify
Supercell
githubusercontent.com
```

Каждая группа должна иметь:

```sh
GROUP_ID
GROUP_TITLE
GROUP_MARKER_BEGIN
GROUP_MARKER_END
GROUP_HOSTS_CONTENT
```

### 13.3. GeoHide hosts

Пункт:

```text
12) Заменить hosts на GeoHide hosts
```

Требования:

- перед заменой создать backup текущего `/etc/hosts`;
- скачать GeoHide hosts во временный файл;
- проверить, что файл не пустой;
- проверить наличие минимум одной валидной hosts-строки;
- заменить `/etc/hosts` только после успешной проверки;
- иметь возможность восстановления.

### 13.4. Восстановление hosts

Пункт:

```text
13) Восстановить hosts
```

Требования:

- показать список доступных backup-файлов;
- дать выбрать файл;
- восстановить выбранный backup;
- сбросить DNS-кэш.

### 13.5. Сброс DNS-кэша

Функция:

```sh
reload_dns_cache()
```

Должна поддерживать:

```sh
resolvectl flush-caches
systemctl restart systemd-resolved
systemctl restart dnsmasq
systemctl restart nscd
```

Команды должны выполняться только если соответствующий сервис установлен и активен.

---

## 14. Backup/restore

Модуль: `lib/backup.sh`.

Нужно реализовать:

```sh
backup_hosts()
backup_strategy()
backup_meta()
backup_all()
restore_hosts()
restore_strategy()
restore_meta()
restore_all()
list_backups()
```

Backup-директория:

```text
/etc/zapret-manager/backup/
```

Формат имён:

```text
hosts.YYYYMMDD-HHMMSS
current.strategy.YYYYMMDD-HHMMSS
current.meta.YYYYMMDD-HHMMSS
full.YYYYMMDD-HHMMSS.tar.gz
```

Требования:

- backup должен создаваться перед любым опасным изменением;
- restore должен проверять существование файла;
- после восстановления стратегии должен выполняться `zml_apply_strategy`;
- после восстановления hosts должен выполняться `reload_dns_cache`.

---

## 15. Диагностика offload/fast-path

OpenWRT `FIX Flow Offloading` не переносить.

Вместо него реализовать диагностическое меню:

```text
Диагностика offload/fast-path

1) Проверить nftables flowtable
2) Проверить iptables FLOWOFFLOAD
3) Проверить NIC offloads
4) Отключить NIC offloads для интерфейса
Enter) Назад
```

Модуль: `lib/offload_diag.sh`.

Функции:

```sh
check_nft_flowtable()
check_iptables_flowoffload()
check_nic_offloads()
disable_nic_offloads()
```

Команды:

```sh
nft list ruleset | grep -i flowtable
iptables-save | grep -i FLOWOFFLOAD
ethtool -k "$IFACE"
ethtool -K "$IFACE" gro off gso off tso off lro off
```

Требования:

- отключение NIC offloads должно быть optional;
- перед отключением показать предупреждение о возможном снижении производительности;
- не делать это автоматически.

---

## 16. Установка зависимостей

Модуль: `lib/installer.sh`.

Минимальные зависимости:

```text
bash
curl
wget
ca-certificates
grep
sed
gawk
coreutils
iproute2
dnsutils
unzip
jq
```

Для диагностики:

```text
nftables
iptables
ethtool
```

Для gateway-режима:

```text
nftables
iptables
conntrack
```

Функции:

```sh
check_os()
check_root()
check_dependencies()
install_dependencies()
check_zapret_installed()
install_or_update_zapret()
```

Требования:

- использовать `apt`;
- не использовать `opkg` или `apk`;
- при неподдерживаемой ОС выводить предупреждение;
- не ломать существующую установку `zapret`.

---

## 17. UI и поведение меню

Модуль: `lib/ui.sh`.

Требования:

- интерфейс текстовый, shell-based;
- управление через цифры и Enter;
- Enter в подменю возвращает назад;
- после действий показывать результат;
- критичные операции должны требовать подтверждение;
- ошибки должны быть понятными;
- команды должны быть пригодны для запуска по SSH.

Не использовать:

```text
whiptail/dialog как обязательную зависимость
GUI
web UI
LuCI
```

Допускается позже добавить `dialog` как optional UI.

---

## 18. Безопасность операций

Общие требования:

- все изменения системных файлов только от root;
- перед изменением `/etc/hosts` всегда backup;
- перед заменой стратегии backup текущей стратегии;
- временные файлы создавать через `mktemp`;
- скачанные файлы проверять на непустое содержимое;
- не выполнять удалённые shell-скрипты напрямую через `curl | sh`;
- скачанные Flowseal `.bat` не запускать;
- не использовать `eval` для параметров стратегий;
- пользовательский ввод домена валидировать.

---

## 19. Валидация домена

Для тестирования по домену и hosts-групп нужна функция:

```sh
is_valid_domain()
```

Допустимый формат:

```text
example.com
sub.example.com
xn--example.com
```

Запрещать:

```text
пробелы
слеши
shell metacharacters
; | & $ ` < >
```

---

## 20. Логирование

Лог-файл:

```text
/var/log/zapret-manager.log
```

Нужно логировать:

- запуск менеджера;
- выбор стратегии;
- применение стратегии;
- restart сервиса;
- изменение `/etc/hosts`;
- backup/restore;
- ошибки загрузки;
- результаты тестов.

Функции:

```sh
log_info()
log_warn()
log_error()
```

---

## 21. Критерии готовности MVP

MVP считается готовым, если реализовано:

```text
1. Запуск zml.sh от root.
2. Проверка Ubuntu/Debian.
3. Проверка и установка зависимостей.
4. Проверка наличия zapret service.
5. Главное меню.
6. Меню стратегий.
7. Установка стратегий v1-v9.
8. Состояние current.meta.
9. Активная стратегия current.strategy.
10. Применение стратегии через systemd restart zapret.
11. Меню hosts.
12. Добавление/удаление доменных групп через маркеры.
13. Backup/restore /etc/hosts.
14. Discord menu без полной автоматизации Flowseal.
15. Установка/удаление Discord custom scripts.
16. Тест текущей стратегии.
17. Backup/restore стратегии.
```

---

## 22. Критерии готовности полной версии

Полная версия считается готовой, если дополнительно реализовано:

```text
1. Flowseal strategy import.
2. YouTube strategies YvXX.
3. Discord strategies DvX.
4. Game strategies GvX.
5. Тестирование v-стратегий.
6. Тестирование Flowseal-стратегий.
7. Тестирование YouTube-стратегий.
8. Тестирование по домену.
9. GeoHide hosts replacement.
10. Диагностика offload/fast-path.
11. Gateway-mode preparation.
12. Логирование.
13. Идемпотентность всех операций.
14. Обработка ошибок загрузки и restore.
```

---

## 23. Рекомендуемый порядок реализации для AI-агента

### Этап 1. Каркас проекта

Создать:

```text
zml.sh
config/paths.sh
config/defaults.sh
lib/ui.sh
lib/os.sh
lib/service.sh
lib/meta.sh
lib/backup.sh
```

Результат этапа:

- менеджер запускается;
- показывает главное меню;
- читает и пишет `current.meta`;
- умеет показывать статус `zapret`.

### Этап 2. Стратегии v1-v9

Создать:

```text
lib/strategies_builtin.sh
lib/zapret_config.sh
```

Результат этапа:

- можно выбрать `v1-v9`;
- стратегия пишется в `current.strategy`;
- `MAIN_STRATEGY` обновляется;
- `zapret` перезапускается.

### Этап 3. Hosts

Создать:

```text
config/domains.sh
lib/hosts.sh
```

Результат этапа:

- можно добавлять/удалять группы;
- работают маркеры;
- создаётся backup;
- работает restore.

### Этап 4. Discord

Создать:

```text
lib/discord.sh
lib/strategies_discord.sh
```

Результат этапа:

- можно установить один из Discord-скриптов;
- можно удалить Discord-скрипт;
- можно добавить/удалить финские IP;
- можно выбрать `Dv1`.

### Этап 5. Тестирование

Создать:

```text
lib/tester.sh
```

Результат этапа:

- можно тестировать текущую стратегию;
- можно тестировать `v1-v9`;
- результаты сохраняются в `/var/lib/zapret-manager/`.

### Этап 6. Flowseal / YouTube / Game

Создать:

```text
lib/strategies_flowseal.sh
lib/strategies_youtube.sh
lib/strategies_game.sh
```

Результат этапа:

- Flowseal-стратегии импортируются;
- YouTube-стратегии ставятся отдельным блоком;
- Game-стратегии ставятся отдельным блоком.

### Этап 7. Диагностика

Создать:

```text
lib/offload_diag.sh
```

Результат этапа:

- можно проверить `nft flowtable`;
- можно проверить `iptables FLOWOFFLOAD`;
- можно проверить NIC offloads;
- можно вручную отключить NIC offloads.

---

## 24. Формат задач для AI-агента

AI-агент должен работать итеративно.

Для каждой задачи он должен:

1. изменить минимально необходимое количество файлов;
2. не ломать существующие функции;
3. после изменения показать список изменённых файлов;
4. запустить shellcheck, если доступен;
5. проверить синтаксис `bash -n`;
6. описать, как вручную протестировать изменение.

Пример задачи:

```text
Задача: реализовать lib/meta.sh.

Требования:
- создать current.meta при первом запуске;
- добавить функции get_meta, set_meta, ensure_meta_defaults;
- значения хранить в KEY=VALUE;
- не использовать eval;
- покрыть дефолты из config/defaults.sh;
- проверить bash -n.
```

---

## 25. Запреты для AI-агента

AI-агенту запрещено:

```text
переписывать проект целиком без необходимости;
использовать uci;
использовать opkg/apk;
создавать зависимости от OpenWRT;
использовать curl | sh;
исполнять скачанные .bat файлы;
очищать /etc/hosts без backup;
выполнять rm -rf по переменным без проверки;
использовать eval для стратегий;
делать restart сетевых сервисов без необходимости;
включать gateway/NAT без явного выбора пользователя;
автоматически отключать NIC offloads;
```

---

## 26. Definition of Done

Для каждого модуля:

```text
1. bash -n проходит без ошибок.
2. shellcheck не показывает критичных ошибок, если установлен.
3. Все публичные функции имеют единый префикс zml_ или понятное имя модуля.
4. Пути не захардкожены внутри логики, если уже есть config/paths.sh.
5. Ошибки не игнорируются молча.
6. Опасные операции делают backup.
7. Повторный запуск функции не создаёт дубли.
8. Меню корректно возвращается назад по Enter.
```

Для проекта целиком:

```text
1. Менеджер запускается на чистом Debian/Ubuntu Server.
2. Не содержит OpenWRT-зависимостей.
3. Умеет применять стратегии через systemd.
4. Умеет управлять hosts-группами.
5. Умеет делать backup/restore.
6. Не ломает существующий zapret при ошибке.
7. Все изменения обратимы через backup.
```

---

## 27. Начальный набор команд для проверки

```sh
bash -n zml.sh
find lib config -name '*.sh' -print0 | xargs -0 -n1 bash -n
shellcheck zml.sh lib/*.sh config/*.sh
sudo ./zml.sh
systemctl status zapret
```

Проверка hosts:

```sh
sudo cp -a /etc/hosts /tmp/hosts.test.backup
sudo ./zml.sh
cat /etc/hosts
sudo cp -a /tmp/hosts.test.backup /etc/hosts
```

Проверка стратегии:

```sh
sudo ./zml.sh
cat /etc/zapret-manager/current.meta
cat /etc/zapret-manager/current.strategy
systemctl status zapret
```

---

## 28. Примечания по реализации

1. Все стратегии должны быть отделены от UI.
2. UI не должен содержать длинные блоки параметров `nfqws`.
3. Hosts-группы должны храниться в `config/domains.sh`.
4. Сервисные операции должны быть только в `lib/service.sh`.
5. Работа с `/etc/hosts` должна быть только в `lib/hosts.sh`.
6. Работа с `current.meta` должна быть только в `lib/meta.sh`.
7. Работа с активной стратегией должна быть только через `lib/zapret_config.sh`.
8. Любая функция, меняющая систему, должна возвращать код ошибки.
9. Любая загрузка из интернета должна быть атомарной.
10. Все блоки в стратегии и hosts должны иметь маркеры для безопасного удаления.
