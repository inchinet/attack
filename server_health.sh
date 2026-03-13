#!/bin/bash

# Configuration
# WA_PHONE="85298826994"
# WA_API_KEY="6157122"
TG_TOKEN="8346252427:AAE7Armqa3XVfAwjZmFdrFeEq_ttUbWGI-s"
TG_CHAT_ID="187681362"
SERVER_NAME=$(hostname)
LOG_FILE="/var/log/server-health.log"

# Thresholds
DISK_LIMIT=90
MEM_LOW_GB=2    # Alert if less than 2GB free
LOAD_LIMIT=4.0  # Alert if load is > 4.0 (your 4-CPU system)

# Ensure log file is writable
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/server-health.log"

# 1. Check Disk Usage
DISK_USAGE=$(df / | grep / | awk '{ print $5 }' | sed 's/%//')

# 2. Check RAM (Available GB)
MEM_AVAILABLE=$(free -g | grep Mem | awk '{print $7}')

# 3. Check Load Average (1 min)
LOAD_AVG=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)

# 4. Check Services
APACHE_STATUS=$(systemctl is-active apache2)
F2B_STATUS=$(systemctl is-active fail2ban)

# 5. Build the Health Message
DATE_STR=$(date +"%Y-%m-%d %H:%M")
STATUS_EMOJI="✅"
ALERT_FOUND=false

# Auto-detect if something is wrong
if [ "$DISK_USAGE" -gt "$DISK_LIMIT" ] || [ "$MEM_AVAILABLE" -lt "$MEM_LOW_GB" ] || [ "$(echo "$LOAD_AVG > $LOAD_LIMIT" | bc -l)" -eq 1 ] || [ "$APACHE_STATUS" != "active" ] || [ "$F2B_STATUS" != "active" ]; then
    STATUS_EMOJI="⚠️"
    ALERT_FOUND=true
fi

# Construct Message
MESSAGE="[$SERVER_NAME] $STATUS_EMOJI *Server Health Report ($DATE_STR)*

📦 *Disk:* ${DISK_USAGE}% used
🧠 *RAM:* ${MEM_AVAILABLE}GB Available
📈 *Load:* ${LOAD_AVG}
🚀 *Apache:* ${APACHE_STATUS}
🛡️ *Fail2ban:* ${F2B_STATUS}"

# Add specific warning text if alerts were found
if [ "$ALERT_FOUND" = true ]; then
    MESSAGE="${MESSAGE}

🛑 *Attention Required: One or more parameters exceed safe thresholds!*"
fi

# Send via Telegram
echo "$DATE_STR: Resulting status: $STATUS_EMOJI" > "$LOG_FILE"

curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
     -d "chat_id=$TG_CHAT_ID" \
     -d "text=$MESSAGE" \
     -d "parse_mode=Markdown" >> "$LOG_FILE" 2>&1

# --- Delivery: WhatsApp (Commented Out) ---
# curl -s -G "https://api.callmebot.com/whatsapp.php" \
#      --data-urlencode "phone=$WA_PHONE" \
#      --data-urlencode "text=$MESSAGE" \
#      --data-urlencode "apikey=$WA_API_KEY" >> "$LOG_FILE" 2>&1

echo "Report sent to Telegram."
