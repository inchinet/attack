# Linux Traffic & Security Monitor

A collection of lightweight shell scripts designed to protect Linux servers (specifically Ubuntu/Oracle Cloud) from automated attacks, DDoS attempts, and rapid-fire requests.


## 🚀 Overview

These scripts monitor your Apache/Web server access logs in real-time. If an IP address exceeds a set threshold of requests within a single minute, the system automatically triggers a permanent ban using `fail2ban`.

### Key Features
- **Real-time Monitoring**: Scans access logs for traffic spikes.
- **Auto-Banning**: Automatically interfaces with `fail2ban-client` to ban malicious IPs.
- **WhatsApp Alerts**: Sends detailed reports to your phone via [Clawdbot].
- **Configurable Thresholds**: Easily adjust the sensitivity (e.g., ban after 60 requests/min).
- **Lightweight**: Pure Bash and AWK — no heavy dependencies.

---

## 🛠 Scripts included

| Script | Purpose |
| :--- | :--- |
| `trafficmonitor.sh` | The core engine. Analyzes logs and triggers bans. |
| `send_traffic_report.sh` | Wrapper script to generate traffic reports and send notifications. |
| `securityofficer.sh` | Scans for suspicious authentication failures over the last 24 hours. |
| `send_security_report.sh` | Generates security incident reports and sends alerts. |

---

## ⚙️ Setup Instructions

### 1. Prerequisites
- **Fail2ban**: Must be installed and running.
- **OpenClaw/Clawdbot**: (Optional) For WhatsApp / etc notifications.
- **Apache**: Access logs should be in `/var/log/apache2/access.log`.

### 2. about fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local
(bantime = -1 meant permanent ban)

```bash
[DEFAULT]
bantime = -1

[apache-auth]
enabled = true
port    = http,https
logpath = %(apache_error_log)s
```

sudo systemctl restart fail2ban

### 3. Configuration
Open `trafficmonitor.sh` and set your desired threshold:
```bash
THRESHOLD=60  # Maximum requests per minute
```

### 4. Automate with Cron
To run the check and send a report every night at 23:59:
1. Run `crontab -e`
2. Add the following line:
```bash
# Traffic report every night at 23:59
59 23 * * * /path/to/send_traffic_report.sh >> /var/log/traffic-report.log 2>&1

# Security incident report every night at 23:59
59 23 * * * /path/to/send_security_report.sh >> /var/log/security-report.log 2>&1
```

---

## 🔒 Security Note
Ensure these scripts are owned by your primary user or root and have restricted permissions:
```bash
chmod 700 send_traffic_report.sh
chmod 700 send_security_report.sh
```

## 📜 License
MIT License - Feel free to use and modify!
