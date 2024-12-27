#!/bin/bash

# Telegram Bot Token 和 Chat ID
TOKEN="7898763629:AAErrUgR8LVqdjWjAiBDfvrqsfEMokeXpVE"
CHAT_ID="-4717527527"  # Telegram chat_id

# 由 Zabbix 傳入的參數
MESSAGE="$1"
ESCAPED_MESSAGE=$(echo "$MESSAGE" | \
	sed -e 's:\.:\\\\.:g' \
		-e 's:\_:\\\\_:g' \
		-e 's:\~:\\\\~:g' \
		-e 's:>:\\\\>:g' \
		-e 's:\#:\\\\#:g' \
		-e 's:\+:\\\\+:g' \
		-e 's:\-:\\\\-:g' \
		-e 's:!:\\\\!:g' \
		-e 's:\=:\\\\=:g' \
		-e 's:(:\\\\(:g' \
		-e 's:):\\\\):g' \
		-e 's:\[:\\\\[:g' \
		-e 's:]:\\\\]:g' \
		-e 's:{:\\\\{:g' \
		-e 's:}:\\\\}:g' \
		-e 's:\*:\\\\*:g' )

# 打印原始訊息和替換後的訊息
#echo "Raw message: $MESSAGE"
#echo "Escaped message: $ESCAPED_MESSAGE"

# 發送訊息到 Telegram
curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
  -H 'Content-Type: application/json' \
  -d '{
    "chat_id": "'"${CHAT_ID}"'",
    "text": "'"${ESCAPED_MESSAGE}"'",
    "parse_mode": "markdownv2",
    "disable_web_page_preview": true
  }'
