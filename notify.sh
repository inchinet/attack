#!/bin/bash

# =================================================================
# NOTIFY: Shared notification dispatcher
# =================================================================
# This script handles message delivery based on the server identity.
# Config is read from /etc/default/update-guard
#
# Server 'oracloud2' -> WhatsApp (via Hermes)
# Other servers     -> Telegram
# =================================================================

CONFIG_FILE="/etc/default/update-guard"
CURL_TIMEOUT=20

# Load configuration
if [ -r "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    . "$CONFIG_FILE"
fi

MESSAGE="$1"

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 \"message text\""
    exit 1
fi

HOST_NAME=$(hostname)

if [ "$HOST_NAME" = "oracloud2" ]; then
    # --- WhatsApp Delivery (via Hermes) ---
    if [ -z "${WA_CHAT_ID:-}" ] || [ -z "${WHATSAPP_BRIDGE_URL:-}" ]; then
        echo "Error: WhatsApp not configured (WA_CHAT_ID or WHATSAPP_BRIDGE_URL missing)."
        exit 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is not installed; cannot safely build WhatsApp JSON."
        exit 1
    fi

    if [ -n "${FINAL_URL:-}" ]; then
        MESSAGE="${MESSAGE}
${FINAL_URL}"
    fi

    SAFE_MSG=$(printf '%s' "$MESSAGE" | jq -Rs .)
    RESULT=$(curl -sS --max-time "$CURL_TIMEOUT" -X POST "$WHATSAPP_BRIDGE_URL" \
        -H "Content-Type: application/json" \
        -d "{\"chatId\": \"${WA_CHAT_ID}\", \"message\": ${SAFE_MSG}}" 2>&1)

    echo "WhatsApp Result: $RESULT"
else
    # --- Telegram Delivery ---
    if [ -z "${TG_TOKEN:-}" ] || [ -z "${TG_CHAT_ID:-}" ]; then
        echo "Error: Telegram not configured (TG_TOKEN or TG_CHAT_ID missing)."
        exit 1
    fi

    RESULT=$(curl -sS --max-time "$CURL_TIMEOUT" -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        --data-urlencode "chat_id=${TG_CHAT_ID}" \
        --data-urlencode "text=${MESSAGE}" \
        --data-urlencode "parse_mode=Markdown" 2>&1)

    echo "Telegram Result: $RESULT"
fi
