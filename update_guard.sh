#!/bin/bash

# =================================================================
# UPDATE GUARD: Security update checker
# =================================================================
# Checks for pending Ubuntu security updates and sends an optional
# notification. Host-specific delivery settings must be exported in
# the environment or placed in /etc/default/update-guard:
#
#   TG_TOKEN="123456:bot-token"
#   TG_CHAT_ID="123456789"
#   WA_CHAT_ID="phone_number@s.whatsapp.net"
#   WHATSAPP_BRIDGE_URL="http://localhost:3000/send"
# =================================================================

LOG_FILE="/var/log/update-guard.log"
CONFIG_FILE="/etc/default/update-guard"
APT_UPDATE_TIMEOUT=${APT_UPDATE_TIMEOUT:-180}
CURL_TIMEOUT=${CURL_TIMEOUT:-20}

if [ -r "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    . "$CONFIG_FILE"
fi

touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/update-guard.log"
exec > >(tee "$LOG_FILE") 2>&1

send_notification() {
    local message="$1"
    local host_name
    host_name=$(hostname)

    if [ "$host_name" = "oracloud2" ]; then
        echo "    - Host is oracloud2, sending to WhatsApp..."

        if [ -z "${WA_CHAT_ID:-}" ] || [ -z "${WHATSAPP_BRIDGE_URL:-}" ]; then
            echo "    - WhatsApp is not configured; set WA_CHAT_ID and WHATSAPP_BRIDGE_URL."
            return 1
        fi

        if ! command -v jq >/dev/null 2>&1; then
            echo "    - jq is not installed; cannot safely build WhatsApp JSON."
            return 1
        fi

        if [ -n "${FINAL_URL:-}" ]; then
            message="${message}
${FINAL_URL}"
        fi

        SAFE_MSG=$(printf '%s' "$message" | jq -Rs .)
        MESSAGE_RESULT=$(curl -sS --max-time "$CURL_TIMEOUT" -X POST "$WHATSAPP_BRIDGE_URL" \
            -H "Content-Type: application/json" \
            -d "{\"chatId\": \"${WA_CHAT_ID}\", \"message\": ${SAFE_MSG}}" 2>&1)
        echo "    - WhatsApp Result: $MESSAGE_RESULT"
    else
        echo "    - Host is not oracloud2, sending to Telegram..."

        if [ -z "${TG_TOKEN:-}" ] || [ -z "${TG_CHAT_ID:-}" ]; then
            echo "    - Telegram is not configured; set TG_TOKEN and TG_CHAT_ID."
            return 1
        fi

        curl -sS --max-time "$CURL_TIMEOUT" -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
            --data-urlencode "chat_id=${TG_CHAT_ID}" \
            --data-urlencode "text=${message}" \
            --data-urlencode "parse_mode=Markdown" \
            >/dev/null
        echo "    - Telegram notification sent."
    fi
}

echo "[$(date)] Checking for security updates..."

if ! command -v apt-get >/dev/null 2>&1; then
    echo "    - apt-get was not found; this script expects Ubuntu/Debian."
    echo "[$(date)] Update Guard check finished."
    exit 1
fi

APT_GET="apt-get"
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        APT_GET="sudo apt-get"
    else
        echo "    - This script must run as root because apt-get update needs the apt lock."
        echo "[$(date)] Update Guard check finished."
        exit 1
    fi
fi

echo "    - Running apt-get update with ${APT_UPDATE_TIMEOUT}s timeout..."
if ! timeout "$APT_UPDATE_TIMEOUT" $APT_GET update -qq; then
    echo "    - apt-get update failed; cannot determine pending security updates."
    echo "[$(date)] Update Guard check finished."
    exit 1
fi

UPGRADABLE=$(apt list --upgradable 2>/dev/null | tail -n +2 || true)
SECURITY_LINES=$(printf '%s\n' "$UPGRADABLE" | grep -E '(^|,)[^ ]*-security' || true)
PACKAGE_LIST=$(printf '%s\n' "$SECURITY_LINES" | cut -d/ -f1 | sed '/^[[:space:]]*$/d' | sort -u)
SECURITY_COUNT=$(printf '%s\n' "$PACKAGE_LIST" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')

if [ "$SECURITY_COUNT" -eq 0 ]; then
    echo "    - No pending security updates found."
    echo "[$(date)] Update Guard check finished."
    exit 0
fi

echo "    - Found $SECURITY_COUNT security updates: $(printf '%s' "$PACKAGE_LIST" | xargs)"

DATE_STR=$(date +"%Y-%m-%d %H:%M")
SERVER_NAME=${SERVER_NAME:-$(hostname -f 2>/dev/null || hostname)}

MESSAGE=$(cat <<EOF
[${SERVER_NAME}] Security Update Alert

Time: ${DATE_STR}
Found ${SECURITY_COUNT} pending security patches.

Packages:
${PACKAGE_LIST}

Action: Run 'sudo apt-get upgrade' to apply.
EOF
)

if send_notification "$MESSAGE"; then
    echo "    - Notification sent."
else
    echo "    - Notification failed."
fi

echo "[$(date)] Update Guard check finished."
