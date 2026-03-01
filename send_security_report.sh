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
currentdatetime=$(date +"%Y-%m-%d %H:%M")
if [ -n "$OUTPUT" ]; then
    MESSAGE_HEADER="=== Security Officer Report ($currentdatetime) ==="
    FULL_MESSAGE="${MESSAGE_HEADER}\n${OUTPUT}"
    
  # 1. Log the full report
    echo -e "$FULL_MESSAGE" >> "$LOG_FILE"
    
  # 2. OPTIONAL: 
  # --- Delivery: WhatsApp (CallMeBot) ---
  # Replace with your phone and the API key you just got
  # WA_PHONE="85212345678" 
  # WA_API_KEY="1234567"
  
  # curl -s -G "https://api.callmebot.com/whatsapp.php" \
  #     --data-urlencode "phone=$WA_PHONE" \
  #     --data-urlencode "text=$FULL_MESSAGE" \
  #     --data-urlencode "apikey=$WA_API_KEY" >> "$LOG_FILE" 2>&1
    
    echo "$(date): Security incidents logged." >> "$LOG_FILE"
else
    echo "$(date): No security incidents to report." >> "$LOG_FILE"
fi

echo "$(date): Script finished." >> "$LOG_FILE"
