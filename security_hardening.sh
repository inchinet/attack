#!/bin/bash

# =================================================================
# SECURITY HARDENING: OS-Level Protection
# =================================================================
# This script applies sysctl hardening and checks for system
# misconfigurations.
# =================================================================

echo "[$(date)] Starting Security Hardening Check..."

# 1. Apply Sysctl Hardening (Network Layer)
# Note: These require root to apply permanently via /etc/sysctl.conf
# We show them here for manual application or script execution.

apply_sysctl() {
    echo "[*] Applying Sysctl Hardening..."
    
    # Ignore ICMP Broadcasts (Prevent Smurf attacks)
    sudo sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1 > /dev/null
    
    # Ignore ICMP Redirects (Prevent MITM)
    sudo sysctl -w net.ipv4.conf.all.accept_redirects=0 > /dev/null
    sudo sysctl -w net.ipv4.conf.default.accept_redirects=0 > /dev/null
    
    # Ignore ICMP Source Routes
    sudo sysctl -w net.ipv4.conf.all.accept_source_route=0 > /dev/null
    
    # Enable SYN Cookies (DoS protection)
    sudo sysctl -w net.ipv4.tcp_syncookies=1 > /dev/null
    
    # Log Martians (Spoofed packets)
    sudo sysctl -w net.ipv4.conf.all.log_martians=1 > /dev/null
    
    echo "    - Network hardening applied."
}

# 2. Check for Open Ports
check_ports() {
    echo "[*] Checking listening ports..."
    # Get listening TCP ports
    OPEN_PORTS=$(sudo ss -tulpn | grep LISTEN | awk '{print $5}' | cut -d: -f2 | sort -u | xargs)
    echo "    - Open ports: $OPEN_PORTS"
    
    # Standard ports for this server: 80, 443, 2222 (SSH)
    # Check for anything else
    for port in $OPEN_PORTS; do
        if [[ "$port" != "80" && "$port" != "443" && "$port" != "2222" && "$port" != "8080" ]]; then
            echo "    ⚠️ ALERT: Unexpected port listening: $port"
        fi
    done
}

# 3. Verify SSH Hardening
check_ssh() {
    echo "[*] Verifying SSH configuration..."
    PASSWORD_AUTH=$(sudo grep "^PasswordAuthentication" /etc/ssh/sshd_config | awk '{print $2}')
    if [ "$PASSWORD_AUTH" == "yes" ]; then
        echo "    ❌ CRITICAL: PasswordAuthentication is still enabled! Disable it for security."
    else
        echo "    ✅ SSH PasswordAuthentication is disabled."
    fi
}

# 4. Check for World-Writable Files in sensitive areas
check_perms() {
    echo "[*] Checking for world-writable sensitive files..."
    WW_FILES=$(sudo find /etc -maxdepth 2 -perm -2 -type f 2>/dev/null)
    if [ -n "$WW_FILES" ]; then
        echo "    ⚠️ WARNING: Found world-writable files in /etc:"
        echo "$WW_FILES"
    else
        echo "    ✅ No world-writable files found in critical /etc paths."
    fi
}

# Execution
apply_sysctl
check_ports
check_ssh
check_perms

echo "[$(date)] Hardening check complete."
