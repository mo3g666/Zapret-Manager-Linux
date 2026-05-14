#!/bin/bash
# config/domains.sh — Группы доменов для hosts

declare -gA DOMAINS_NALOG=(
    [ID]="nalog"
    [TITLE]="nalog.ru"
    [MARKER_BEGIN]="# ZML_HOSTS_NALOG_BEGIN"
    [MARKER_END]="# ZML_HOSTS_NALOG_END"
    [CONTENT]="45.155.204.190 lkfl2.nalog.ru
45.155.204.181 lknpd.nalog.ru"
)

declare -gA DOMAINS_RUTOR=(
    [ID]="rutor"
    [TITLE]="rutor.info"
    [MARKER_BEGIN]="# ZML_HOSTS_RUTOR_BEGIN"
    [MARKER_END]="# ZML_HOSTS_RUTOR_END"
    [CONTENT]="173.245.58.219 rutor.info d.rutor.info"
)

declare -gA DOMAINS_NTC=(
    [ID]="ntc"
    [TITLE]="ntc.party"
    [MARKER_BEGIN]="# ZML_HOSTS_NTC_BEGIN"
    [MARKER_END]="# ZML_HOSTS_NTC_END"
    [CONTENT]="130.255.77.28 ntc.party"
)

declare -gA DOMAINS_LIBRUSEC=(
    [ID]="librusec"
    [TITLE]="lib.rus.ec"
    [MARKER_BEGIN]="# ZML_HOSTS_LIBRUSEC_BEGIN"
    [MARKER_END]="# ZML_HOSTS_LIBRUSEC_END"
    [CONTENT]="185.39.18.98 lib.rus.ec www.lib.rus.ec"
)

declare -gA DOMAINS_AI=(
    [ID]="ai"
    [TITLE]="AI сервисы"
    [MARKER_BEGIN]="# ZML_HOSTS_AI_BEGIN"
    [MARKER_END]="# ZML_HOSTS_AI_END"
    [CONTENT]="45.155.204.190 chatgpt.com auth.openai.com platform.openai.com
45.155.204.190 gemini.google.com aistudio.google.com
45.155.204.190 claude.ai console.anthropic.com api.anthropic.com"
)

declare -gA DOMAINS_INSTAGRAM=(
    [ID]="instagram"
    [TITLE]="Instagram & Facebook"
    [MARKER_BEGIN]="# ZML_HOSTS_INSTAGRAM_BEGIN"
    [MARKER_END]="# ZML_HOSTS_INSTAGRAM_END"
    [CONTENT]="57.144.222.34 instagram.com www.instagram.com
57.144.244.192 static.cdninstagram.com
57.144.244.1 facebook.com www.facebook.com"
)

declare -gA DOMAINS_TWITCH=(
    [ID]="twitch"
    [TITLE]="Twitch"
    [MARKER_BEGIN]="# ZML_HOSTS_TWITCH_BEGIN"
    [MARKER_END]="# ZML_HOSTS_TWITCH_END"
    [CONTENT]="45.155.204.190 usher.ttvnw.net gql.twitch.tv"
)

declare -gA DOMAINS_TELEGRAM=(
    [ID]="telegram"
    [TITLE]="Telegram Web"
    [MARKER_BEGIN]="# ZML_HOSTS_TELEGRAM_BEGIN"
    [MARKER_END]="# ZML_HOSTS_TELEGRAM_END"
    [CONTENT]="149.154.167.220 web.telegram.org core.telegram.org api.telegram.org
149.154.167.220 t.me telegram.me telegram.org"
)

declare -gA DOMAINS_SPOTIFY=(
    [ID]="spotify"
    [TITLE]="Spotify"
    [MARKER_BEGIN]="# ZML_HOSTS_SPOTIFY_BEGIN"
    [MARKER_END]="# ZML_HOSTS_SPOTIFY_END"
    [CONTENT]="45.155.204.190 api.spotify.com login5.spotify.com open.spotify.com
45.155.204.190 accounts.spotify.com www.spotify.com"
)

declare -gA DOMAINS_SUPERCELL=(
    [ID]="supercell"
    [TITLE]="Supercell"
    [MARKER_BEGIN]="# ZML_HOSTS_SUPERCELL_BEGIN"
    [MARKER_END]="# ZML_HOSTS_SUPERCELL_END"
    [CONTENT]="103.27.157.38 accounts.supercell.com cdn.id.supercell.com
103.27.157.38 store.supercell.com security.id.supercell.com"
)

declare -gA DOMAINS_GITHUB=(
    [ID]="github"
    [TITLE]="githubusercontent.com"
    [MARKER_BEGIN]="# ZML_HOSTS_GITHUB_BEGIN"
    [MARKER_END]="# ZML_HOSTS_GITHUB_END"
    [CONTENT]="185.199.109.133 raw.githubusercontent.com release-assets.githubusercontent.com
185.199.108.133 private-user-images.githubusercontent.com gist.githubusercontent.com avatars.githubusercontent.com"
)

declare -gA DOMAINS_LIST=(
    [nalog]="DOMAINS_NALOG"
    [rutor]="DOMAINS_RUTOR"
    [ntc]="DOMAINS_NTC"
    [librusec]="DOMAINS_LIBRUSEC"
    [ai]="DOMAINS_AI"
    [instagram]="DOMAINS_INSTAGRAM"
    [twitch]="DOMAINS_TWITCH"
    [telegram]="DOMAINS_TELEGRAM"
    [spotify]="DOMAINS_SPOTIFY"
    [supercell]="DOMAINS_SUPERCELL"
    [github]="DOMAINS_GITHUB"
)
