
# Linux Traffic & Security Monitor

A collection of lightweight shell scripts designed to protect Linux servers (specifically Ubuntu/Oracle Cloud) from automated attacks, DDoS attempts, and rapid-fire requests.
![Internet attack](https://github.com/inchinet/attack/blob/main/issue.png)

## 🚀 Overview

These scripts monitor your Apache/Web server logs. If an IP address exceeds a set threshold of requests within a single minute, the system automatically triggers a permanent ban using `fail2ban`.

### Key Features
- **Real-time Monitoring**: Scans access logs for traffic spikes.
- **Auto-Banning**: Automatically interfaces with `fail2ban-client` to ban malicious IPs.
- **WhatsApp Alerts**: Sends detailed reports to your phone via [OpenClaw].
- **Jail-Specific Reporting**: Reports now show WHICH jail caught the IP (e.g., `[sshd]`, `[apache-auth]`).
- **Permanent Protection**: Optimized for `bantime = -1`.
- **Lightweight**: Pure Bash and AWK — no heavy dependencies.

---

## 🛠 Scripts included

| Script | Purpose |
| :--- | :--- |
| `trafficmonitor.sh` | **The Defense Patrol**. Analyzes logs and triggers active bans. |
| `securityofficer.sh` | **The Audit Report**. Summarizes all bans from the last 24 hours with jail names and countries. |
| `send_traffic_report.sh` | Wrapper to send traffic data (use openclaw via WhatsApp). |
| `send_security_report.sh`| Wrapper to send the security audit (use openclaw via WhatsApp). |

---

## 💡 Why trafficmonitor.sh is Necessary? (Fail2ban vs Traffic Monitor)

A common question is: *"Why doesn't Fail2ban catch these high-volume attacks automatically?"*

### 1. Different Log Files
*   **Fail2ban (Standard Jails):** Typically watches `error.log`. It is looking for explicit failures like "Password mismatch" or "User not found".
*   **The Attacks:** High-volume requests (bots scanning for vulnerabilities or bad crawlers) often show up as "200 OK" or "404 Not Found" in `access.log`.
*   **The Conflict:** Since standard Fail2ban isn't watching `access.log`, it is completely blind to the "speed" of the traffic. It only cares if they failed a login.

### 2. Different Criteria
*   **Fail2ban (Standard Jails):** Counts "retries". E.g., "3 failed attempts in 10 minutes."
*   **TrafficMonitor.sh:** Counts "speed". E.g., "30 requests in 1 minute."  (THRESHOLD=30 is configurable)

### The Solution
`trafficmonitor.sh` acts as a custom **"DoS Detector"**:
1.  It reads the `access.log` (which standard Fail2ban ignores).
2.  It counts the *volume* (which Fail2ban isn't counting).
3.  When it finds an IP exceeding the threshold (e.g., 30 req/min), it manually triggers `fail2ban-client` to ban them immediately.

---

## ⚙️ Setup Instructions

### 1. Prerequisites
- **Fail2ban**: Must be installed and running.
- **Root/Sudo Access**: You need sudo privileges to configure these settings.

### 2. Environment & Permissions Set Up
Run the following commands to configure your user groups and file permissions. This ensures you can read logs and upload scripts securely.

```bash
# 1. Allow yourself to read system logs (adm group)
sudo usermod -a -G adm $(whoami)

# 2. Allow yourself to manage web files (www-data group)
sudo usermod -a -G www-data $(whoami)

# 3. Create log files and set strict permissions (640)
# (640 = Owner RW, Group R, Others None)
sudo touch /var/log/security-report.log /var/log/traffic-report.log
sudo chown $(whoami):adm /var/log/security-report.log /var/log/traffic-report.log
sudo chmod 640 /var/log/security-report.log /var/log/traffic-report.log
```
Please LOG OUT and log in for group changes to take effect.


### 3. Configure Fail2ban for Permanent Bans
Edit `/etc/fail2ban/jail.local` to enable permanent bans and monitor multiple log files (e.g., standard Apache).

```bash
sudo nano /etc/fail2ban/jail.local
```

**Recommended Configuration:**
```ini
[DEFAULT]
bantime = -1

[apache-auth]
enabled = true
port    = http,https
logpath = /var/log/apache2/error.log

[apache-badbots]
enabled = true
port    = http,https
logpath = /var/log/apache2/access.log


[apache-noscript]
enabled = true
port    = http,https
logpath = /var/log/apache2/error.log

```

Apply changes:
```bash
sudo systemctl restart fail2ban
```

### 4. Upload & Activate Scripts
Upload `trafficmonitor.sh`, `securityofficer.sh`, `send_traffic_report.sh`, and `send_security_report.sh` to `/var/www/html`.

**Set Strict Permissions (Only for these scripts):**
Do not modify the entire folder. Just secure the scripts.
```bash
cd /var/www/html
sudo chown $(whoami):www-data trafficmonitor.sh securityofficer.sh send_*.sh
sudo chmod 740 trafficmonitor.sh securityofficer.sh send_*.sh
```
*(740 = Owner can write/execute, Group can read only, Others cannot access)*

---

## 🔐 Permissions for Automation (Sudoers)
Since these scripts use `sudo` inside (to ban IPs and read secure logs), they need to run without a password prompt when automated.

### Option 1: Run as Root (Recommended)
Add the cron jobs to the **root** crontab. This is the simplest and most secure method.
1. Run `sudo crontab -e`
2. Add the lines from the "Automation with Cron" section below.

### Option 2: Configure `visudo` (Standard User)
If you run the cron jobs as your standard user (Run `crontab -e`), you must allow passwordless execution for the required commands.
1. Run `sudo visudo`
2. Add the following lines at the bottom (replace `your_username`):
   ```bash
   your_username ALL=(ALL) NOPASSWD: /usr/bin/awk
   your_username ALL=(ALL) NOPASSWD: /usr/bin/grep
   your_username ALL=(ALL) NOPASSWD: /usr/bin/fail2ban-client
   ```

---

### 5. ⏰ Automation with Cron
To receive a daily summary, add the following lines in `crontab -e`:
```bash
# Traffic report every hour
0 * * * * /var/www/html/send_traffic_report.sh >> /var/log/traffic-report.log 2>&1

# Security audit at 23:59 
59 23 * * * /var/www/html/send_security_report.sh >> /var/log/security-report.log 2>&1
```

### 6. 🚀 check ban IP
```bash
sudo fail2ban-client status apache-auth
sudo fail2ban-client status apache-noscript
sudo fail2ban-client status apache-badbots
sudo fail2ban-client status sshd
```

1. remove/unban ip from jail if need
```bash
sudo fail2ban-client set apache-auth unbanip <IP_ADDRESS>
```

2. Unban an IP from ALL jails at once:
```bash
sudo fail2ban-client unban <IP_ADDRESS>
```

3. Manually ban an IP (if you want to test it):
```bash
sudo fail2ban-client set apache-auth banip <IP_ADDRESS>
```
---

## 🛡️ Extra Guides
- [SSH Security Upgrade Guide](changessh.md) - Complete step-by-step guide for changing your SSH port and hardening access.

## 📜 License
MIT License - Developed by [inchinet](https://github.com/inchinet). Feel free to use and modify!


