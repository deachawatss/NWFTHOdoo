# 🌐 Odoo WSL Network Access Setup

## The Problem
Your Odoo runs in WSL (Windows Subsystem for Linux) which has its own network. Friends on your local network can't directly access the WSL IP address. We need to forward traffic from your Windows IP to WSL.

## Network Configuration
- **WSL IP**: `172.26.236.105` (internal, not accessible from outside)
- **Windows WiFi IP**: `192.168.6.42` ⭐ **This is what friends need to access**
- **WSL Host Bridge**: `172.26.224.1`

---

## 🚀 Quick Setup (3 Steps)

### Step 1: Set up Windows Port Forwarding
**On Windows (as Administrator):**

**Option A: Easy Way**
1. Go to your Odoo17 folder in Windows Explorer
2. **Right-click** `setup-network-access.bat`
3. Select **"Run as Administrator"**

**Option B: Manual Way**
1. Open **PowerShell as Administrator**
2. Navigate to your Odoo folder
3. Run: `.\setup-wsl-portforward.ps1`

### Step 2: Start Odoo with Nginx
**In WSL/Linux terminal:**
```bash
cd /home/deachawat/dev/projects/Odoo/Odoo17
./start-with-nginx.sh
```

### Step 3: Share the URL
Give your friends this URL: **`http://192.168.6.42`**

---

## 📋 What the Setup Does

### Port Forwarding Rules
- `Windows:80` → `WSL:80` (Nginx)
- `Windows:8069` → `WSL:8069` (Direct Odoo)

### Firewall Rules
- Allows incoming connections on ports 80 and 8069
- Works with all Windows Firewall profiles (Domain, Private, Public)

### Benefits
- ✅ **Clean URLs**: `http://192.168.6.42` (no port numbers needed)
- ✅ **Better Performance**: Nginx caching and compression
- ✅ **Security**: Proper headers and rate limiting
- ✅ **File Uploads**: Up to 50MB supported
- ✅ **Professional**: Production-ready setup

---

## 🔧 Troubleshooting

### Problem: "Can't connect"
**Check these in order:**

1. **Is Odoo running in WSL?**
   ```bash
   # In WSL, check if Odoo is running
   curl http://localhost:80
   ```

2. **Is port forwarding active?**
   ```powershell
   # In Windows PowerShell (as Admin)
   netsh interface portproxy show v4tov4
   ```

3. **Is Windows Firewall blocking?**
   - Check Windows Defender Firewall settings
   - Look for "WSL Odoo HTTP (80)" rule

4. **Test locally first:**
   ```cmd
   # On Windows, test if forwarding works locally
   curl http://192.168.6.42
   ```

### Problem: "Connection refused" 
- Ensure you're using `./start-with-nginx.sh` not `./start-dev.sh`
- Check nginx is running: `sudo systemctl status nginx`

### Problem: "Timeout"
- Your router might be blocking connections
- Try accessing from the same WiFi network first

---

## 📱 Access URLs

| Purpose | URL | Description |
|---------|-----|-------------|
| **Primary** | `http://192.168.6.42` | Clean URL through nginx |
| **Direct** | `http://192.168.6.42:8069` | Direct to Odoo (backup) |
| **Local WSL** | `http://localhost` | Only works inside WSL |
| **Local Windows** | `http://localhost:80` | Windows forwarded |

---

## 🗑️ Removing Setup

If you want to remove the port forwarding:

**Option A:** Run `setup-wsl-portforward-remove.ps1`
**Option B:** Manual cleanup
```powershell
# Remove port forwarding
netsh interface portproxy delete v4tov4 listenport=80
netsh interface portproxy delete v4tov4 listenport=8069

# Remove firewall rules
Remove-NetFirewallRule -DisplayName "WSL Odoo HTTP (80)"
Remove-NetFirewallRule -DisplayName "WSL Odoo Direct (8069)"
```

---

## 🎯 Different Startup Options

### Full Setup (Recommended)
```bash
./start-with-nginx.sh
```
- Nginx reverse proxy
- Clean URLs
- Performance optimization
- Security headers

### Basic Setup
```bash
./start-dev.sh
```
- Direct Odoo access only
- Requires port 8069 in URL
- No nginx optimizations

---

## 📊 Performance Comparison

| Feature | Direct Odoo | With Nginx |
|---------|-------------|------------|
| **URL** | `:8069` required | Clean URLs |
| **Static Files** | Slower | Cached |
| **Compression** | None | Gzip enabled |
| **Security** | Basic | Headers + rules |
| **File Uploads** | 25MB default | 50MB configured |
| **Production Ready** | No | Yes |

---

## 🛡️ Security Notes

- Port forwarding only affects your local network
- External access requires router configuration (not covered here)
- Always use strong passwords for Odoo admin accounts
- Consider HTTPS for production use

---

## 📞 Support

If you have issues:
1. Check the troubleshooting section above
2. Verify all commands were run as Administrator
3. Ensure WSL and Windows are on the same network bridge
4. Test locally before testing remotely

**Files Created:**
- `setup-wsl-portforward.ps1` - Main setup script
- `setup-wsl-portforward-remove.ps1` - Cleanup script
- `setup-network-access.bat` - Easy double-click setup
- `start-with-nginx.sh` - Nginx-enabled startup
- `nginx-odoo.conf` - Nginx configuration

**Your friends' access URL: `http://192.168.6.42`** 🚀