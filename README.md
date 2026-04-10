# Linux 流量與安全監控
網路入侵不僅浪費您的頻寬，還涉及各種形式的攻擊。
這是一套輕量級的 Shell 腳本集合，專為保護 Linux 伺服器（特別是 Ubuntu/Oracle Cloud）免受自動化攻擊、DDoS 嘗試和密集請求而設計。
![Internet attack](https://github.com/inchinet/attack/blob/main/issue.png)

## 🚀 專案概述

這些腳本會監控您的 Apache/Web 伺服器日誌。如果某個 IP 位址在一分鐘內的請求次數超過設定的閾值，系統會自動透過 `fail2ban` 觸發永久封鎖。

### 主要功能
- **即時監控**：掃描存取日誌以尋找流量峰值。
- **自動封鎖**：自動與 `fail2ban-client` 互動以封鎖惡意 IP。
- **WhatsApp/Telegram 警報**：透過 [CallMeBot](https://www.callmebot.com/) 或 Telegram 將詳細報告傳送到您的手機。
- **特定 Jail 報告**：報告現在會顯示哪個 Jail 攔截了該 IP（例如：`[sshd]`，`[apache-auth]`）。
- **永久保護**：針對 `bantime = -1` 進行了最佳化。
- **輕量級**：純 Bash 與 AWK — 無需龐大的依賴套件。
- **全面的伺服器健康監控**：監控記憶體、磁碟使用率、運作中的服務與對外連網 IP 狀態 (`server_health.sh`)。
- **系統強化與稽核**：定期檢查重要資料夾權限、待處理的安全更新，以及作業系統底層調校 (`security_hardening.sh`, `update_guard.sh`, `config_guard.sh`)。
- **Web 應用程式防火牆 (WAF)**：輕量級、基於特徵碼的狙擊守衛，能即時攔截 SQLi、XSS 和目錄遍歷的惡意嘗試 (`sniper_monitor.sh`)。

---

## 🛠 包含的腳本

| 腳本 | 用途 |
| :--- | :--- |
| `trafficmonitor.sh` | **防禦巡邏**。分析日誌並觸發主動封鎖。 |
| `sniper_monitor.sh` | **狙擊守衛**。針對敏感檔案與進階網路攻擊（SQLi、XSS、RCE）進行即時封鎖。 |
| `securityofficer.sh` | **稽核報告**。總結過去 24 小時內的所有封鎖記錄。 |
| `server_health.sh` | **系統心跳**。報告磁碟、記憶體、CPU 以及服務狀態。 |
| `security_hardening.sh` | **鐵匠**。套用 sysctl 強化設定並稽核通訊埠/SSH。 |
| `update_guard.sh` | **守望者**。檢查待處理的安全更新。 |
| `config_guard.sh` | **金庫守衛**。稽核 .env 與備份檔案的權限。 |
| `send_traffic_report.sh` | 將流量數據封裝並透過 WhatsApp/Telegram 傳送。 |
| `send_security_report.sh`| 將安全稽核報告封裝並透過 WhatsApp/Telegram 傳送。 |

關於 Telegram，請參閱 *Telegram 設定* 區塊。
---
![Internet attack](https://github.com/inchinet/attack/blob/main/banip2.png)
![Internet attack](https://github.com/inchinet/attack/blob/main/issue2.png)

## 💡 為什麼需要 trafficmonitor.sh？(Fail2ban vs 流量監控)
機器人會在一秒鐘內發送大量對 .env 檔案的請求，試圖如上述範例般讀取/獲取網路上不同資料夾的憑證。這可以使用 trafficmonitor.sh 來防禦。
常見的問題是：*"為什麼 Fail2ban 不能自動攔截這些高流量攻擊？"*

### 1. 不同的日誌檔案
*   **Fail2ban（標準 Jails）：** 通常監控 `error.log`。它尋找的是明確的失敗訊息，例如 "Password mismatch" (密碼錯誤) 或 "User not found" (找不到使用者)。
*   **攻擊行為：** 高流量請求（掃描漏洞的機器人或惡意爬蟲）在 `access.log` 中通常顯示為 "200 OK" 或 "404 Not Found"。
*   **衝突所在：** 由於標準 Fail2ban 並未監控 `access.log`，所以它對流量的「速度」完全一無所知。它只在乎登入是否失敗。

### 2. 不同的判定標準
*   **Fail2ban（標準 Jails）：** 計算「重試次數」。例如："10 分鐘內失敗 3 次"。
*   **TrafficMonitor.sh：** 計算「速度」。例如："1 分鐘內 30 次請求"。（THRESHOLD=30 可自訂）

### 解決方案
`trafficmonitor.sh` 充當自訂的 **"DoS 偵測器"**：
1.  它讀取 `access.log`（這是標準 Fail2ban 忽略的）。
2.  它計算*流量大小*（這是 Fail2ban 不會計算的）。
3.  當發現某個 IP 超過閾值（例如：30次請求/分鐘）時，它會手動觸發 `fail2ban-client` 以立即封鎖該 IP。

---

## ⚙️ 設定說明

### 1. 系統需求
- **Fail2ban**：必須已安裝且正在運行。
- **Root/Sudo 權限**：您需要 sudo 權限來設定這些組態。

### 2. 環境與權限設定
執行以下命令來配置您的使用者群組和檔案權限。可確保您能安全地讀取日誌與上傳腳本。

```bash
# 1. 允許自己讀取系統日誌 (adm 群組)
sudo usermod -a -G adm $(whoami)

# 2. 允許自己管理網頁檔案 (www-data 群組)
sudo usermod -a -G www-data $(whoami)

# 3. 建立日誌檔案並設定嚴格權限 (640)
# (640 = 擁有者可讀寫，群組可讀，其他無權限)
sudo touch /var/log/security-report.log /var/log/traffic-report.log /var/log/server-health.log \
           /var/log/security-hardening.log /var/log/update-guard.log /var/log/config-guard.log
sudo chown $(whoami):adm /var/log/security-report.log /var/log/traffic-report.log /var/log/server-health.log \
                       /var/log/security-hardening.log /var/log/update-guard.log /var/log/config-guard.log
sudo chmod 640 /var/log/security-report.log /var/log/traffic-report.log /var/log/server-health.log \
               /var/log/security-hardening.log /var/log/update-guard.log /var/log/config-guard.log
```
請登出並重新登入以使群組變更生效。


### 3. 設定 Fail2ban 進行永久封鎖
編輯 `/etc/fail2ban/jail.local` 以啟用永久封鎖，並監控多個日誌檔案（例如：標準的 Apache 日誌）。

```bash
sudo nano /etc/fail2ban/jail.local
```

**推薦配置：**
```ini
[DEFAULT]
bantime = -1

[apache-auth]
enabled = true
port    = http,https
logpath = /var/log/apache2/error.log

[apache-badbots]
enabled = true
port    = http,https
logpath = /var/log/apache2/access.log


[apache-noscript]
enabled = true
port    = http,https
logpath = /var/log/apache2/error.log

```

套用變更：
```bash
sudo systemctl restart fail2ban
```

##  自我修復（無法被擊殺的守衛）
確保 Fail2ban 在崩潰或意外停止時會自動重新啟動：
1. 建立目錄
```bash
sudo mkdir -p /etc/systemd/system/fail2ban.service.d
```
2. 將設定直接寫入檔案
```bash
echo -e "[Service]\nRestart=always\nRestartSec=5" | sudo tee /etc/systemd/system/fail2ban.service.d/override.conf
```
3. 重新載入伺服器設定
```bash
sudo systemctl daemon-reload
```
4. 避免封鎖自己
修改 `trafficmonitor.sh`，將白名單中的 0.123.456.789 替換為您自己的 IP，中間不加逗號：

```ini
WHITELIST="0.123.456.789 127.0.0.1 ::1"
```

### 4. 上傳與啟用腳本
將所有腳本（除了 `sniper_monitor.sh`）上傳到 `/var/www/html`。

**設定嚴格權限（統一做法）：**
請勿修改整個資料夾。只需保護這些腳本即可。
```bash
cd /var/www/html
# 將所有安全及健康監控腳本的擁有權設定為您的使用者與 adm 群組
sudo chown $(whoami):adm *.sh

# 750 = 擁有者可讀寫執行，群組可讀執行，其他無權限
sudo chmod 750 *.sh
```
*(750 = 擁有者可寫入/執行，群組可讀取/執行，其他人無法存取)*

---

## 🔐 自動化權限設定 (Sudoers)
由於這些腳本在內部使用了 `sudo`（以封鎖 IP 及讀取安全日誌），當自動化執行時，它們必須在不需要提示密碼的狀態下執行。

### 選項 1: 以 Root 身份執行 (強烈建議)
將 cron 任務新增至 **root** 的 crontab 中。這是最簡單也是最安全的方法。
1. 執行 `sudo crontab -e`
2. 加入下方「自動化執行 (Cron)」區段的設定行。

### 選項 2: 設定 `visudo` (標準使用者)
如果您以標準使用者執行 cron 任務（執行 `crontab -e`），您必須允許在不輸入密碼的情況下執行指定的指令。
1. 執行 `sudo visudo`
2. 在底部加入以下內容（請替換 `your_username` 為您的使用者名稱）：
   ```bash
   your_username ALL=(ALL) NOPASSWD: /usr/bin/awk
   your_username ALL=(ALL) NOPASSWD: /usr/bin/grep
   your_username ALL=(ALL) NOPASSWD: /usr/bin/fail2ban-client
   ```

---

### 5. ⏰ 自動化執行 (Cron)
若要定期接收更新報告，請在 `crontab -e` 中加入以下設定：
```bash
# 每小時發送流量報告
0 * * * * /var/www/html/send_traffic_report.sh >> /var/log/traffic-report.log 2>&1

# 每日 23:59 進行安全稽核
59 23 * * * /var/www/html/send_security_report.sh >> /var/log/security-report.log 2>&1

# 每日 09:00 發送伺服器健康報告
0 9 * * * /var/www/html/server_health.sh >> /var/log/server-health.log 2>&1
```

### 6. 🎯 狙擊守衛 (背景服務)
`sniper_monitor.sh` 是一個 **即時** 守衛。有別於等待流量閾值（速度）的 `trafficmonitor.sh`，狙擊守衛關注於 **企圖**。它作為一個輕量級的 Web 應用程式防火牆（WAF），提供即時的保護。

#### 🛡️ 為什麼它能攔截攻擊：
狙擊守衛不在乎攻擊者的速度有多快；它在乎的是攻擊者 **正在找什麼**。它使用兩種不同的偵測層級：

| 層級 | 偵測邏輯 | 攔截目標 |
| :--- | :--- | :--- |
| **1. 敏感檔案** | **錨點正規表達式**: 僅比對完整的路徑片段 (例如：`/.env` 或是 `/config.php`)。 | 防止駭客刺探憑證、資料庫組態或 git 歷史記錄。 |
| **2. 攻擊特徵** | **全域特徵**: 極具惡意的模式，這些模式絕對不會出現在安全合法的流量中。 | 偵測主動利用漏洞的嘗試，例如 SQL Injection（資料隱碼攻擊）、XSS 與 RCE。 |

#### 🔍 詳細模式邏輯：
*   **零誤報錨定**: 它使用正規表達式 `(^|/)($FILE_PATTERNS)($|\?|/)`。這意味著它會封鎖嘗試存取 `example.com/.env` 的人，但 **不會** 封鎖正在閱讀標題為 `how-to-fix-your-config.php` 的合法使用者。
*   **SQL Injection (SQLi)**: 偵測如 `UNION SELECT`、`information_schema` 以及資料庫探測指令（`@@version`, `order by`）等關鍵字。它甚至能藉由尋找 `sleep()` 函數來攔截「基於時間的盲注 (Time-based Blind SQLi)」。
*   **Cross-Site Scripting (XSS)**: 立即封鎖包含 `<script>`、`onerror=`、`alert(` 或 `javascript:` URI 機制的請求載荷 (payloads)。
*   **Remote Code Execution (RCE) 與目錄遍歷**: 監控目錄遍歷 (`../`)、讀取系統檔案嘗試 (`/etc/passwd`) 以及執行特徵如 `base64_decode` 或是 `bin/bash`。
*   **即時互動**: 因為它對日誌使用 `tail -F`，並且直接與 `fail2ban-client` 通訊，封鎖會在幾毫秒內發生——往往在攻擊者的第一個惡意請求處理完成之前就已生效。

**安裝與設定：**
1. 將腳本移動到系統路徑：
```bash
sudo mv sniper_monitor.sh /usr/local/bin/
```
2. 設定擁有權和權限（**安全最佳實踐**）：
```bash
# 只有 root 才應該可以編輯安全腳本
sudo chown root:root /usr/local/bin/sniper_monitor.sh
sudo chmod 755 /usr/local/bin/sniper_monitor.sh
```

3. 建立服務設定檔 `/etc/systemd/system/sniper-monitor.service`：
```ini
[Unit]
Description=Sniper Security Monitor
After=network.target apache2.service fail2ban.service

[Service]
Type=simple
ExecStart=/usr/local/bin/sniper_monitor.sh
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
```
4. 啟用並啟動服務：
```bash
sudo systemctl daemon-reload
sudo systemctl enable sniper-monitor
sudo systemctl start sniper-monitor
```
**重啟服務**

 1. 停止官方服務
```bash
sudo systemctl stop sniper-monitor
```
 2. 手動清除所有殘留的執行緒
```bash
sudo pkill -f sniper_monitor.sh
```
 3. 再次啟動
```bash
sudo systemctl start sniper-monitor
```


**如何檢查日誌：**
* **即時監控：**
```bash
sudo journalctl -u sniper-monitor -f
```
* **今天封鎖了多少 IP？**
```bash
sudo journalctl -u sniper-monitor --since "24 hours ago" | grep "Banned" | wc -l
```
* **列出所有被封鎖的 IP：**
```bash
sudo journalctl -u sniper-monitor | awk '/Banned/ {for(i=1;i<=NF;i++) if($i=="Banned") print $(i+1)}' | sort -u
```

**額外說明**

若要防止 Apache 列出目錄，您應該使用 `Options -Indexes` 指令。這樣可以阻止伺服器在沒有索引檔案（例如 index.html）時自動產生檔案清單。
編輯您的主設定檔（通常在 Debian/Ubuntu 上是 `/etc/apache2/apache2.conf`，在 CentOS/RHEL 上是 `/etc/httpd/conf/httpd.conf`）。
找到 `<Directory /var/www/>` 程式碼區塊（或您指定的文檔根目錄）。
修改 `Options` 行: 

```ini
<Directory /var/www/>
Options -Indexes +FollowSymLinks
AllowOverride None
Require all granted
</Directory>
```

```bash
sudo systemctl restart apache2 (or httpd)
```

### 7. 🚀 檢查封鎖 IP
```bash
sudo fail2ban-client status apache-auth
sudo fail2ban-client status apache-noscript
sudo fail2ban-client status apache-badbots
sudo fail2ban-client status sshd
```

1. 如有需要，從 jail 移除/解鎖 IP
```bash
sudo fail2ban-client set apache-auth unbanip <IP_ADDRESS>
```

*範例：如果您的伺服器封鎖了自身的 IPv6 迴圈位址，解鎖自己：*
```bash
sudo fail2ban-client set apache-auth unbanip ::1
```

2. 一次解除某 IP 在所有 jails 的封鎖：
```bash
sudo fail2ban-client unban <IP_ADDRESS>
```

3. 手動封鎖某 IP（若您想測試）：
```bash
sudo fail2ban-client set apache-auth banip <IP_ADDRESS>
```

### 8. 🛡️ 作業系統強化與維護
除了即時監控之外，您應該定期執行強化稽核，並確保腳本具備嚴格的擁有者限權。

**設定腳本擁有權：**
請確保這些腳本的擁有者是您的管理使用者與 `adm` 群組。
```bash
sudo chown $(whoami):adm security_hardening.sh update_guard.sh config_guard.sh
sudo chmod 750 security_hardening.sh update_guard.sh config_guard.sh
```

**執行強化稽核：**
```bash
# 執行強化腳本
sudo ./security_hardening.sh
```

**自動化維護 (Cron Jobs)：**
將這些加入 `crontab -e` 來自動化您的安全稽核：

```bash
# 1. 安全更新檢查 (每週日 08:30)
30 8 * * 0 /var/www/html/update_guard.sh >> /var/log/update-guard.log 2>&1

# 2. 網站權限稽核 (每週日 00:00)
0 0 * * 0 /var/www/html/config_guard.sh >> /var/log/config-guard.log 2>&1

# 3. 每月作業系統強化檢查 (每月 1 號 01:00)
0 1 1 * * /var/www/html/security_hardening.sh >> /var/log/security-hardening.log 2>&1
```

**Cockpit 強固 (僅限作者)：**
預設情況下，Cockpit（Port 9090）可能對公網開放。為了遵守「僅限作者 (`Author Only`)」規則，您可以將它綁定至您的區域網路 (LAN) IP。這不僅防止暴露在網際網路，同時仍允許從您的家用網路（或透過路由器上的秘密端口轉發）存取。

```bash
# 1. 建立覆蓋設定目錄
sudo mkdir -p /etc/systemd/system/cockpit.socket.d

# 2. 綁定至您的 LAN IP (請將 10.0.0.15 替換為伺服器實際的 LAN IP)
echo -e "[Socket]\nListenStream=\nListenStream=10.0.0.15:9090" | sudo tee /etc/systemd/system/cockpit.socket.d/override.conf

# 3. 套用變更
sudo systemctl daemon-reload
sudo systemctl restart cockpit.socket
```
*(設定完成後，在路由器上將一個自訂的「秘密」外部通訊埠指向您的 LAN IP，即可安全地遠端存取。)*

**安全的安全性升級（逐一套件升級）：**
在關鍵的伺服器上，執行完整的 `apt upgrade` 可能會有風險。較安全的做法是，透過 `update_guard.sh` 找出標記的關鍵安全套件，然後逐一升級。

```bash
# 基本語法
sudo apt-get install --only-upgrade <package_name>

# 推薦的關鍵更新：
sudo apt-get install --only-upgrade sudo
sudo apt-get install --only-upgrade openssh-server openssh-client openssh-sftp-server
sudo apt-get install --only-upgrade curl libcurl4
```

---
## 🛡️ WhatsApp 警報 (CallMeBot)
此專案使用 **CallMeBot** 發送 WhatsApp 通知，完全免費且無需安裝任何額外軟體。

### CallMeBot 設定方法：
1. 將 **+34 621 33 14 81**（或是從 [CallMeBot](https://www.callmebot.com/) 取得機器人最新的號碼）加入手機聯絡人。
2. 透過 WhatsApp 發送訊息 `"I allow callmebot to send me messages"` 給該聯絡人。
3. 您將收到一組 **API Key**。
4. 在您的 `send_*.sh` 腳本中更新以下變數：
   ```bash
   WA_PHONE="your_phone_number" # 例如：852xxxxxxx
   WA_API_KEY="your_api_key"
   ```

## 🛡️ Telegram 設定
我們強烈建議使用 Telegram（因為 CallMeBot 有免費額度限制），您可以使用 Telegram Bot。
- 詳細資訊請參閱 [Telegram 設定指南](telegram-remote.md)。

## 🛡️ 額外指南
- [SSH 安全升級指南](changessh.md) 
- 嘗試攻擊伺服器密碼 (pwd) 的暴力破解攻擊，可以透過修改 SSHD 預設 port 22 以及要求憑證認證，大大消除這些風險。
- 用以變更 SSH 埠號並強化存取權限的完整步驟指南。

## 📜 授權條款
MIT License - 開發者 [inchinet](https://github.com/inchinet)。歡迎自由使用及修改！
