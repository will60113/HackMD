# Zabbix Webhook to Telegram 設定說明

本文件說明如何在 Zabbix 中使用Webhook 來將警報發送到 Telegram 聊天室。

## 前置準備

1. **Zabbix 伺服器版本:** 確保 Zabbix 版本支援 Media Type 使用外部腳本的方式（以下 7.0.3 版本為例）。
2. **Telegram Bot Token:** 從Telegram取得bot token，在呼叫bot api時使用。
3. **Telegram 聊天室id:** 可以是個人或群組聊天室，以下用群組做範例。
4. 創建bot及取得id方式可參考[官方說明](https://www.zabbix.com/integrations/telegram)。其中幾個會需要用到的官方bot請參考本文件[FAQ](##FAQ)第二項。

## Media Type 設定

1. **新增Media Types：**
   1. Zabbix web介面，Alerts --> Media types。
   2. 點擊右上角的 Create media type。
   欄位內容如下：
      - **Name:** Telegram_Webhook (以此為例，可自行更換)
      - **Type:** Webhook
      - **Parameters:** 總共5個Key，value可參考[附件](###Key-Value對應範例)
          - Message
          - ParseMode
          - Subject
          - To
          - Token
      - **Script:** 範例參考[附件](###Script範例)
      - **Message Templates**
          - message type 選 "problem" 可以推送觸發的問題，其他依照需求新增就好。

2. **測試Media Types：**
    1. 測試時會跳出剛設定的 parameters，可以修改測試內容或直接發送，應該就會在 Telegram聊天室內看到。
    2. 測試階段遇過的錯誤訊息及腳本內容說明可參考[FAQ](##FAQ)第一項。

## Users 設定

- **配置Users Media**
   1. Zabbix web介面，Users --> Users。
   2. 選擇需要接收通知的用戶。
   3. 在 Media 頁籤點 Add，內容如下：
      - **Type:** 選擇 Telegram_Webhook。(剛剛設定的 Media type名稱)
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
      - Operation 內 **Send only to** Telegram_Webhook (上面設定的Media type name)
2. **測試設定是否成功**

---

## FAQ

1. **Sending failed: URIError: invalid input.**  
    出現這個表示傳送的內容中包含了無效或未正確處理的字元，有可能是 markdown的保留字，範例script中的除了原先預設的replace以外，還有特別處理幾種特殊情況：
    - (/(\s>)|(\s> )/g, '\\>')
        - 說明：\s 代表空格，所以是把“空格>”跟“空格>空格”，取代成“\\\\>”。
        - 如果“> ”(前面沒有空格，但後面接著一個空格)，這個會被視為markdown縮排使用，所以不作取代。
    - (/%0A/g, '\n')、(/%/g, '\\%')
        - 說明：%0A會被替換成 \n作為換行使用
        - 上面%0A替換完之後，會再把單獨的“%”轉換成“\\\\%”

2. 需要用到的BOT:
    - [botfather](https://telegram.me/BotFather)，建立自己的bot。
    - [MyID](https://t.me/myidbot)，查詢聊天室ID，如果是要查詢群組的需要先把bot邀進聊天室內。

---

## Script example

### Key-Value對應範例
``` json
Key: Message 
Value:
    Host:%0A>  {HOST.NAME}%0A>  {HOST.DESCRIPTION}%0A%0AProblem started at: %0A>  {EVENT.DATE}___{EVENT.TIME}%0A%0AProblem name: %0A>  {EVENT.NAME}%0A%0ASeverity: %0A>  {EVENT.SEVERITY}%0A%0A%0A###End###
    
Key: ParseMode
Value:
    markdownv2
    
Key: Subject
Value:
    ###Start###%0A%0A**From zabbix icar **
    
Key: To
Value:
    Telegram 聊天室id
    
Key: Token
Value:
    Telegram Bot Token
```
### Script範例
``` javascript
var Telegram = {
    token: null,
    to: null,
    message: null,
    proxy: null,
    parse_mode: null,

    escapeMarkup: function (str, mode) {
        switch (mode) {
            case 'markdown':
                return str.replace(/([_*\[`])/g, '\\$&');

            case 'markdownv2':
                return str.replace(/(\s>)|(\s> )/g, '\\>').replace(/([_\[\]()~`#+\-=|{}.!])/g, '\\$&');

            case 'html':
                return str.replace(/<(\s|[^a-z\/])/g, '&lt;$1');

            default:
                return str;
        }
    },

    sendMessage: function () {
        var params = {
            chat_id: Telegram.to,
            text: Telegram.message,
            disable_web_page_preview: true,
            disable_notification: false
        },
        data,
        response,
        request = new HttpRequest(),
        url = 'https://api.telegram.org/bot' + Telegram.token + '/sendMessage';

        if (Telegram.parse_mode !== null) {
            params['parse_mode'] = Telegram.parse_mode;
        }

        if (Telegram.proxy) {
            request.setProxy(Telegram.proxy);
        }

        request.addHeader('Content-Type: application/json');
        params.text = params.text.replace(/%0A/g, '\n'); // 將 %0A 換成 \n
        params.text = params.text.replace(/%/g, '\\%');  // 將 % 替換為 \%
        data = JSON.stringify(params);

        // Remove replace() function if you want to see the exposed token in the log file.
        Zabbix.log(4, '[Telegram Webhook] URL: ' + url.replace(Telegram.token, '<TOKEN>'));
        Zabbix.log(4, '[Telegram Webhook] params: ' + data);
        response = request.post(url, data);
        Zabbix.log(4, '[Telegram Webhook] HTTP code: ' + request.getStatus());

        try {
            response = JSON.parse(response);
        }
        catch (error) {
            response = null;
        }

        if (request.getStatus() !== 200 || typeof response.ok !== 'boolean' || response.ok !== true) {
            if (typeof response.description === 'string') {
                throw response.description;
            }
            else {
                throw 'Unknown error. Check debug log for more information.';
            }
        }
    }
};

try {
    var params = JSON.parse(value);

    if (typeof params.Token === 'undefined') {
        throw 'Incorrect value is given for parameter "Token": parameter is missing';
    }

    Telegram.token = params.Token;

    if (params.HTTPProxy) {
        Telegram.proxy = params.HTTPProxy;
    } 

    params.ParseMode = params.ParseMode.toLowerCase();
    
    if (['markdown', 'html', 'markdownv2'].indexOf(params.ParseMode) !== -1) {
        Telegram.parse_mode = params.ParseMode;
    }

    Telegram.to = params.To;
    Telegram.message = params.Subject + '\n' + params.Message;

    if (['markdown', 'html', 'markdownv2'].indexOf(params.ParseMode) !== -1) {
        Telegram.message = Telegram.escapeMarkup(Telegram.message, params.ParseMode);

    }
    Telegram.sendMessage();
    return 'OK';
}
catch (error) {
    Zabbix.log(4, '[Telegram Webhook] notification failed: ' + error);
    throw 'Sending failed: ' + error + '.';
}
```