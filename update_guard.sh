#!/bin/bash

# =================================================================
# UPDATE GUARD: Security Patch Monitor
# =================================================================
# Checks for pending security updates and alerts via Telegram.
# =================================================================

# Configuration
TG_TOKEN="YOUR_TOKEN"
TG_CHAT_ID="YOUR_ID"
SERVER_NAME=$(hostname)
LOG_FILE="/var/log/update-guard.log"

# Ensure log file is writable
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/update-guard.log"

echo "[$(date)] Checking for security updates..." > "$LOG_FILE"

# 1. Update package lists (Requires root)
sudo apt-get update > /dev/null

# 2. Extract security updates
UPDATE_LIST=$(apt-get -s upgrade | grep -i security | grep ^Inst | awk '{print $2}' | xargs)

# Count words in the list safely
if [ -z "$UPDATE_LIST" ]; then
    SECURITY_UPDATES=0
else
    SECURITY_UPDATES=$(echo "$UPDATE_LIST" | wc -w)
fi

if [ "$SECURITY_UPDATES" -gt 0 ]; then
    echo "    - Found $SECURITY_UPDATES security updates: $UPDATE_LIST" >> "$LOG_FILE"
    
    # Construct Message
    DATE_STR=$(date +"%Y-%m-%d %H:%M")
    MESSAGE="🛠️ *[$SERVER_NAME] Security Update Alert* 🛠️
    
Time: $DATE_STR
Found *$SECURITY_UPDATES* pending security patches.

*Packages:*
\`$UPDATE_LIST\`

*Action:* Run 'sudo apt-get upgrade' to apply."

    # Send via Telegram
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
         -d "chat_id=$TG_CHAT_ID" \
         -d "text=$MESSAGE" \
         -d "parse_mode=Markdown" >> "$LOG_FILE" 2>&1
    
    echo "    - Notification sent to Telegram." >> "$LOG_FILE"
else
    echo "    - System is up to date." >> "$LOG_FILE"
fi

echo "[$(date)] Update Guard check finished." >> "$LOG_FILE"
