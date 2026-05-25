# Zapret Manager Linux

Менеджер для управления Zapret на Linux (Debian/Ubuntu).

## Установка

### Одна команда

```bash
curl -fsSL https://raw.githubusercontent.com/mo3g666/Zapret-Manager-Linux/main/install.sh | sudo bash
```

Или с wget:

```bash
sh <(wget -O - https://raw.githubusercontent.com/mo3g666/Zapret-Manager-Linux/main/install.sh)
```

### Вручную

```bash
git clone https://github.com/mo3g666/Zapret-Manager-Linux.git
cd zapret-manager-linux
sudo bash install.sh
```

## Использование

После установки:

```bash
zml
# или
zms
```

## Требования

- Debian 11+ или Ubuntu 20.04+
- root или sudo доступ
- bash, curl, sed, grep, jq, systemctl, apt-get

## Возможности

- ✅ Управление стратегиями zapret (v1-v9)
- ✅ YouTube стратегии (YV01-YV03)
- ✅ Game стратегия (Gv1)
- ✅ Discord интеграция (Dv1, скрипты, Finland IPs)
- ✅ Управление доменами в /etc/hosts (11 групп)
- ✅ Тестирование стратегий
- ✅ Backup/restore конфигураций
- ✅ Диагностика offload параметров
- ✅ Установка zapret2 из GitHub

## Структура проекта

```
zml/
├── zml.sh                 # Главный скрипт
├── config/
│   ├── paths.sh          # Пути системы
│   ├── defaults.sh       # Дефолтные значения
│   └── domains.sh        # Группы доменов
├── lib/
│   ├── installer.sh      # Установка zapret2
│   ├── service.sh        # Управление сервисом
│   ├── strategies_*.sh   # Стратегии различных типов
│   ├── hosts.sh          # Управление hosts
│   ├── backup.sh         # Backup/restore
│   ├── tester.sh         # Тестирование
│   ├── discord.sh        # Discord интеграция
│   ├── offload_diag.sh   # Диагностика
│   └── [другие модули]
└── install.sh            # Скрипт установки

```

---

**Статус**: Готов к использованию  
**Обновлено**: 2026-05-25  
**Версия**: 1.0
