# 🖥️ Odoo Server Deployment Guide

## Server Network Configuration
- **Server Windows IP**: `192.168.0.21` ⭐ **External Access IP**
- **WSL Bridge IP**: `172.19.64.1`
- **WSL Internal**: Detected automatically

---

## 🚀 Quick Server Setup (3 Steps)

### Step 1: Configure Windows Port Forwarding
**On Windows Server (as Administrator):**

**Option A: Easy Setup**
1. Right-click `server-setup.bat`
2. Select **"Run as Administrator"**

**Option B: Manual Setup**
1. Open **PowerShell as Administrator**
2. Run: `.\server-portforward.ps1`

### Step 2: Install and Configure Nginx in WSL
**In WSL terminal:**
```bash
# Install nginx
sudo apt update && sudo apt install nginx -y

# Copy server nginx configuration
sudo cp nginx-server.conf /etc/nginx/sites-available/odoo17-server

# Enable the site
sudo ln -sf /etc/nginx/sites-available/odoo17-server /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test and start nginx
sudo nginx -t
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Step 3: Start Odoo Server
**In WSL terminal:**
```bash
chmod +x start-server-nginx.sh
./start-server-nginx.sh
```

### Step 4: Share Access
Give users this URL: **`http://192.168.0.21`**

---

## 📋 Server Configuration Details

### Port Forwarding Rules
- `Windows:80` → `WSL:80` (Nginx HTTP)
- `Windows:8069` → `WSL:8069` (Odoo Direct)
- `Windows:443` → `WSL:443` (HTTPS Future)

### Nginx Server Features
- ✅ **External Access**: Ready for internet/network users
- ✅ **Performance**: Aggressive caching and compression
- ✅ **Security**: Rate limiting and security headers
- ✅ **File Uploads**: Up to 100MB supported
- ✅ **WebSocket**: Longpolling support for chat
- ✅ **Static Assets**: Optimized delivery with 1-year caching

### Firewall Rules
- Allows incoming on ports 80, 443, 8069
- Works with all Windows Firewall profiles
- External network access enabled

---

## 🌐 Access URLs

| Purpose | URL | Users |
|---------|-----|-------|
| **Primary** | `http://192.168.0.21` | All external users |
| **Direct** | `http://192.168.0.21:8069` | Backup access |
| **Local** | `http://localhost` | Server console only |
| **HTTPS** | `https://192.168.0.21` | Future SSL setup |

---

## 🔧 Server Troubleshooting

### Problem: "Can't connect from external"
1. **Check port forwarding:**
   ```powershell
   # In PowerShell (as Admin)
   netsh interface portproxy show v4tov4
   ```

2. **Verify nginx is running:**
   ```bash
   # In WSL
   sudo systemctl status nginx
   curl http://localhost
   ```

3. **Test Windows firewall:**
   - Check Windows Defender Firewall
   - Look for "Odoo Server HTTP (80)" rule

### Problem: "502 Bad Gateway"
- Odoo is not running in WSL
- Use `./start-server-nginx.sh` not other scripts
- Check if virtual environment exists

### Problem: "Connection timeout"
- Server network configuration issue
- Router might be blocking connections
- Check if server IP is correct

---

## 📊 Server Performance Features

### Nginx Optimizations
- **Gzip Compression**: 6-level compression for text files
- **Static Caching**: 1-year cache for assets
- **Rate Limiting**: 10 requests/second with burst of 20
- **Connection Limiting**: Max 10 connections per IP
- **Buffer Optimization**: 64k buffers for better performance

### Security Features
- **Security Headers**: XSS protection, content type validation
- **Rate Limiting**: Basic DDoS protection
- **Server Tokens**: Hidden nginx version
- **Frame Options**: Clickjacking protection

---

## 🛡️ Production Considerations

### SSL/HTTPS Setup (Optional)
1. **Get SSL Certificate**:
   - Let's Encrypt (free): `sudo apt install certbot python3-certbot-nginx`
   - Commercial certificate
   
2. **Enable HTTPS in nginx config**:
   - Uncomment HTTPS server block in `nginx-server.conf`
   - Add certificate paths

3. **Auto-redirect HTTP to HTTPS**:
   - Update nginx configuration
   - Force secure connections

### Domain Name Setup
1. **DNS Configuration**:
   - Point your domain to `192.168.0.21`
   - Configure A record: `yourdomain.com → 192.168.0.21`
   
2. **Update nginx**:
   - Change `server_name _;` to `server_name yourdomain.com;`

### Router Configuration (Internet Access)
1. **Port Forwarding on Router**:
   - Forward external port 80 → `192.168.0.21:80`
   - Forward external port 443 → `192.168.0.21:443`
   
2. **Dynamic DNS** (if IP changes):
   - Use services like DuckDNS, No-IP

---

## 📁 Server Files Created

| File | Purpose |
|------|---------|
| `start-server-nginx.sh` | Server startup with nginx |
| `nginx-server.conf` | Production nginx configuration |
| `server-portforward.ps1` | Windows port forwarding setup |
| `server-setup.bat` | Easy double-click setup |
| `SERVER-DEPLOYMENT.md` | This documentation |

---

## 🎯 Different Access Levels

### Local Network Access
- **URL**: `http://192.168.0.21`
- **Users**: Anyone on same WiFi/network
- **Setup**: Port forwarding only

### Internet Access
- **URL**: `http://yourdomain.com` or `http://YOUR_PUBLIC_IP`
- **Users**: Anyone on internet
- **Setup**: Router configuration + domain/DNS

### Secure Access (HTTPS)
- **URL**: `https://yourdomain.com`
- **Users**: Secure external access
- **Setup**: SSL certificate + HTTPS configuration

---

## 🔄 Management Commands

### Start Services
```bash
# Start Odoo with nginx
./start-server-nginx.sh

# Start nginx only
sudo systemctl start nginx

# Check status
sudo systemctl status nginx
```

### Stop Services
```bash
# Stop Odoo (Ctrl+C in running terminal)
# Stop nginx
sudo systemctl stop nginx
```

### Remove Port Forwarding
```powershell
# Remove all rules
netsh interface portproxy reset
```

---

## 📞 Server Support

### Logs Locations
- **Nginx Access**: `/var/log/nginx/odoo_access.log`
- **Nginx Errors**: `/var/log/nginx/odoo_error.log`
- **Odoo Logs**: `./logs/odoo.log`

### Health Checks
```bash
# Test nginx config
sudo nginx -t

# Test Odoo response
curl http://localhost:8069

# Test external access
curl http://192.168.0.21
```

**Your server access URL: `http://192.168.0.21`** 🚀

**External users can access your Odoo server from anywhere on your network!**