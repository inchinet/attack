---
description: How to send system alerts to Telegram from a remote Linux server without any installations (Zero-Install).
---

# Zero-Install System Alerts (Telegram)

This method allows you to deliver security and traffic reports from any Linux server without installing OpenClaw, Node.js, or any other bots. It is 100% sterile and uses standard `curl`.

## 1. Setup (60 Seconds)

### A. Create your Bot
1.  Open Telegram and message **@BotFather**.
2.  Send `/newbot`.
3.  Choose a name (e.g. `Server Monitor`).
4.  Choose a username ending in `bot` (e.g. `inchi_server_bot`).
5.  **Save the API Token** provided (e.g., `123456:ABC-DEF...`).

### B. Get your Chat ID
1.  Search for **@userinfobot** in Telegram and click **START**.
2.  **Save your ID** (a series of numbers, e.g., `98765432`).
3.  **Critical "Wake Up" Step**: Search for your newly created bot (e.g., `@inchinet_bot`) and click **START**. 
    *   *Note: If you don't do this, Telegram will block the script from sending you messages.*

---

## 2. Updated Production Scripts

Replace the `openclaw` line in your scripts with the following `curl` logic. Telegram supports Markdown, so we use `*` for bold.

### Changes for `prod_send_security_report.sh`
```bash
# REPLACING: openclaw message send --channel WhatsApp --target +852xxxxxxxx --message "$FULL_MESSAGE"
# WITH:
TG_TOKEN="YOUR_BOT_TOKEN_HERE"
TG_CHAT_ID="YOUR_CHAT_ID_HERE"

curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
     -d "chat_id=$TG_CHAT_ID" \
     -d "text=$FULL_MESSAGE" \
     -d "parse_mode=Markdown" >> "$LOG_FILE" 2>&1
```

### Changes for `prod_send_traffic_report.sh`
```bash
# REPLACING: openclaw message send --channel WhatsApp --target +852xxxxxxxx --message "$FULL_MESSAGE"
# WITH:
TG_TOKEN="YOUR_BOT_TOKEN_HERE"
TG_CHAT_ID="YOUR_CHAT_ID_HERE"

curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
     -d "chat_id=$TG_CHAT_ID" \
     -d "text=$FULL_MESSAGE" \
     -d "parse_mode=Markdown" >> "$LOG_FILE" 2>&1
```

---

## 3. Why this is the "Liquid Glass" Choice?
- **Extreme Safety**: No background services or Node.js runtimes. The server remains sterile.
- **Reliability**: Telegram does not have "full" slots like CallMeBot.
- **Rich Formatting**: Reports support bold text, italics, and code blocks for easy reading on your phone.
- **One-Way only**: The script only *sends* out. No incoming ports are opened.

## 4. Verification
Run this one-liner from your Linux terminal to test (Replace variables):
```bash
curl -s -X POST "https://api.telegram.org/botYOUR_TOKEN/sendMessage" -d "chat_id=YOUR_ID" -d "text=Test Message"
```
