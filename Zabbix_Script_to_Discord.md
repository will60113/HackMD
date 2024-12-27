# Zabbix Script to Discord 設定說明

本文件說明如何在 Zabbix 中使用外部腳本（Script）來將警報發送到 Discord 的 Webhook 頻道。

## 前置準備

1. **Zabbix 伺服器版本:** 確保 Zabbix 版本支援 Media Type 使用外部腳本的方式（以下 7.0.3 版本為例）。
2. **Discord Webhook URL:** 從 Discord 頻道中取得 Webhook URL。
3. **外部腳本:** 透過.sh腳本來發送通知到 Discord。

## Script 撰寫及上傳

1. **編寫一個用來發送通知的外部腳本**

- 檔名：**discord_webhook.sh** (以此為例，可自行更換)
- 內容及說明：
  - WEBHOOK_URL 是 Discord 的 Webhook 地址（請自行替換）。
  - MESSAGE 是 Zabbix 警報的消息內容。
  - 該腳本會使用 curl 將消息發送到 Discord。

```bash
#!/bin/bash
WEBHOOK_URL="https://discord.com/api/webhooks/1296721752168202262/2RiJYQIoVGLyPKXubfRX08eXDUb7uk4eEYVoB3GBpguJAL82qZtJOu_1kthct5C_uV4o"
MESSAGE="$1"  # 從 Zabbix 傳遞的訊息作為參數
curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$MESSAGE\"}" $WEBHOOK_URL
```

2. **上傳Script**

- 將編寫好的 **discord_webhook.sh** 上傳到 Zabbix 伺服器，預設位置在 /usr/lib/zabbix/alertscripts/ 。
- 確保腳本擁有可執行權限：

```bash
chmod +x /usr/lib/zabbix/alertscripts/discord_webhook.sh
```

## Media Type 設定

1. **新增Media Types：**
   1. Zabbix web介面，Alerts --> Media types。
   2. 點擊右上角的 Create media type。
   欄位內容如下：
      - **Name:** Discord Webhook (以此為例，可自行更換)
      - **Type:** Script
      - **Script name:** discord_webhook.sh (server上腳本檔名)
      - **Script parameters:** (範例可自行修改)
      內容中 \n 是換行符號，其他 # **等符號是因應discord有支援顯示 markdown 語法做的調整。

        ```script
        # From zabbix (icar) \n ## Host: \n > **{HOST.NAME}** \n ## Problem started at \n > **{EVENT.DATE}** **{EVENT.TIME}** \n ## Problem name: \n > **{EVENT.NAME}** \n ## Severity: \n > **{EVENT.SEVERITY}**
        ```

2. **測試Media Types：**
    1. 測試時會跳出剛打的Script parameters，直接改為測試訊息就好，例如"this is a test message."。
    2. 如果設定正確應該會在Discord頻道內，收到webhook 發送的"this is a test message."。

## Users 設定

- **配置Users Media**
   1. Zabbix web介面，Users --> Users。
   2. 選擇需要接收通知的用戶。
   3. 在 Media 頁籤點 Add，內容如下：
      - **Type:** 選擇 Discord Webhook。(剛剛設定的 Media type名稱)
      - **Send to:** 填入完整的 Discord Webhook URL (script 設定中的WEBHOOK_URL)
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
      - Operation 內 **Send only to** 選Discord Webhook (上面設定的Media type name)
2. **測試設定是否成功**

---

### 常見錯誤排查

- **腳本無法執行:** 請檢查腳本的路徑和執行權限是否正確。
- **通知未發送成功:** 請檢查 Action log 中的狀態，確認是否有發送錯誤。
- **無法發送到 Discord:** 請確認 Discord Webhook URL 是否正確，並確保 curl 能夠正常執行。
可在zabbix server或其他不同網路環境測試執行
  
``` bash
curl -X POST -H "Content-Type: application/json" -d '{"content":"test message"}' https://discord.com/api/webhooks/1296721752168202262/2RiJYQIoVGLyPKXubfRX08eXDUb7uk4eEYVoB3GBpguJAL82qZtJOu_1kthct5C_uV4o
```
