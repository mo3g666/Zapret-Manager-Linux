#!/bin/bash
# lib/ui.sh — Функции UI и меню

source "$(dirname "$0")/logger.sh"

# Цвета
export GREEN="\033[1;32m"
export RED="\033[1;31m"
export CYAN="\033[1;36m"
export YELLOW="\033[1;33m"
export NC="\033[0m"

print_header() {
    local title="$1"
    clear
    echo -e "${CYAN}=== $title ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${CYAN}→ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

ask_confirmation() {
    local prompt="$1"
    local response
    read -p "$(echo -e ${YELLOW})$prompt (y/N): $(echo -e ${NC})" response
    [[ "$response" =~ ^[Yy]$ ]]
}

pause_menu() {
    echo ""
    read -p "Нажмите Enter для продолжения..."
}

show_status() {
    local label="$1"
    local value="$2"
    printf "%-30s: %s\n" "$label" "$value"
}
