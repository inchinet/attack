#!/bin/bash

LOG_FILE="/var/log/security-report.log"
OFFICER_SCRIPT="/var/www/html/securityofficer.sh"

# Ensure log file is writable
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/security-report.log"

echo "$(date): Starting security report check" > "$LOG_FILE"

# Check if officer script exists
if [ ! -f "$OFFICER_SCRIPT" ]; then
    echo "$(date): ERROR: $OFFICER_SCRIPT not found!" >> "$LOG_FILE"
    exit 1
fi

# Run the officer script
OUTPUT=$("$OFFICER_SCRIPT")
currentdatetime=$(date +"%Y-%m-%d %H:%M")
if [ -n "$OUTPUT" ]; then
    SERVER_NAME=$(hostname)
    MESSAGE_HEADER="[$SERVER_NAME] *Security Officer Report ($currentdatetime):*"
    FULL_MESSAGE="${MESSAGE_HEADER}

${OUTPUT}"

    # Deliver report via shared notification script
    if /var/www/html/notify.sh "$FULL_MESSAGE" >> "$LOG_FILE" 2>&1; then
        echo "$(date): Report delivered successfully." >> "$LOG_FILE"
    else
        echo "$(date): Report delivery failed." >> "$LOG_FILE"
    fi
else
    echo "$(date): No security incidents to report." >> "$LOG_FILE"
fi

echo "$(date): Script finished." >> "$LOG_FILE"
