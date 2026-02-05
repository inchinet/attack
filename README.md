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
| `send_traffic_report.sh` | Wrapper script to generate reports and send notifications. |

---

## ⚙️ Setup Instructions

### 1. Prerequisites
- **Fail2ban**: Must be installed and running.
- **Clawdbot**: (Optional) For WhatsApp notifications.
- **Apache**: Access logs should be in `/var/log/apache2/access.log`.

### 2. Configuration
Open `trafficmonitor.sh` and set your desired threshold:
```bash
THRESHOLD=60  # Maximum requests per minute
```

### 3. Automate with Cron
To run the check and send a report every night at 23:59:
1. Run `crontab -e`
2. Add the following line:
```bash
59 23 * * * /path/to/send_traffic_report.sh >> /var/log/traffic-report.log 2>&1
```

---

## 🔒 Security Note
Ensure these scripts are owned by your primary user or root and have restricted permissions:
```bash
chmod 700 send_traffic_report.sh
```

## 📜 License
MIT License - Feel free to use and modify!
