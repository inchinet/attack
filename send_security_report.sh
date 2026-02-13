#!/bin/bash

LOG_FILE="/var/log/security-report.log"
OFFICER_SCRIPT="./securityofficer.sh"

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

if [ -n "$OUTPUT" ]; then
    MESSAGE_HEADER="=== Security Officer Report ($(date)) ==="
    FULL_MESSAGE="${MESSAGE_HEADER}\n${OUTPUT}"
    
    # 1. Log the full report
    echo -e "$FULL_MESSAGE" >> "$LOG_FILE"
    
    # 2. OPTIONAL: Send via openclaw (Uncomment and set variables if using openclaw)
    # CHANNEL="WhatsApp"
    # TARGET="+85212345678"
    # openclaw message send --channel "$CHANNEL" --target "$TARGET" --message "$FULL_MESSAGE" >> "$LOG_FILE" 2>&1
    
    echo "$(date): Security incidents logged." >> "$LOG_FILE"
else
    echo "$(date): No security incidents to report." >> "$LOG_FILE"
fi

echo "$(date): Script finished." >> "$LOG_FILE"
