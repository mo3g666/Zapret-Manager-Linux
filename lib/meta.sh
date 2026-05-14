#!/bin/bash
# lib/meta.sh — Работа с current.meta

source "$(dirname "$0")/../config/paths.sh"
source "$(dirname "$0")/../config/defaults.sh"
source "$(dirname "$0")/logger.sh"

ensure_meta_file() {
    if [ ! -d "$ZML_DIR" ]; then
        mkdir -p "$ZML_DIR" || return 1
    fi

    if [ ! -f "$META_FILE" ]; then
        touch "$META_FILE" || return 1
    fi
}

ensure_meta_defaults() {
    ensure_meta_file || return 1

    local keys=(
        "MODE:$DEFAULT_MODE"
        "MAIN_STRATEGY:$DEFAULT_MAIN_STRATEGY"
        "YOUTUBE_STRATEGY:$DEFAULT_YOUTUBE_STRATEGY"
        "GAME_STRATEGY:$DEFAULT_GAME_STRATEGY"
        "DISCORD_STRATEGY:$DEFAULT_DISCORD_STRATEGY"
        "FLOWSEAL_STRATEGY:$DEFAULT_FLOWSEAL_STRATEGY"
        "RKN_BYPASS:$DEFAULT_RKN_BYPASS"
        "WSSIZE_BLOCK:$DEFAULT_WSSIZE_BLOCK"
        "METHODEOL_BLOCK:$DEFAULT_METHODEOL_BLOCK"
        "DISCORD_SCRIPT:$DEFAULT_DISCORD_SCRIPT"
        "DISCORD_FINLAND_IPS:$DEFAULT_DISCORD_FINLAND_IPS"
        "HOSTS_GROUPS_ADDED:$DEFAULT_HOSTS_GROUPS_ADDED"
    )

    for key_val in "${keys[@]}"; do
        local key="${key_val%:*}"
        local default_val="${key_val#*:}"

        if ! grep -q "^${key}=" "$META_FILE"; then
            echo "${key}=${default_val}" >> "$META_FILE"
        fi
    done
}

get_meta() {
    local key="$1"
    local default_val="${2:-}"

    ensure_meta_file || return 1

    local value
    value=$(grep "^${key}=" "$META_FILE" 2>/dev/null | cut -d= -f2-)

    if [ -z "$value" ]; then
        echo "$default_val"
    else
        echo "$value"
    fi
}

set_meta() {
    local key="$1"
    local value="$2"

    ensure_meta_file || return 1

    sed -i "/^${key}=/d" "$META_FILE"
    echo "${key}=${value}" >> "$META_FILE"
    log_info "Set $key=$value"
    return 0
}
