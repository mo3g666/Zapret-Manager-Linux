# Инструкция по тестированию переключения стратегий

## Проблема, которая была исправлена

**Ошибка:** "стратегия не переключается" (strategy not switching)

**Корневая причина:** `/opt/zapret2/config` это **ФАЙЛ**, а не директория. Предыдущий код пытался писать в `/opt/zapret2/config/config` (как в поддиректорию), что вызывало ошибку.

**Что было исправлено:**
- `zml_apply_strategy()` теперь копирует конфигурацию прямо в файл `/opt/zapret2/config`
- `ensure_zapret_dirs()` больше не создаёт `/opt/zapret2/config` как директорию
- `lib/debug.sh` корректно отображает `/opt/zapret2/config` как файл

## Быстрый тест (на сервере)

### 1. Загруженный новый код
```bash
# Скачиваем обновление
curl -fsSL https://raw.githubusercontent.com/mo3g666/Zapret-Manager-Linux/main/install.sh | sudo bash
```

### 2. Проверяем статус zapret2
```bash
systemctl status zapret2
```

Должна быть строка: `Active: active (running)`

### 3. Запускаем тест переключения стратегий
```bash
sudo bash /opt/zapret-manager/test_strategy_switching.sh
```

**Ожидаемый результат:**
```
✓ УСПЕХ: Переключение стратегии работает корректно!
```

## Подробный тест через меню

### 1. Запускаем zml
```bash
zml
```

### 2. Выбираем опцию 1: "Меню стратегий"

### 3. Выбираем опцию 1: "Выбрать и установить стратегию v1-v9"

### 4. Выбираем одну из стратегий (например, v7)

**Что должно произойти:**
- Консоль покажет: "Стратегия v7 установлена"
- После паузы вернёмся в меню

### 5. Проверяем результат

В главном меню под "Основная стратегия" должна показаться "v7"

## Диагностика с помощью встроенного инструмента

### 1. В главном меню zml выбираем опцию 9: "Диагностика стратегий"

### 2. Выбираем опцию 1: "Показать все файлы стратегий"

**Должны увидеть:**

```
📄 STRATEGY_FILE: /etc/zapret-manager/current.strategy
   Размер: XXXX байт (XX строк)
   Содержимое:
   #v7
   --filter-tcp=443
   ...параметры стратегии...
```

```
📄 Конфиг zapret2: /opt/zapret2/config
   Размер: XXXX байт
   Первые 10 строк:
   --filter-tcp=443
   ...параметры стратегии...
```

Если содержимое STRATEGY_FILE совпадает с /opt/zapret2/config - **всё работает правильно**.

## Что проверяем

### Файл стратегии (`/etc/zapret-manager/current.strategy`)
```bash
# Проверяем что файл существует
ls -l /etc/zapret-manager/current.strategy

# Проверяем размер
wc -l /etc/zapret-manager/current.strategy

# Показываем содержимое
cat /etc/zapret-manager/current.strategy
```

### Файл конфига zapret2 (`/opt/zapret2/config`)
```bash
# Проверяем что файл существует (это файл, не директория!)
file /opt/zapret2/config

# Показываем первые параметры
head -10 /opt/zapret2/config

# Проверяем что это не директория
ls -la /opt/zapret2/config/  # это должно вернуть ошибку!
```

### Метаданные (текущая выбранная стратегия)
```bash
# Посмотреть текущую стратегию
grep "MAIN_STRATEGY" /etc/zapret-manager/current.meta

# Посмотреть все метаданные
cat /etc/zapret-manager/current.meta
```

### Статус сервиса
```bash
# Проверяем что сервис запущен
systemctl status zapret2

# Проверяем что он перезагрузился (смотрим время в Status)
systemctl status zapret2 | grep "Active"
```

## Ожидаемые пути

```
/etc/zapret-manager/
├── current.strategy        ← Файл с параметрами текущей стратегии
├── current.meta           ← Файл с метаданными (какая стратегия выбрана)
└── ...другие файлы...

/opt/zapret2/
├── config                 ← ФАЙЛ (не директория!) с параметрами для запуска
├── nftables.conf
├── install_easy.sh
└── ...другие файлы...

/opt/zapret-manager/
├── zml.sh
├── config/
├── lib/
└── test_strategy_switching.sh  ← Скрипт для автоматического тестирования
```

## Если тест не пройден

### Проблема: "/opt/zapret2/config это директория"
```
cat: /opt/zapret2/config/config: Not a directory
```

**Решение:**
- Переустановите zapret2: `zml` → опция 8 → "Установить zapret (последняя версия)"
- Или вручную: `sudo rm -rf /opt/zapret2 && sudo systemctl stop zapret2`

### Проблема: "zapret2 сервис не запущен"
```bash
sudo systemctl start zapret2
sudo systemctl enable zapret2
```

### Проблема: "STRATEGY_FILE не создан"
```bash
# Проверяем директории
ls -la /etc/zapret-manager/

# Инициализируем директории
sudo mkdir -p /etc/zapret-manager /var/lib/zapret-manager /var/log

# Пробуем выбрать стратегию заново
zml
```

## Логирование

Все операции логируются в `/var/log/zapret-manager.log`:

```bash
# Показываем последние операции
tail -50 /var/log/zapret-manager.log

# Показываем только ошибки
grep "ERROR" /var/log/zapret-manager.log

# Отслеживаем применение стратегии в реальном времени
tail -f /var/log/zapret-manager.log
```

## Если нужна помощь

1. Запустите тест: `sudo bash /opt/zapret-manager/test_strategy_switching.sh`
2. Запустите диагностику: `zml` → опция 9 → опция 1
3. Скопируйте логи:
   ```bash
   tail -100 /var/log/zapret-manager.log
   ```
