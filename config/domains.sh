#!/bin/bash
# config/domains.sh — Группы доменов для hosts

declare -gA DOMAINS_NALOG=(
    [ID]="nalog"
    [TITLE]="nalog.ru"
    [MARKER_BEGIN]="# ZML_HOSTS_NALOG_BEGIN"
    [MARKER_END]="# ZML_HOSTS_NALOG_END"
    [CONTENT]="213.24.64.175 lkfl2.nalog.ru
213.24.64.181 lknpd.nalog.ru"
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
    [CONTENT]="# Gemini
45.155.204.190 gemini.google.com
# Grok
45.155.204.190 grok.com accounts.x.ai assets.grok.com
# OpenAI
45.155.204.190 chatgpt.com ab.chatgpt.com auth.openai.com auth0.openai.com platform.openai.com cdn.oaistatic.com
45.155.204.190 tcr9i.chat.openai.com webrtc.chatgpt.com android.chat.openai.com api.openai.com operator.chatgpt.com
45.155.204.190 sora.chatgpt.com sora.com videos.openai.com ios.chat.openai.com cdn.auth0.com files.oaiusercontent.com
# Microsoft
45.155.204.190 copilot.microsoft.com sydney.bing.com edgeservices.bing.com rewards.bing.com
45.155.204.190 xsts.auth.xboxlive.com xgpuwebf2p.gssv-play-prod.xboxlive.com xgpuweb.gssv-play-prod.xboxlive.com
# ElevenLabs
45.155.204.190 elevenlabs.io api.us.elevenlabs.io elevenreader.io api.elevenlabs.io help.elevenlabs.io
# DeepL
45.155.204.190 deepl.com www.deepl.com www2.deepl.com login-wall.deepl.com w.deepl.com dict.deepl.com ita-free.www.deepl.com
45.155.204.190 write-free.www.deepl.com experimentation.deepl.com experimentation-grpc.deepl.com ita-free.app.deepl.com
45.155.204.190 ott.deepl.com api-free.deepl.com backend.deepl.com clearance.deepl.com errortracking.deepl.com
45.155.204.190 oneshot-free.www.deepl.com checkout.www.deepl.com gtm.deepl.com auth.deepl.com shield.deepl.com
# Claude
45.155.204.190 claude.ai console.anthropic.com api.anthropic.com
# Trae.ai
45.155.204.190 trae-api-sg.mchost.guru api.trae.ai api-sg-central.trae.ai api16-normal-alisg.mchost.guru
# Windsurf
45.155.204.190 windsurf.com codeium.com server.codeium.com web-backend.codeium.com marketplace.windsurf.com
45.155.204.190 unleash.codeium.com inference.codeium.com windsurf-stable.codeium.com
144.31.14.104 windsurf-telemetry.codeium.com
# Manus
45.155.204.190 manus.im api.manus.im
# Notion
45.155.204.190 www.notion.so calendar.notion.so
# AIStudio
45.155.204.190 aistudio.google.com generativelanguage.googleapis.com aitestkitchen.withgoogle.com aisandbox-pa.googleapis.com xsts.auth.xboxlive.com
45.155.204.190 webchannel-alkalimakersuite-pa.clients6.google.com alkalimakersuite-pa.clients6.google.com assistant-s3-pa.googleapis.com
45.155.204.190 proactivebackend-pa.googleapis.com robinfrontend-pa.googleapis.com o.pki.goog labs.google labs.google.com notebooklm.google
45.155.204.190 notebooklm.google.com jules.google.com stitch.withgoogle.com gemini.google.com copilot.microsoft.com edgeservices.bing.com
45.155.204.190 rewards.bing.com sydney.bing.com xboxdesignlab.xbox.com xgpuweb.gssv-play-prod.xboxlive.com xgpuwebf2p.gssv-play-prod.xboxlive.com"
)

declare -gA DOMAINS_INSTAGRAM=(
    [ID]="instagram"
    [TITLE]="Instagram & Facebook"
    [MARKER_BEGIN]="# ZML_HOSTS_INSTAGRAM_BEGIN"
    [MARKER_END]="# ZML_HOSTS_INSTAGRAM_END"
    [CONTENT]="57.144.222.34 instagram.com www.instagram.com
157.240.9.174 instagram.com www.instagram.com
157.240.245.174 instagram.com www.instagram.com b.i.instagram.com z-p42-chat-e2ee-ig.facebook.com help.instagram.com
157.240.205.174 instagram.com www.instagram.com
57.144.244.192 static.cdninstagram.com graph.instagram.com i.instagram.com api.instagram.com edge-chat.instagram.com
31.13.66.63 scontent.cdninstagram.com scontent-hel3-1.cdninstagram.com
57.144.244.1 facebook.com www.facebook.com fb.com fbsbx.com
57.144.244.128 static.xx.fbcdn.net scontent.xx.fbcdn.net
31.13.67.20 scontent-hel3-1.xx.fbcdn.net"
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
    [CONTENT]="149.154.167.220 core.telegram.org api.telegram.org flora.web.telegram.org kws1-1.web.telegram.org kws1.web.telegram.org kws2-1.web.telegram.org kws2.web.telegram.org kws4-1.web.telegram.org
149.154.167.220 kws4.web.telegram.org kws5-1.web.telegram.org kws5.web.telegram.org pluto-1.web.telegram.org pluto.web.telegram.org td.telegram.org telegram.dog
149.154.167.220 telegram.me telegram.org telegram.space telesco.pe venus.web.telegram.org web.telegram.org zws1-1.web.telegram.org zws1.web.telegram.org
149.154.167.220 tg.dev t.me zws2-1.web.telegram.org zws2.web.telegram.org zws4-1.web.telegram.org zws5-1.web.telegram.org zws5.web.telegram.org"
)

declare -gA DOMAINS_SPOTIFY=(
    [ID]="spotify"
    [TITLE]="Spotify"
    [MARKER_BEGIN]="# ZML_HOSTS_SPOTIFY_BEGIN"
    [MARKER_END]="# ZML_HOSTS_SPOTIFY_END"
    [CONTENT]="45.155.204.190 api.spotify.com login5.spotify.com encore.scdn.co gew1-spclient.spotify.com spclient.wg.spotify.com
45.155.204.190 api-partner.spotify.com aet.spotify.com www.spotify.com accounts.spotify.com open.spotify.com
45.155.204.190 accounts.scdn.co gew1-dealer.spotify.com open-exp.spotifycdn.com www-growth.scdn.co"
)

declare -gA DOMAINS_SUPERCELL=(
    [ID]="supercell"
    [TITLE]="Supercell"
    [MARKER_BEGIN]="# ZML_HOSTS_SUPERCELL_BEGIN"
    [MARKER_END]="# ZML_HOSTS_SUPERCELL_END"
    [CONTENT]="103.27.157.38 accounts.supercell.com cdn.id.supercell.com clashofclans.inbox.supercell.com game-assets.brawlstarsgame.com
103.27.157.38 game-assets.clashofclans.com game-assets.clashroyaleapp.com security.id.supercell.com store.supercell.com"
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
