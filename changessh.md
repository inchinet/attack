# SSH Security Upgrade Guide

Changing your SSH port and disabling passwords is the most effective way to stop the "background noise" you see in your logs.

![banip](https://github.com/inchinet/attack/blob/main/banip.png)

## 🛡️ Security Concept
When you set `PasswordAuthentication no`, the server **ignores everyone** who tries to log in with a password. It will only talk to people who have your **SSH Private Key**.

> [!IMPORTANT]
> **To answer your question:** Even if an attacker ("outcomer") finds your new port (2345), they **cannot get in** without your private key. They can't even "guess" a password because the server won't even ask for one.
>
> **Note for WindTerm/Existing users:** If you already have a cert/key that works, you **do not** need to generate a new one. Just change the port in your connection settings.

---

## 📝 Step-by-Step Instructions

### Step 0: Check which Firewall is active
Run these commands to see which one is being used:
```bash
# If this returns "Status: active", use Option A
sudo ufw status

# If UFW is inactive or not found, check this:
sudo iptables -L -n
```

### Step 0.5: Cloud Console Firewall (OCI/AWS/GCP)
If your server is in the cloud (like **Oracle Cloud**), the network has its own firewall outside the server.
1. Log into your **OCI Console**.
2. Go to `Networking` -> `Virtual Cloud Networks` -> Your VCN -> `Security Lists`.
3. Add an **Ingress Rule**:
   - **Source CIDR:** `0.0.0.0/0`
   - **Protocol:** `TCP`
   - **Destination Port Range:** `2345`
**DO NOT skip this.** If you change the port without opening the firewall, you will lock yourself out.

### Step 1: Allow new port 2345

#### Option A: If using UFW (Ubuntu/Debian)
```bash
# Replace 2345 with your preferred port
sudo ufw allow 2345/tcp
sudo ufw reload
```

#### Option B: If using iptables (CentOS/Oracle/RHEL)
```bash
# Allow the new port
sudo iptables -I INPUT -p tcp --dport 2345 -j ACCEPT

# Save the rules (Command depends on OS)
sudo service iptables save  # Oracle/CentOS
# OR
sudo netfilter-persistent save # Ubuntu/Debian with persistent iptables
```

### Step 2: Modify SSH Configuration
Edit the configuration file:
```bash
sudo nano /etc/ssh/sshd_config
```

Find and change these lines (remove the `#` if they are commented out):
```ssh
Port 2345
PasswordAuthentication no
PubkeyAuthentication yes
```

### Step 2.5: Ubuntu Socket Activation (Crucial)
Newer Ubuntu versions use `ssh.socket` to manage connections. If this is active, the `Port` in `sshd_config` is ignored.

1. **Check if socket is used:**
   ```bash
   sudo systemctl is-active ssh.socket
   ```
2. **If it says "active", create an override:**
   ```bash
   sudo mkdir -p /etc/systemd/system/ssh.socket.d
   sudo nano /etc/systemd/system/ssh.socket.d/override.conf
   ```
   
```ini
[Socket]
ListenStream=
ListenStream=0.0.0.0:2345
ListenStream=[::]:2345
```
3. **Apply the change:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart ssh.socket
   ```

### Step 3: Test and Verify (CRITICAL)
**DO NOT close your current terminal.** Open a **new** terminal window and try to log in:

```bash
# Test the new port
ssh -p 2345 ubuntuadmin@your-server-ip
```

### Step 4: Restart Service
If the test in Step 3 works, you can safely restart the service:
```bash
sudo systemctl restart ssh
sudo ss -tulpn | grep ssh
```

### Step 5: Fail2ban & Final Cleanup
Once you are 100% sure you can get in via the new port, update your security tools and block the old port.

#### 5.1: Update Fail2ban
If you use Fail2ban, you must tell it to watch the new port.

1. **Edit jail settings:**
   ```bash
   sudo nano /etc/fail2ban/jail.local
   ```
2. **Update the [sshd] section:**
   ```ini
   [sshd]
   enabled = true
   port    = 2345
   ```
3. **Restart Service:**
   ```bash
   sudo systemctl restart fail2ban
   ```

#### 5.2: Verify and Close Port 22
Restarting Fail2ban usually cleans up the port 22 rules automatically.

1. **Check for remnants:**
   ```bash
   sudo ufw status numbered             #if use ufw
   sudo iptables -L -n --line-numbers   #if use iptables
   ```
2. **Manual Cleanup (if port 22 is still there):**
   ```bash
   # Use the line number from the previous command with port 22
   sudo ufw delete {LineNumber}         #if use ufw
   sudo iptables -D INPUT {LineNumber}  #if use iptables
   ```
3. **Save changes (Crucial):**
   ```bash
   sudo ufw reload						#if use ufw
   sudo netfilter-persistent save		#if use iptables
   ```

#### 5.3: Cloud Console (OCI/AWS)
**DO NOT FORGET THIS.** Even if the server firewall is clean, the Cloud firewall still has port 22 open.
1. Log into your **OCI Console**.
2. Go to your Security List.
3. **Delete** the Ingress Rule for port **22**.

---

## � Generating SSH Keys (Optional)
If you already have a key (like in WindTerm), you can skip this section. If you are currently using a password to log in, you **must** generate keys and copy them to the server **before** you disable passwords.

### 1. On your LOCAL computer (Windows/Mac/Linux):
```bash
# Generate the key (Press Enter for all prompts)
ssh-keygen -t ed25519 -C "your_email@example.com"
```

### 2. Copy the key to the server:
> [!NOTE]
> The **.pub** file is your **Public Key** (the "lock"). This is the only one you copy.
> The file **without .pub** is your **Private Key** (the "key"). **NEVER** share or copy the private key file.

```bash
# Replace with your server IP
ssh-copy-id -i ~/.ssh/id_ed25519.pub ubuntuadmin@your-server-ip
```

### 3. Verify
Try to log in. If it **doesn't** ask for a password, your key is working!

---

---

## �💡 Troubleshooting & Tips
*   **Socket Activation:** If on Ubuntu, remember to use Step 2.5!
*   **Lockout Protection:** Always keep one active terminal session open while you test.
*   **Connecting:** From now on, use: `ssh -p 2345 ...`
