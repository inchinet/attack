
# Linux Traffic & Security Monitor

A collection of lightweight shell scripts designed to protect Linux servers (specifically Ubuntu/Oracle Cloud) from automated attacks, DDoS attempts, and rapid-fire requests.
![Internet attack](https://github.com/inchinet/attack/blob/main/issue.png)

## 🚀 Overview

These scripts monitor your Apache/Web server logs. If an IP address exceeds a set threshold of requests within a single minute, the system automatically triggers a permanent ban using `fail2ban`.

### Key Features
- **Real-time Monitoring**: Scans access logs for traffic spikes.
- **Auto-Banning**: Automatically interfaces with `fail2ban-client` to ban malicious IPs.
- **WhatsApp Alerts**: Sends detailed reports to your phone via [Clawdbot].
- **Jail-Specific Reporting**: Reports now show WHICH jail caught the IP (e.g., `[sshd]`, `[apache-auth]`).
- **Permanent Protection**: Optimized for `bantime = -1`.
- **Lightweight**: Pure Bash and AWK — no heavy dependencies.

---

## 🛠 Scripts included

| Script | Purpose |
| :--- | :--- |
| `trafficmonitor.sh` | **The Defense Patrol**. Analyzes logs and triggers active bans. |
| `securityofficer.sh` | **The Audit Report**. Summarizes all bans from the last 24 hours with jail names and countries. |
| `send_traffic_report.sh` | Wrapper to send traffic data via WhatsApp. |
| `send_security_report.sh`| Wrapper to send the security audit via WhatsApp. |

---

## ⚙️ Setup Instructions

### 1. Prerequisites
- **Fail2ban**: Must be installed and running.
- **adm Group**: Your user needs permission to read logs.
  ```bash
  sudo usermod -a -G adm $(whoami)
  # logout and login again for this to work
  ```

sudo touch /var/log/security-report.log /var/log/traffic-report.log
sudo chown ubuntuadmin:ubuntuadmin /var/log/security-report.log /var/log/traffic-report.log

### 2. Configure Fail2ban for Permanent Bans
Edit `/etc/fail2ban/jail.local` to enable permanent bans and monitor multiple log files (e.g., standard Apache and Clawdbot).

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
          /var/log/apache2/clawdbot_error.log

[apache-badbots]
enabled = true
port    = http,https
logpath = /var/log/apache2/access.log
          /var/log/apache2/clawdbot_access.log

[apache-noscript]
enabled = true
port    = http,https
logpath = /var/log/apache2/error.log
          /var/log/apache2/clawdbot_error.log
```

Apply changes:
```bash
sudo systemctl restart fail2ban
```

### 3. File Ownership & WindTerm Uploads
To prevent "Permission Denied" errors when uploading via WindTerm, set ownership to your user:
```bash
sudo chown -R $(whoami):www-data /var/www/html
sudo chmod -R 755 /var/www/html
```

---

## ⏰ Automation with Cron
To receive a daily summary at 09:00 AM:
1. Run `crontab -e`
2. Add the following lines:
```bash
# Traffic report every morning at 09:00 AM
0 9 * * * /var/www/html/send_traffic_report.sh >> /var/log/traffic-report.log 2>&1

# Security audit every morning at 09:00 AM
0 9 * * * /var/www/html/send_security_report.sh >> /var/log/security-report.log 2>&1
```

---

## 🛡️ Extra Guides
- [SSH Security Upgrade Guide](changessh.md) - Complete step-by-step guide for changing your SSH port and hardening access.

## 📜 License
MIT License - Developed by [inchinet](https://github.com/inchinet). Feel free to use and modify!


