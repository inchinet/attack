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
currentdatetime=$(date +"%Y-%m-%d %H:%M")
if [ -n "$OUTPUT" ]; then
    SERVER_NAME=$(hostname)
    MESSAGE_HEADER="[$SERVER_NAME] *Traffic Monitor Report ($currentdatetime):*"
    FULL_MESSAGE="${MESSAGE_HEADER}

${OUTPUT}"

    # Deliver report via shared notification script
    if /var/www/html/notify.sh "$FULL_MESSAGE" >> "$LOG_FILE" 2>&1; then
        echo "$(date): Report delivered successfully." >> "$LOG_FILE"
    else
        echo "$(date): Report delivery failed." >> "$LOG_FILE"
    fi
else
    echo "$(date): No traffic spikes to report." >> "$LOG_FILE"
fi

echo "$(date): Script finished." >> "$LOG_FILE"
