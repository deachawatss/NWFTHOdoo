# Odoo 17 Windows - Quick Setup Guide

**⚡ Get Odoo 17 running on Windows in 10 minutes**

---

## 🚀 Prerequisites (5 minutes)

### 1. Install Python 3.11+
- Download: https://python.org/downloads/
- **IMPORTANT**: ✅ Check "Add Python to PATH"
- Verify: `python --version`

### 2. Install PostgreSQL
- Download: https://postgresql.org/download/windows/
- Remember the `postgres` user password
- Verify: `psql --version`

---

## 📦 Installation (3 minutes)

### 1. Get Odoo 17
```bash
# Option A: Git (recommended)
git clone https://github.com/odoo/odoo.git
cd odoo
git checkout 17.0

# Option B: Download ZIP
# https://github.com/odoo/odoo/archive/17.0.zip
```

### 2. Copy Windows Scripts
Place these files in your Odoo directory:
- `setup-windows-environment.bat`
- `setup-database.bat`  
- `start-odoo-windows.bat`
- `stop-odoo-windows.bat`
- `restart-odoo-windows.bat`
- `logs-odoo-windows.bat`
- `odoo-windows.conf`

---

## ⚡ Quick Start (2 minutes)

### 1. Setup Environment
**Double-click**: `setup-windows-environment.bat`
- Creates Python virtual environment
- Installs Odoo dependencies
- Creates necessary directories

### 2. Setup Database  
**Double-click**: `setup-database.bat`
- Enter PostgreSQL `postgres` password when prompted
- Creates `odoo_prod` database and user

### 3. Start Odoo
**Double-click**: `start-odoo-windows.bat`
- Wait for "Odoo is running" message (1-2 minutes)

### 4. Access Odoo
**Browser**: http://192.168.0.21:8069
- **Admin Password**: `AdminSecure2024!`
- Complete setup wizard

---

## 🎯 That's It! 

Your Odoo 17 is now running natively on Windows!

### Daily Operations
- **Start**: Double-click `start-odoo-windows.bat`
- **Stop**: Double-click `stop-odoo-windows.bat`  
- **Restart**: Double-click `restart-odoo-windows.bat`
- **View Logs**: Double-click `logs-odoo-windows.bat`

### Default Access
- **URL**: http://192.168.0.21:8069
- **User**: admin
- **Password**: AdminSecure2024!

---

## 🆘 Quick Troubleshooting

### Python Issues
```cmd
# If "python not found"
python --version
# Re-install Python with "Add to PATH" checked
```

### Database Issues  
```cmd
# If database connection fails
net start postgresql-x64-13
# Or restart PostgreSQL service in Services.msc
```

### Port Issues
```cmd
# If port 8069 is busy
netstat -an | findstr :8069
# Stop the process using the port
```

### Complete Reset
```cmd
stop-odoo-windows.bat
rmdir /s odoo_env
setup-windows-environment.bat
setup-database.bat
start-odoo-windows.bat
```

---

## 📖 Need More Help?

See **README-Windows.md** for:
- Detailed installation guide
- Configuration options
- Security settings
- Performance tuning
- Backup procedures
- Comprehensive troubleshooting

---

**🎉 Welcome to Odoo 17 on Windows!**