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

# --- Security Patterns ---
# 1. Sensitive Files (Anchored: Must match a full segment like /.env or /config.php)
FILE_PATTERNS="\.env|\.git|wp-config|config\.php|phpmyadmin|setup\.php|xmlrpc\.php|\.aws|\.ssh"

# 2. Attack Signatures (Global: Highly malicious patterns that never appear in safe traffic)
# Covers: SQLi (Sleep, Union, Order By), XSS (Alert, Script), RCE (Base64, PHP Filters, Bin/Bash)
ATTACK_PATTERNS="union.*select|information_schema|--|sleep\(\d+\)|@@version|order.*by|<script|onerror=|onload=|alert\(|javascript:|etc/passwd|etc/shadow|\.\./|%2e%2e%2f|php://filter|base64_decode|bin/bash|bin/sh"

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
    # Advanced Detection: Check both Anchored Files and Global Attack Signatures
    if echo "$REQUEST_PATH" | grep -iE "(^|/)($FILE_PATTERNS)($|\?|/)" > /dev/null || \
       echo "$REQUEST_PATH" | grep -iE "($ATTACK_PATTERNS)" > /dev/null; then
        
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
