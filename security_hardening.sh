#!/bin/bash

# =================================================================
# SECURITY HARDENING: OS-Level Protection
# =================================================================
# This script applies sysctl hardening and checks for system
# misconfigurations.
# =================================================================

# Configuration
LOG_FILE="/var/log/security-hardening.log"

# Ensure log file is writable
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/security-hardening.log"

exec > >(tee "$LOG_FILE") 2>&1

echo "[$(date)] Starting Security Hardening Check..."

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
    # Get listening TCP ports with their local address
    LISTENING_INFO=$(sudo ss -tulpn | grep LISTEN | awk '{print $5"|"$7}')
    
    echo "    - Analyzing active services..."
    
    # Standard ports for this cluster: 80, 443, 2222 (SSH), 11434 (Ollama), 3306 (MySQL), 53 (DNS), 9090 (Cockpit)
    FOUND_PORTS=""
    for entry in $LISTENING_INFO; do
        addr_port=$(echo $entry | cut -d'|' -f1)
        proc_info=$(echo $entry | cut -d'|' -f2)
        
        port=$(echo $addr_port | rev | cut -d: -f1 | rev)
        ip=$(echo $addr_port | rev | cut -d: -f2- | rev)

        # Build a list of found ports for summary
        FOUND_PORTS="$FOUND_PORTS $port"

        # Alert if port is not in whitelist
        if [[ "$port" != "80" && "$port" != "443" && "$port" != "2222" && "$port" != "8080" && "$port" != "11434" && "$port" != "3306" && "$port" != "33060" && "$port" != "53" && "$port" != "9090" ]]; then
            echo "    ⚠️ ALERT: Unexpected port listening: $port ($proc_info)"
        fi

        # Extra caution: Check if sensitive services are listening on public IP (0.0.0.0 or *)
        if [[ "$port" == "11434" || "$port" == "3306" || "$port" == "33060" || "$port" == "9090" ]]; then
            if [[ "$ip" == "*" || "$ip" == "0.0.0.0" || "$ip" == "::" ]]; then
                echo "    🚨 SECURITY: Service on port $port ($proc_info) is PUBLICLY EXPOSED ($ip). Bind to 127.0.0.1 or your LAN IP instead!"
            elif [[ "$ip" =~ ^192\.168\. || "$ip" =~ ^10\. || "$ip" =~ ^172\. ]]; then
                echo "    ℹ️ NOTE: Service on port $port is bound to LAN IP ($ip). Ensure your Router/Firewall restricts access!"
            fi
        fi
    done
    
    # Sort and clean the found ports list
    CLEAN_PORTS=$(echo $FOUND_PORTS | tr ' ' '\n' | sort -un | xargs)
    echo "    ✅ Monitored ports found: $CLEAN_PORTS"
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
