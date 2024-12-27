#!/bin/bash

# 定義 Webhook URL
WEBHOOK_URL="https://discord.com/api/webhooks/1296721752168202262/2RiJYQIoVGLyPKXubfRX08eXDUb7uk4eEYVoB3GBpguJAL82qZtJOu_1kthct5C_uV4o"

# 接收 Zabbix 傳遞的參數
MESSAGE="$1"

# 使用 curl 發送 POST 請求到 Discord Webhook
curl -H "Content-Type: application/json" \
     -X POST \
     -d "{\"content\": \"$MESSAGE\"}" \
     "$WEBHOOK_URL"
