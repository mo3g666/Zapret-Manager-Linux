#!/bin/bash
# config/paths.sh — Пути системы

# Основные директории zapret-manager
export ZML_DIR="/etc/zapret-manager"
export ZML_STATE_DIR="/var/lib/zapret-manager"
export ZML_BACKUP_DIR="/etc/zapret-manager/backup"

# Директории zapret
export ZAPRET_DIR="/opt/zapret"
export ZAPRET_CONFIG_DIR="/opt/zapret/config"
export ZAPRET_IPSET_DIR="/opt/zapret/ipset"
export ZAPRET_FAKE_DIR="/opt/zapret/files/fake"
export ZAPRET_CUSTOM_DIR="/opt/zapret/init.d/custom.d"

# Файлы состояния
export STRATEGY_FILE="/etc/zapret-manager/current.strategy"
export META_FILE="/etc/zapret-manager/current.meta"
export HOSTS_FILE="/etc/hosts"
export LOG_FILE="/var/log/zapret-manager.log"

# Временные файлы (используются в модулях)
export TMP_DIR="/tmp/zapret-manager"

# Flowseal и результаты
export FLOWSEAL_DIR="/var/lib/zapret-manager/flowseal"
export RESULTS_DIR="/var/lib/zapret-manager"
