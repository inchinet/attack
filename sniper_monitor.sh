#!/bin/bash

# =================================================================
# SNIPER MONITOR: Instant Security Defense
# =================================================================
# Difference from trafficmonitor.sh:
# - trafficmonitor.sh: Detects VOLUME (Speed). Bans if > 60 req/min.
# - sniper_monitor.sh: Detects INTENT (Target). Bans INSTANTLY if they
#   touch a single forbidden file, regardless of speed.
# =================================================================

# Configuration
LOG_FILE="/var/log/apache2/access.log"
JAIL="apache-auth"
TG_TOKEN="8346252427:AAE7Armqa3XVfAwjZmFdrFeEq_ttUbWGI-s"
TG_CHAT_ID="187681362"
SERVER_NAME=$(hostname)

# Forbidden Patterns (Regex)
# These are files/folders that NO legitimate user should ever touch.
FORBIDDEN_PATTERNS="\.env|\.git|wp-config|config\.php|phpmyadmin|setup\.php|xmlrpc\.php|\.aws|\.ssh"

echo "[$(date)] Sniper Monitor started. Watching $LOG_FILE..."

# Use 'tail' to read new log lines in real-time
tail -Fn0 "$LOG_FILE" | while read -r line; do
    
    # Check if the line contains a forbidden pattern
    if echo "$line" | grep -iE "$FORBIDDEN_PATTERNS" > /dev/null; then
        
        # Extract the IP address (first field in standard Apache logs)
        IP=$(echo "$line" | awk '{print $1}')
        
        # Extract the requested path for the report
        REQUEST=$(echo "$line" | awk -F'"' '{print $2}')
        
        # INSTANT BAN
        sudo fail2ban-client set "$JAIL" banip "$IP" > /dev/null 2>&1
        
        # Send Immediate Telegram Notification
        DATE_STR=$(date +"%Y-%m-%d %H:%M:%S")
        MESSAGE="🛡️ *SNIPER BAN: Critical Intent Detected!* 🛡️

*Server:* $SERVER_NAME
*Time:* $DATE_STR
*Attacker IP:* $IP
*Target File:* $REQUEST

*Action:* Permanent ban applied inside jail [$JAIL] instantly."

        curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
             -d "chat_id=$TG_CHAT_ID" \
             -d "text=$MESSAGE" \
             -d "parse_mode=Markdown" > /dev/null 2>&1
             
        echo "[$DATE_STR] Banned $IP for attempting to access $REQUEST"
    fi
done
