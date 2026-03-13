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
TG_TOKEN="YOUR_TOKEN"
TG_CHAT_ID="YOUR_ID"
SERVER_NAME=$(hostname)
WHITELIST="0.123.456.789 127.0.0.1 ::1"

# Forbidden Patterns (Regex)
# These are files/folders or attack signatures that NO legitimate user should ever touch.
# Precision regex: We match against the requested path.
# Covers: Sensitive files (.env, .git), SQLi (union select), XSS (<script), Path Traversal (etc/passwd).
FORBIDDEN_PATTERNS="\.env|\.git|wp-config|config\.php|phpmyadmin|setup\.php|xmlrpc\.php|\.aws|\.ssh|union.*select|information_schema|--|<script|onerror=|onload=|etc/passwd|etc/shadow|\.\./|bin/bash|bin/sh"

echo "[$(date)] Sniper Monitor started. Watching $LOG_FILE..."

# Use 'tail' to read new log lines in real-time
tail -Fn0 "$LOG_FILE" | while read -r line; do
    
    # 1. Extract the IP address
    IP=$(echo "$line" | awk '{print $1}')
    
    # 2. Extract the requested URI (e.g., "GET /admin HTTP/1.1")
    FULL_REQUEST=$(echo "$line" | awk -F'"' '{print $2}')
    
    # 3. Extract just the PATH (e.g., "/admin")
    REQUEST_PATH=$(echo "$FULL_REQUEST" | awk '{print $2}')

    # Bulletproof Logic: Match only if it's a full path segment (starts with / or start, ends with ?, / or end)
    # This prevents banning "yoursite.com/blog/how-to-fix-config.php" (Safe)
    # But it WILL ban "yoursite.com/config.php" or "yoursite.com/dir/config.php?id=1" (Ban!)
    if echo "$REQUEST_PATH" | grep -iE "(^|/)($FORBIDDEN_PATTERNS)($|\?|/)" > /dev/null; then
        
        # Whitelist Check
        if echo " $WHITELIST " | grep -Fq " $IP "; then
            # echo "Whitelisted IP $IP tried to access forbidden $REQUEST_PATH - Ignored."
            continue
        fi

        # INSTANT BAN
        sudo fail2ban-client set "$JAIL" banip "$IP" > /dev/null 2>&1
        
        # Send Immediate Telegram Notification
        DATE_STR=$(date +"%Y-%m-%d %H:%M:%S")
        MESSAGE="🛡️ *SNIPER BAN: Critical Intent Detected!* 🛡️

*Server:* $SERVER_NAME
*Time:* $DATE_STR
*Attacker IP:* $IP
*Target File:* $REQUEST_PATH

*Action:* Permanent ban applied inside jail [$JAIL] instantly."

        curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
             -d "chat_id=$TG_CHAT_ID" \
             -d "text=$MESSAGE" \
             -d "parse_mode=Markdown" > /dev/null 2>&1
             
        echo "[$DATE_STR] Banned $IP for attempting to access $REQUEST_PATH"
    fi
done
