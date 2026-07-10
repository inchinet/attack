#!/bin/bash

# =================================================================
# NOTIFY: Shared notification dispatcher
# =================================================================
# Config is read from /etc/default/update-guard
#
# oracloud2 → WhatsApp via wa-gateway (whatsapp-web.js, systemd service)
#   WA_GATEWAY_URL=http://localhost:3001/api/send
#   WA_CHAT_ID, WA_TOKEN — set in /etc/default/update-guard
#   Auto-falls back to Telegram if wa-gateway is down.
#
# cwchin / others → Telegram only
#   TG_TOKEN, TG_CHAT_ID — set in /etc/default/update-guard
#
# --- HISTORY ---
# 2026-07-01: Hermes/Baileys rc13 broke — "failed to ack notification"
# 2026-07-09: Replaced with whatsapp-web.js (wa-gateway) — WORKING ✅
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

if [ -n "${FINAL_URL:-}" ]; then
    MESSAGE="${MESSAGE}
${FINAL_URL}"
fi

# =================================================================
# WhatsApp via wa-gateway (whatsapp-web.js on oracloud2)
# Auto-falls back to Telegram if wa-gateway is not running.
# =================================================================
if [ -n "${WA_GATEWAY_URL:-}" ] && [ -n "${WA_CHAT_ID:-}" ] && [ -n "${WA_TOKEN:-}" ]; then

    if ! command -v jq > /dev/null 2>&1; then
        echo "Warning: jq not installed, skipping WhatsApp."
    else
        SAFE_MSG=$(printf '%s' "$MESSAGE" | jq -Rs .)
        RESULT=$(curl -sS --max-time "$CURL_TIMEOUT" -X POST "${WA_GATEWAY_URL}" \
            -H "Content-Type: application/json" \
            -H "x-token: ${WA_TOKEN}" \
            -d "{\"chatId\": \"${WA_CHAT_ID}\", \"message\": ${SAFE_MSG}}" 2>&1)
        CURL_EXIT=$?

        if [ $CURL_EXIT -eq 0 ] && echo "$RESULT" | grep -q '"success":true'; then
            echo "WhatsApp Result: OK"
            exit 0
        else
            echo "WhatsApp unavailable (${RESULT}), falling back to Telegram..."
        fi
    fi
fi

# =================================================================
# HERMES BRIDGE — DISABLED (broken since 2026-07-01)
# Baileys rc13 QR pairing bug: "failed to ack notification"
# Kept here for reference. Re-enable when Baileys is fixed.
# =================================================================
# HOST_NAME=$(hostname)
# if [ "$HOST_NAME" = "oracloud2" ]; then
#     if [ -z "${WA_CHAT_ID:-}" ] || [ -z "${WHATSAPP_BRIDGE_URL:-}" ]; then
#         echo "Error: WhatsApp not configured (WA_CHAT_ID or WHATSAPP_BRIDGE_URL missing)."
#         exit 1
#     fi
#     if ! command -v jq > /dev/null 2>&1; then
#         echo "Error: jq is not installed; cannot safely build WhatsApp JSON."
#         exit 1
#     fi
#     SAFE_MSG=$(printf '%s' "$MESSAGE" | jq -Rs .)
#     RESULT=$(curl -sS --max-time "$CURL_TIMEOUT" -X POST "$WHATSAPP_BRIDGE_URL" \
#         -H "Content-Type: application/json" \
#         -d "{\"chatId\": \"${WA_CHAT_ID}\", \"message\": ${SAFE_MSG}}" 2>&1)
#     echo "WhatsApp Result: $RESULT"
#     exit 0
# fi

# =================================================================
# Telegram fallback (used when WA_GATEWAY_URL not configured)
# =================================================================
if [ -z "${TG_TOKEN:-}" ] || [ -z "${TG_CHAT_ID:-}" ]; then
    echo "Error: No notification configured (WA_GATEWAY_URL or TG_TOKEN missing)."
    exit 1
fi

RESULT=$(curl -sS --max-time "$CURL_TIMEOUT" -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TG_CHAT_ID}" \
    --data-urlencode "text=${MESSAGE}" \
    --data-urlencode "parse_mode=Markdown" 2>&1)

echo "Telegram Result: $RESULT"
