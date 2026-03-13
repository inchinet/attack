
# Linux Traffic & Security Monitor
Network intrusions not only waste your bandwidth, but also involve various forms of attacks.
A collection of lightweight shell scripts designed to protect Linux servers (specifically Ubuntu/Oracle Cloud) from automated attacks, DDoS attempts, and rapid-fire requests.
![Internet attack](https://github.com/inchinet/attack/blob/main/issue.png)

## 🚀 Overview

These scripts monitor your Apache/Web server logs. If an IP address exceeds a set threshold of requests within a single minute, the system automatically triggers a permanent ban using `fail2ban`.

### Key Features
- **Real-time Monitoring**: Scans access logs for traffic spikes.
- **Auto-Banning**: Automatically interfaces with `fail2ban-client` to ban malicious IPs.
- **WhatsApp/Telegram Alerts**: Sends detailed reports to your phone via [CallMeBot](https://www.callmebot.com/) or Telegram.
- **Jail-Specific Reporting**: Reports now show WHICH jail caught the IP (e.g., `[sshd]`, `[apache-auth]`).
- **Permanent Protection**: Optimized for `bantime = -1`.
- **Lightweight**: Pure Bash and AWK — no heavy dependencies.

---

## 🛠 Scripts included

| Script | Purpose |
| :--- | :--- |
| `trafficmonitor.sh` | **The Defense Patrol**. Analyzes logs and triggers active bans. |
| `sniper_monitor.sh` | **The Sniper Guard**. Instant bans for IPs touching sensitive files (`.env`, `.git`). |
| `securityofficer.sh` | **The Audit Report**. Summarizes all bans from the last 24 hours. |
| `server_health.sh` | **The Heartbeat**. Reports Disk, RAM, CPU, and Service status. |
| `security_hardening.sh` | **The Blacksmith**. Applies sysctl hardening and audits ports/SSH. |
| `update_guard.sh` | **The Watchman**. Daily check for pending security patches. |
| `config_guard.sh` | **The Vault Guard**. Audits permissions of .env and backup files. |
| `send_traffic_report.sh` | Wrapper to send traffic data via WhatsApp/Telegram. |
| `send_security_report.sh`| Wrapper to send the security audit via WhatsApp/Telegram. |

For Telegram, see section *Telegram Setup*
---
![Internet attack](https://github.com/inchinet/attack/blob/main/banip2.png)
![Internet attack](https://github.com/inchinet/attack/blob/main/issue2.png)

## 💡 Why trafficmonitor.sh is Necessary? (Fail2ban vs Traffic Monitor)
Bots sending a bunch of .env file requests in one second attempting to read/catch different folders credentials of your network as above example. This can be defensed using trafficmonitor.sh.
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
sudo touch /var/log/security-report.log /var/log/traffic-report.log /var/log/server-health.log \
           /var/log/security-hardening.log /var/log/update-guard.log /var/log/config-guard.log
sudo chown $(whoami):adm /var/log/security-report.log /var/log/traffic-report.log /var/log/server-health.log \
                       /var/log/security-hardening.log /var/log/update-guard.log /var/log/config-guard.log
sudo chmod 640 /var/log/security-report.log /var/log/traffic-report.log /var/log/server-health.log \
               /var/log/security-hardening.log /var/log/update-guard.log /var/log/config-guard.log
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

##  Self-Healing (Unkillable Guard)
To ensure Fail2ban automatically restarts if it ever crashes or is accidentally stopped:
1. Create the directory
```bash
sudo mkdir -p /etc/systemd/system/fail2ban.service.d
```
2. Force the settings into the file directly
```bash
echo -e "[Service]\nRestart=always\nRestartSec=5" | sudo tee /etc/systemd/system/fail2ban.service.d/override.conf
```
3. Reload your server settings
```bash
sudo systemctl daemon-reload
```
4. Prevent ban yourself
amend `trafficmonitor.sh` replace 0.123.456.789 with your own ip in whitelist, no comma in between:

```ini
WHITELIST="0.123.456.789 127.0.0.1 ::1"
```

### 4. Upload & Activate Scripts
Upload `trafficmonitor.sh`, `securityofficer.sh`,  `send_traffic_report.sh`, and `send_security_report.sh` to `/var/www/html`.

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
To receive automatic updates, add the following lines in `crontab -e`:
```bash
# Traffic report every hour
0 * * * * /var/www/html/send_traffic_report.sh >> /var/log/traffic-report.log 2>&1

# Security audit at 23:59 
59 23 * * * /var/www/html/send_security_report.sh >> /var/log/security-report.log 2>&1

# Server health report at 09:00
0 9 * * * /var/www/html/server_health.sh >> /var/log/server-health.log 2>&1
```

### 6. 🎯 Sniper Monitor (Background Service)
The `sniper_monitor.sh` is a **real-time** guard. It does not run via Cron; it should run as a background service to provide instant protection.

> [!TIP]
> **Precision Defense:** Sniper Monitor uses anchor-based regex to ensure it only bans when a forbidden file is the *actual* target. Safe visitors reading blog posts about `.env` or searching for `config.php` will **not** be banned. It only snipes direct hits on sensitive system files.

**Installation & Setup:**
1. Move the script to a system path:
```bash
sudo mv sniper_monitor.sh /usr/local/bin/
```
2. Set ownership and permissions (**Security best practice**):
```bash
# Only root should be able to edit security scripts
sudo chown root:root /usr/local/bin/sniper_monitor.sh
sudo chmod 755 /usr/local/bin/sniper_monitor.sh
```

3. Create the service file `/etc/systemd/system/sniper-monitor.service`:
```ini
[Unit]
Description=Sniper Security Monitor
After=network.target apache2.service fail2ban.service

[Service]
Type=simple
ExecStart=/usr/local/bin/sniper_monitor.sh
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
```
4. Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable sniper-monitor
sudo systemctl start sniper-monitor
```
for Restart

# 1. Stop the official service
```bash
sudo systemctl stop sniper-monitor
```
# 2. Kill any stray processes manually
```bash
sudo pkill -f sniper_monitor.sh
```
# 3. Start it back up
```bash
sudo systemctl start sniper-monitor
```


**How to check logs:**
* **Real-time monitor:**
```bash
sudo journalctl -u sniper-monitor -f
```
* **How many bans today?**
```bash
sudo journalctl -u sniper-monitor --since "24 hours ago" | grep "Banned" | wc -l
```
* **List all banned IPs:**
```bash
sudo journalctl -u sniper-monitor | awk '/Banned/ {for(i=1;i<=NF;i++) if($i=="Banned") print $(i+1)}' | sort -u
```


### 7. 🚀 check ban IP
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

*Example: Unban yourself if your server blocked its own IPv6 loopback:*
```bash
sudo fail2ban-client set apache-auth unbanip ::1
```

2. Unban an IP from ALL jails at once:
```bash
sudo fail2ban-client unban <IP_ADDRESS>
```

3. Manually ban an IP (if you want to test it):
```bash
sudo fail2ban-client set apache-auth banip <IP_ADDRESS>
```

### 8. 🛡️ OS Hardening & Maintenance
In addition to real-time monitoring, you should periodically run hardening audits.

**Run Hardening Audit:**
```bash
sudo chmod +x security_hardening.sh update_guard.sh config_guard.sh
sudo ./security_hardening.sh
```

**Automated Maintenance (Cron Jobs):**
Add these to `crontab -e` to automate your security audits:

```bash
# 1. Security update check (Every Sunday at 08:30)
30 8 * * 0 /var/www/html/update_guard.sh >> /var/log/update-guard.log 2>&1

# 2. Web permission audit (Every Sunday at 00:00)
0 0 * * 0 /var/www/html/config_guard.sh >> /var/log/config-guard.log 2>&1

# 3. Monthly OS hardening check (1st of every month at 01:00)
0 1 1 * * /var/www/html/security_hardening.sh >> /var/log/security-hardening.log 2>&1
```

**Safe Security Upgrades (One-by-One):**
On critical servers, running a full `apt upgrade` can be risky. It is safer to upgrade only the critical security packages flagged by `update_guard.sh` one-by-one.

```bash
# General Syntax
sudo apt-get install --only-upgrade <package_name>

# Recommended critical updates:
sudo apt-get install --only-upgrade sudo
sudo apt-get install --only-upgrade openssh-server openssh-client openssh-sftp-server
sudo apt-get install --only-upgrade curl libcurl4
```

---
## 🛡️ WhatsApp Alerts (CallMeBot)
This project uses **CallMeBot** to send WhatsApp notifications for free without installing any extra software.

### How to set up CallMeBot:
1. Add **+34 621 33 14 81** (or the robot's current number from [CallMeBot](https://www.callmebot.com/)) to your phone's contacts.
2. Send the message `"I allow callmebot to send me messages"` to that contact via WhatsApp.
3. You will receive an **API Key**.
4. Update the following variables in your `send_*.sh` scripts:
   ```bash
   WA_PHONE="your_phone_number" # e.g., 852xxxxxxx
   WA_API_KEY="your_api_key"
   ```

## 🛡️ Telegram Setup
Telegram is preferred (as callmebot will have free limit), you can use a Telegram Bot.
- See [Telegram Setup Guide](telegram-remote.md) for details.

## 🛡️ Extra Guides
- [SSH Security Upgrade Guide](changessh.md) 
- Brute-force attacks that try to attack your server (pwd), modification of SSHD port 22 and the requirement for cert authentication will largely eliminated many of these attacks.
- Complete step-by-step guide for changing your SSH port and hardening access.

## 📜 License
MIT License - Developed by [inchinet](https://github.com/inchinet). Feel free to use and modify!


