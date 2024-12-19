# Zabbix Script to Telegram 設定說明

本文件說明如何在 Zabbix 中使用外部腳本（Script）來將警報發送到 Telegram 聊天室。

## 前置準備

1. **Zabbix 伺服器版本:** 確保 Zabbix 版本支援 Media Type 使用外部腳本的方式（以下 7.0.3 版本為例）。
2. **Telegram Bot Token:** 從Telegram取得bot token，在呼叫bot api時使用。
3. **Telegram 聊天室id:** 可以是個人或群組聊天室，以下用群組做範例。
4. 創建bot及取得id方式可參考[官方說明](https://www.zabbix.com/integrations/telegram)。其中幾個會需要用到的官方bot請參考本文件[FAQ](##ＦＡＱ)。
6. **外部腳本:** 透過.sh腳本來發送通知到 telegram。

## Script 撰寫及上傳

1. **編寫一個用來發送通知的外部腳本**

- 檔名：**telegram_notify.sh** (以此為例，可自行更換)
- 內容及說明：
  - TOKEN 是 telegram上建立的bot token。
  - CHAT_ID 是 telegram的聊天室id。
  - MESSAGE 是 Zabbix 警報的消息內容。
  - 該腳本會使用 curl 將消息發送到 telegram。
  - 腳本針對message加工替換符號，是因為呼叫api時會視為保留字，如果不加上\\\\會出現錯誤。

```bash
#!/bin/bash

# Telegram Bot Token 和 Chat ID
TOKEN=" " # Telegram BOT Token
CHAT_ID=" "  # Telegram chat_id

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

```

2. **上傳Script**

- 將編寫好的 **telegram_notify.sh** 上傳到 Zabbix 伺服器，預設位置在 /usr/lib/zabbix/alertscripts/ 。
- 確保腳本擁有可執行權限：

```bash
chmod +x /usr/lib/zabbix/alertscripts/telegram_notify.sh
```

## Media Type 設定

1. **新增Media Types：**
   1. Zabbix web介面，Alerts --> Media types。
   2. 點擊右上角的 Create media type。
   欄位內容如下：
      - **Name:** Telegram_notify_script (以此為例，可自行更換)
      - **Type:** Script
      - **Script name:** telegram_notify.sh (server上腳本檔名)
      - **Script parameters:** (範例可自行修改)
      內容中 \n 是換行符號，其他 # **等符號是因應discord有支援顯示 markdown 語法做的調整。

        ```script
        ###Start###\n\nFrom zabbix icar \nHost: \n>  {HOST.NAME}\n>  {HOST.DESCRIPTION}\n\nProblem started at: \n>  {EVENT.DATE}___{EVENT.TIME}\n\nProblem name: \n>  {EVENT.NAME}\n\nSeverity: \n>  {EVENT.SEVERITY}\n\n\n###End###\n
        ```

2. **測試Media Types：**
    1. 測試時會跳出剛打的Script parameters，直接改為測試訊息就好，例如"this is a test message."。
    2. 如果設定正確應該會在telegram頻道內，收到webhook 發送的"this is a test message."。

## Users 設定

- **配置Users Media**
   1. Zabbix web介面，Users --> Users。
   2. 選擇需要接收通知的用戶。
   3. 在 Media 頁籤點 Add，內容如下：
      - **Type:** 選擇 Telegram_notify_script。(剛剛設定的 Media type名稱)
      - **Send to:** 填入完整的 Telegram Bot API URL (script 設定中的URL，`https://api.telegram.org/bot${TOKEN}/sendMessage`)
      - **When active:** 設置時間段，預設1-7,00:00-24:00。
      - **Use if severity:** 設定警報的嚴重性級別，選擇需要接收的事件嚴重性。

## Trigger Actions 設定

1. **新增Action**
   1. Zabbix web介面，Alerts --> Actions --> Trigger actions。
   2. 點擊右上角的 Create action。
      1. 點開第一頁籤 **Action** 欄位內容如下：
      - Name: Report problem to Zabbix admins (可自行修改)
      - Conditions 中設置觸發條件。
      2. 點開第二頁籤 **Operations** 欄位設定如下：
      - Operation 內 **Send to user groups** 或 **Send to users** 設定發送對象
      - Operation 內 **Send only to** 選Telegram_notify_script (上面設定的Media type name)
2. **測試設定是否成功**

---

## ＦＡＱ

- **腳本無法執行:** 請檢查腳本的路徑和執行權限是否正確。
- **通知未發送成功:** 請檢查 Action log 中的狀態，確認是否有發送錯誤。
- ```sed -e 's:\.:\\\\.:g'```  
替換文字的指令“sed”，一般會查到是用“\”而不是“:”來區隔，但因為此處替換會加上很多“\”，所以改使用“:”來增加易讀性。  
以上述範例說明：將字串中的“.”，取代成“\\\\.”，前面的pattern因為會使用到萬用字“.”所以也需要加上跳脫符號來判定一般文字。
- 需要用到的BOT:
    - [botfather](https://telegram.me/BotFather)，建立自己的bot。
    - [MyID](https://t.me/myidbot)，查詢聊天室ID，如果是要查詢群組的需要先把bot邀進聊天室內。