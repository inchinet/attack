#!/bin/bash

# Configuration
LOG_FILE="/var/log/traffic-report.log"
MONITOR_SCRIPT="/var/www/html/trafficmonitor.sh"

# Ensure log file is writable
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/traffic-report.log"

echo "$(date): Starting traffic report check" > "$LOG_FILE"

# Check if monitor script exists
if [ ! -f "$MONITOR_SCRIPT" ]; then
    echo "$(date): ERROR: $MONITOR_SCRIPT not found!" >> "$LOG_FILE"
    exit 1
fi

# Run the monitor script
OUTPUT=$("$MONITOR_SCRIPT")

if [ -n "$OUTPUT" ]; then
    MESSAGE_HEADER="=== Traffic Monitor Report ($(date)) ==="
    FULL_MESSAGE="${MESSAGE_HEADER}\n${OUTPUT}"
    
    # 1. Log the full report
    echo -e "$FULL_MESSAGE" >> "$LOG_FILE"
    
    # 2. OPTIONAL: Send via openclaw (Uncomment and set variables if using openclaw)
    # CHANNEL="WhatsApp"
    # TARGET="+85212345678"
    # openclaw message send --channel "$CHANNEL" --target "$TARGET" --message "$FULL_MESSAGE" >> "$LOG_FILE" 2>&1
    
    echo "$(date): Report generated and logged." >> "$LOG_FILE"
else
    echo "$(date): No traffic spikes to report." >> "$LOG_FILE"
fi

echo "$(date): Script finished." >> "$LOG_FILE"
