#!/bin/bash

# =================================================================
# CONFIG GUARD: Web Configuration Auditor
# =================================================================
# Audits permissions of sensitive files in the web root.
# =================================================================

WEB_ROOT="/var/www/html"
LOG_FILE="/var/log/config-guard.log"

echo "[$(date)] Starting Config Guard Audit..."

# 1. Check for .env files and their permissions
audit_env() {
    echo "[*] Checking .env files..."
    ENV_FILES=$(sudo find "$WEB_ROOT" -name ".env" 2>/dev/null)
    for f in $ENV_FILES; do
        PERMS=$(stat -c "%a" "$f")
        if [ "$PERMS" -gt 640 ]; then
            echo "    ⚠️ DANGER: $f has loose permissions ($PERMS). Should be 600 or 640."
        else
            echo "    ✅ $f permissions are secure ($PERMS)."
        fi
    done
}

# 2. Check for .git directories in web root
audit_git() {
    echo "[*] Checking for exposed .git directories..."
    GIT_DIRS=$(sudo find "$WEB_ROOT" -name ".git" -type d 2>/dev/null)
    if [ -n "$GIT_DIRS" ]; then
        echo "    ⚠️ WARNING: Exposed .git directories found in web root:"
        echo "$GIT_DIRS"
    else
        echo "    ✅ No exposed .git directories found."
    fi
}

# 3. Check for sensitive backup files (.sql, .zip, .tar, .bak)
audit_backups() {
    echo "[*] Checking for potentially sensitive backup files..."
    BACKUP_FILES=$(sudo find "$WEB_ROOT" -regex ".*\(.sql\|.zip\|.tar\|.bak\|.old\)$" 2>/dev/null)
    if [ -n "$BACKUP_FILES" ]; then
        echo "    ⚠️ WARNING: Found backup/old files in web root:"
        echo "$BACKUP_FILES"
    else
        echo "    ✅ No sensitive backup files found in web root."
    fi
}

# Execution
audit_env
audit_git
audit_backups

echo "[$(date)] Config Guard Audit complete."
