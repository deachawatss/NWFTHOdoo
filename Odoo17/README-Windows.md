# Odoo 17 Windows Native Deployment Guide

**Complete guide for running Odoo 17 natively on Windows Server**

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Detailed Installation](#detailed-installation)
5. [Script Reference](#script-reference)
6. [Configuration](#configuration)
7. [Daily Operations](#daily-operations)
8. [Troubleshooting](#troubleshooting)
9. [Security](#security)
10. [Performance Tuning](#performance-tuning)
11. [Backup & Recovery](#backup--recovery)

---

## 🎯 Overview

This Windows native deployment provides a **simple, reliable alternative to Docker** for running Odoo 17 on Windows Server. The solution includes:

- **One-click startup**: Double-click `start-odoo-windows.bat` to start Odoo
- **Complete management suite**: Start, stop, restart, and log viewing scripts
- **Automated setup**: Environment and database setup scripts
- **Production-ready**: Optimized configuration for Windows Server 192.168.0.21
- **No Docker dependency**: Native Windows installation with Python virtual environment

### Architecture
```
Windows Server 192.168.0.21
├── Python 3.11+ Virtual Environment
├── PostgreSQL Database (localhost:5432)
├── Odoo 17 Application (port 8069)
└── File-based Session Storage
```

---

## 🔧 Prerequisites

### System Requirements
- **Windows Server** or Windows 10/11 Pro
- **RAM**: 4GB minimum, 8GB+ recommended
- **CPU**: 2+ cores recommended
- **Disk**: 10GB+ free space
- **Network**: Static IP 192.168.0.21 (configurable)

### Software Requirements
- **Python 3.11+** - [Download from python.org](https://python.org)
- **PostgreSQL 12+** - [Download from postgresql.org](https://postgresql.org)
- **Git** (optional) - For version control

### Network Requirements
- **Port 8069**: Odoo web interface
- **Port 5432**: PostgreSQL database
- **Internet access**: For Python package installation

---

## 🚀 Quick Start

### 1. Clone/Download Odoo 17
```bash
# If using Git
git clone https://github.com/odoo/odoo.git
cd odoo
git checkout 17.0

# Or download and extract Odoo 17 zip file
```

### 2. Install Prerequisites
- Install Python 3.11+ (check "Add Python to PATH")
- Install PostgreSQL with password for `postgres` user
- Verify installations:
  ```cmd
  python --version
  psql --version
  ```

### 3. Run Setup Scripts
1. **Double-click** `setup-windows-environment.bat`
2. **Double-click** `setup-database.bat`

### 4. Start Odoo
**Double-click** `start-odoo-windows.bat`

### 5. Access Odoo
Open browser to: **http://192.168.0.21:8069**
- **Admin Password**: `AdminSecure2024!`

---

## 📖 Detailed Installation

### Step 1: System Preparation

#### Install Python 3.11+
1. Download from [python.org](https://python.org)
2. **Important**: Check "Add Python to PATH" during installation
3. Verify: `python --version` should show 3.11+

#### Install PostgreSQL
1. Download from [postgresql.org](https://postgresql.org)
2. Remember the `postgres` user password
3. Ensure PostgreSQL service is running
4. Verify: `psql --version`

### Step 2: Odoo Installation

#### Download Odoo 17
```bash
# Option 1: Git clone
git clone https://github.com/odoo/odoo.git
cd odoo
git checkout 17.0

# Option 2: Download ZIP
# Download from https://github.com/odoo/odoo/archive/17.0.zip
# Extract to desired directory
```

#### Copy Windows Scripts
Ensure these files are in your Odoo directory:
- `start-odoo-windows.bat`
- `stop-odoo-windows.bat`
- `restart-odoo-windows.bat`
- `logs-odoo-windows.bat`
- `setup-windows-environment.bat`
- `setup-database.bat`
- `odoo-windows.conf`

### Step 3: Environment Setup

#### Run Environment Setup
1. **Right-click** `setup-windows-environment.bat` → **Run as Administrator**
2. The script will:
   - Validate Python installation
   - Create virtual environment `odoo_env`
   - Install Odoo dependencies
   - Create necessary directories
   - Validate installation

#### Expected Output
```
======================================================
       Environment Setup Complete!
======================================================
✓ Python 3.11.x validated
✓ Virtual environment created/validated
✓ Dependencies installed
✓ Directories created
✓ Odoo 17.x validated
✓ Environment ready for use
```

### Step 4: Database Setup

#### Run Database Setup
1. **Double-click** `setup-database.bat`
2. Enter PostgreSQL `postgres` user password when prompted
3. The script will:
   - Test PostgreSQL connection
   - Create `odoo_prod` user with password `OdooSecure2024!`
   - Create `odoo_prod` database
   - Set up necessary extensions
   - Validate permissions

#### Expected Output
```
======================================================
       Database Setup Complete!
======================================================
✓ PostgreSQL connection validated
✓ User 'odoo_prod' created/updated
✓ Database 'odoo_prod' created/validated
✓ Database permissions validated
✓ Extensions created
```

### Step 5: First Startup

#### Start Odoo
1. **Double-click** `start-odoo-windows.bat`
2. Wait for startup (may take 1-2 minutes on first run)
3. Look for: `"Odoo is running on http://0.0.0.0:8069"`

#### Access Web Interface
1. Open browser to: **http://192.168.0.21:8069**
2. Complete Odoo setup wizard:
   - **Database Name**: `odoo_prod` (pre-filled)
   - **Admin Password**: `AdminSecure2024!`
   - **Language**: Choose your preference
   - **Country**: Select your country
   - **Demo Data**: Recommended for testing

---

## 📜 Script Reference

### Core Scripts

#### `start-odoo-windows.bat`
**Primary startup script** - Double-click to start Odoo
- ✅ Environment validation
- ✅ Process cleanup
- ✅ Virtual environment activation
- ✅ Database connectivity check
- ✅ Odoo server startup
- ✅ Comprehensive error handling

**Usage**: Double-click or run from command line
```cmd
start-odoo-windows.bat
```

#### `stop-odoo-windows.bat`
**Safe shutdown script** - Stops all Odoo processes
- ✅ Graceful process termination
- ✅ Force kill if needed
- ✅ Port cleanup (8069)
- ✅ Log file archiving
- ✅ Temporary file cleanup

**Usage**: Double-click or run from command line
```cmd
stop-odoo-windows.bat
```

#### `restart-odoo-windows.bat`
**Restart script** - Stops and restarts Odoo
- ✅ Safe shutdown
- ✅ Environment revalidation
- ✅ Choice of foreground/background mode
- ✅ Status verification

**Usage**: Double-click and choose mode:
1. **Foreground**: See logs in console window
2. **Background**: Run silently, close window
3. **Cancel**: Abort restart

#### `logs-odoo-windows.bat`
**Log management tool** - View and manage log files
- ✅ Real-time log monitoring
- ✅ Error/warning search
- ✅ Archived log viewing
- ✅ Custom pattern search
- ✅ Log file management

**Features**:
1. View last 50/100 lines
2. View complete log
3. Real-time monitoring (tail -f)
4. Search for errors/warnings
5. Custom pattern search
6. View archived logs
7. Clear current log

### Setup Scripts

#### `setup-windows-environment.bat`
**One-time environment setup** - Run once before first use
- ✅ Python version validation (3.11+)
- ✅ Virtual environment creation
- ✅ Dependency installation
- ✅ Directory structure creation
- ✅ Odoo installation validation

**When to run**: Before first Odoo startup

#### `setup-database.bat`
**Database configuration** - Sets up PostgreSQL
- ✅ PostgreSQL connection testing
- ✅ `odoo_prod` user creation
- ✅ `odoo_prod` database creation
- ✅ Extension installation
- ✅ Permission validation

**When to run**: After PostgreSQL installation, before first startup

---

## ⚙️ Configuration

### Main Configuration File: `odoo-windows.conf`

#### Database Settings
```ini
[options]
# Database connection
db_host = localhost
db_port = 5432
db_user = odoo_prod
db_password = OdooSecure2024!
db_maxconn = 32
```

#### Server Settings
```ini
# Web server
http_port = 8069
gevent_port = 8072

# Module paths
addons_path = addons,custom_addons
server_wide_modules = base,web
```

#### Windows Optimizations
```ini
# Single-threaded for Windows stability
workers = 0
max_cron_threads = 2

# Memory limits
limit_memory_soft = 1073741824   # 1GB
limit_memory_hard = 2147483648   # 2GB

# Session storage (file-based, no Redis)
session_store = filesystem
```

### Network Configuration

#### Default Settings
- **Web Interface**: http://192.168.0.21:8069
- **Database**: localhost:5432
- **Admin Password**: AdminSecure2024!

#### Customizing IP Address
To change from 192.168.0.21 to another IP:

1. **Edit `odoo-windows.conf`**:
   ```ini
   # Add or modify:
   http_interface = 0.0.0.0  # Listen on all interfaces
   ```

2. **Update Windows Firewall**:
   ```cmd
   # Allow Odoo through firewall
   netsh advfirewall firewall add rule name="Odoo17" dir=in action=allow protocol=TCP localport=8069
   ```

3. **Access via new IP**:
   - http://YOUR_NEW_IP:8069

### Directory Structure
```
Odoo17/
├── odoo-bin                    # Main Odoo executable
├── addons/                     # Standard Odoo modules
├── custom_addons/              # Custom modules (optional)
├── odoo_env/                   # Python virtual environment
├── data/                       # Data directory
│   ├── filestore/             # File attachments
│   └── sessions/              # Session files
├── logs/                       # Log files
│   ├── odoo.log              # Current log
│   └── archived/             # Old log files
├── odoo-windows.conf          # Configuration file
├── requirements.txt           # Python dependencies
└── *.bat                      # Management scripts
```

---

## 🔄 Daily Operations

### Starting Odoo
```cmd
# Method 1: Double-click
start-odoo-windows.bat

# Method 2: Command line
cd C:\path\to\odoo
start-odoo-windows.bat
```

### Stopping Odoo
```cmd
# Method 1: Double-click
stop-odoo-windows.bat

# Method 2: Ctrl+C in startup window
# Method 3: Task Manager (kill python.exe processes)
```

### Restarting Odoo
```cmd
# Interactive restart with mode selection
restart-odoo-windows.bat

# Quick restart (command line)
stop-odoo-windows.bat && start-odoo-windows.bat
```

### Viewing Logs
```cmd
# Interactive log viewer
logs-odoo-windows.bat

# Quick log view (command line)
type logs\odoo.log

# Real-time monitoring (PowerShell)
Get-Content logs\odoo.log -Wait -Tail 10
```

### Checking Status
```cmd
# Check if Odoo is running
tasklist | findstr python.exe

# Check port usage
netstat -an | findstr :8069

# Quick web test
curl http://192.168.0.21:8069/web/health
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Startup Failures

**Error**: `python: command not found`
```cmd
# Solution: Add Python to PATH
# Re-run Python installer and check "Add Python to PATH"
# Or manually add: C:\Python311\Scripts\;C:\Python311\;
```

**Error**: `ModuleNotFoundError: No module named 'odoo'`
```cmd
# Solution: Reinstall dependencies
cd C:\path\to\odoo
odoo_env\Scripts\activate
pip install -r requirements.txt
```

**Error**: `Virtual environment activation failed`
```cmd
# Solution: Recreate virtual environment
rmdir /s odoo_env
python -m venv odoo_env
odoo_env\Scripts\activate
pip install -r requirements.txt
```

#### 2. Database Connection Issues

**Error**: `FATAL: password authentication failed`
```cmd
# Solution: Reset database password
setup-database.bat
# Or manually reset:
# psql -U postgres -c "ALTER USER odoo_prod PASSWORD 'OdooSecure2024!';"
```

**Error**: `could not connect to server: Connection refused`
```cmd
# Solution: Start PostgreSQL service
net start postgresql-x64-13
# Or use Services.msc to start PostgreSQL service
```

**Error**: `database "odoo_prod" does not exist`
```cmd
# Solution: Create database
setup-database.bat
# Or manually:
# createdb -U postgres -O odoo_prod odoo_prod
```

#### 3. Port Conflicts

**Error**: `Address already in use: ('', 8069)`
```cmd
# Solution: Find and kill process using port 8069
netstat -ano | findstr :8069
taskkill /F /PID [PID_NUMBER]

# Or use different port in odoo-windows.conf:
# http_port = 8070
```

#### 4. Permission Issues

**Error**: `Permission denied: 'logs\odoo.log'`
```cmd
# Solution: Check file permissions and close log viewers
# Kill any processes accessing the log file
tasklist | findstr notepad
tasklist | findstr tail
# Kill the processes and restart Odoo
```

#### 5. Memory Issues

**Error**: `MemoryError` or system slowdown
```cmd
# Solution: Adjust memory limits in odoo-windows.conf
limit_memory_soft = 536870912    # 512MB
limit_memory_hard = 1073741824   # 1GB

# Or add more system RAM
```

### Performance Issues

#### Slow Startup
1. **Check antivirus**: Add Odoo directory to exclusions
2. **Check disk space**: Ensure >2GB free
3. **Check PostgreSQL**: Restart PostgreSQL service
4. **Check memory**: Close unnecessary applications

#### Slow Web Interface
1. **Browser cache**: Clear browser cache and cookies
2. **Network**: Check network connectivity to 192.168.0.21
3. **Database**: Restart PostgreSQL service
4. **Odoo cache**: Restart Odoo server

### Log Analysis

#### Check for Errors
```cmd
# Search current log for errors
findstr /i "error" logs\odoo.log

# Search for database errors
findstr /i "database error" logs\odoo.log

# Search for memory errors
findstr /i "memory" logs\odoo.log
```

#### Common Log Messages
- `✓ Good`: `"Odoo is running on http://0.0.0.0:8069"`
- `⚠ Warning`: `"WARNING: unable to load module"`
- `❌ Error`: `"ERROR: Database connection failed"`
- `❌ Critical`: `"CRITICAL: Failed to initialize database"`

### Recovery Procedures

#### Complete Reset
```cmd
# 1. Stop Odoo
stop-odoo-windows.bat

# 2. Reset database
dropdb -U postgres odoo_prod
setup-database.bat

# 3. Reset environment
rmdir /s odoo_env
setup-windows-environment.bat

# 4. Start fresh
start-odoo-windows.bat
```

#### Backup Before Changes
```cmd
# Backup database
pg_dump -U odoo_prod -h localhost odoo_prod > backup_odoo_prod.sql

# Backup filestore
xcopy data\filestore backup_filestore\ /E /I

# Backup configuration
copy odoo-windows.conf odoo-windows.conf.backup
```

---

## 🔒 Security

### Default Credentials
**⚠️ CHANGE THESE IN PRODUCTION**

- **Odoo Admin**: admin / AdminSecure2024!
- **Database User**: odoo_prod / OdooSecure2024!
- **Master Password**: AdminSecure2024!

### Security Hardening

#### 1. Change Default Passwords
```cmd
# Odoo admin password (via web interface):
# Settings → Users & Companies → Users → Administrator → Change Password

# Database password:
psql -U postgres -c "ALTER USER odoo_prod PASSWORD 'YOUR_NEW_PASSWORD';"
# Update odoo-windows.conf with new password
```

#### 2. Restrict Database Access
```cmd
# Edit PostgreSQL pg_hba.conf to restrict connections
# Typically located in: C:\Program Files\PostgreSQL\13\data\pg_hba.conf
# Change:
local   all   all   trust
# To:
local   all   all   md5
```

#### 3. Enable Firewall Rules
```cmd
# Allow only specific IPs to access Odoo
netsh advfirewall firewall add rule name="Odoo17-Restricted" dir=in action=allow protocol=TCP localport=8069 remoteip=192.168.0.0/24

# Block external access to PostgreSQL
netsh advfirewall firewall add rule name="Block-PostgreSQL" dir=in action=block protocol=TCP localport=5432
```

#### 4. Disable Database Management
In `odoo-windows.conf`:
```ini
[options]
list_db = False          # Hide database list
db_name = odoo_prod      # Force specific database
```

#### 5. Enable HTTPS (Production)
1. **Install SSL certificate**
2. **Configure reverse proxy** (nginx/IIS)
3. **Update configuration**:
   ```ini
   [options]
   proxy_mode = True
   ```

### File Permissions
```cmd
# Restrict access to configuration file
icacls odoo-windows.conf /grant:r Users:R
icacls odoo-windows.conf /remove "Everyone"

# Protect data directory
icacls data /grant:r "NT AUTHORITY\SYSTEM":F
icacls data /grant:r Administrators:F
icacls data /grant:r [ODOO_USER]:F
```

### Monitoring & Auditing
- **Enable PostgreSQL logging**
- **Monitor failed login attempts**
- **Regular security updates**
- **Log file rotation and archiving**

---

## ⚡ Performance Tuning

### System Optimization

#### Windows Settings
```cmd
# Disable Windows Search indexing on Odoo directory
# Set high performance power plan
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# Increase virtual memory
# System Properties → Advanced → Performance → Settings → Advanced → Virtual Memory
# Set to 2x RAM size
```

#### PostgreSQL Optimization
Add to `postgresql.conf`:
```ini
# Memory settings
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# Connection settings
max_connections = 100

# Performance settings
checkpoint_segments = 32
checkpoint_completion_target = 0.7
wal_buffers = 16MB
```

### Odoo Configuration Tuning

#### For 4GB RAM System
```ini
[options]
workers = 0                    # Single-threaded
limit_memory_soft = 1073741824 # 1GB
limit_memory_hard = 2147483648 # 2GB
max_cron_threads = 2
```

#### For 8GB+ RAM System
```ini
[options]
workers = 0                    # Keep single-threaded for Windows
limit_memory_soft = 2147483648 # 2GB
limit_memory_hard = 4294967296 # 4GB
max_cron_threads = 3
db_maxconn = 64
```

### Database Maintenance

#### Regular Maintenance
```cmd
# Weekly vacuum (every Sunday)
psql -U odoo_prod -d odoo_prod -c "VACUUM ANALYZE;"

# Reindex monthly
psql -U odoo_prod -d odoo_prod -c "REINDEX DATABASE odoo_prod;"

# Update table statistics
psql -U odoo_prod -d odoo_prod -c "ANALYZE;"
```

#### Automated Maintenance Script
Create `maintenance.bat`:
```cmd
@echo off
echo Starting database maintenance...
psql -U odoo_prod -d odoo_prod -c "VACUUM ANALYZE;"
echo Database maintenance completed.
```

### Log Management
```ini
[options]
# Rotate logs daily
logrotate = True
log_level = info

# Reduce log verbosity in production
log_db = False
log_db_level = warning
```

---

## 💾 Backup & Recovery

### Automated Backup Script

Create `backup-odoo.bat`:
```cmd
@echo off
REM Daily Odoo Backup Script

setlocal enabledelayedexpansion
set BACKUP_DIR=C:\Odoo_Backups
set DATE=%date:~-4%%date:~3,2%%date:~0,2%
set TIME=%time:~0,2%%time:~3,2%%time:~6,2%
set TIME=%TIME: =0%
set TIMESTAMP=%DATE%_%TIME%

REM Create backup directory
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM Stop Odoo
echo Stopping Odoo for backup...
stop-odoo-windows.bat

REM Backup database
echo Backing up database...
pg_dump -U odoo_prod -h localhost odoo_prod > "%BACKUP_DIR%\odoo_prod_%TIMESTAMP%.sql"

REM Backup filestore
echo Backing up filestore...
xcopy "data\filestore" "%BACKUP_DIR%\filestore_%TIMESTAMP%\" /E /I /Q

REM Backup configuration
echo Backing up configuration...
copy "odoo-windows.conf" "%BACKUP_DIR%\odoo-windows_%TIMESTAMP%.conf"

REM Start Odoo
echo Starting Odoo...
start-odoo-windows.bat

REM Cleanup old backups (keep 7 days)
forfiles /p "%BACKUP_DIR%" /m *.sql /d -7 /c "cmd /c del @path" 2>nul
forfiles /p "%BACKUP_DIR%" /m *.conf /d -7 /c "cmd /c del @path" 2>nul

echo Backup completed: %TIMESTAMP%
```

### Manual Backup

#### Database Backup
```cmd
# Full backup
pg_dump -U odoo_prod -h localhost odoo_prod > backup_full.sql

# Compressed backup
pg_dump -U odoo_prod -h localhost odoo_prod | gzip > backup_compressed.sql.gz

# Schema only
pg_dump -U odoo_prod -h localhost --schema-only odoo_prod > backup_schema.sql
```

#### Filestore Backup
```cmd
# Copy filestore
xcopy data\filestore backup\filestore\ /E /I

# Compressed filestore (using 7zip)
7z a backup_filestore.7z data\filestore\*
```

### Recovery Procedures

#### Database Recovery
```cmd
# 1. Stop Odoo
stop-odoo-windows.bat

# 2. Drop existing database
dropdb -U postgres odoo_prod

# 3. Create new database
createdb -U postgres -O odoo_prod odoo_prod

# 4. Restore from backup
psql -U odoo_prod -d odoo_prod < backup_full.sql

# 5. Start Odoo
start-odoo-windows.bat
```

#### Complete System Recovery
```cmd
# 1. Install Python and PostgreSQL
# 2. Restore Odoo directory from backup
# 3. Run environment setup
setup-windows-environment.bat

# 4. Restore database
createdb -U postgres -O odoo_prod odoo_prod
psql -U odoo_prod -d odoo_prod < backup_full.sql

# 5. Restore filestore
xcopy backup\filestore data\filestore\ /E /I

# 6. Restore configuration
copy backup\odoo-windows.conf odoo-windows.conf

# 7. Start Odoo
start-odoo-windows.bat
```

### Scheduled Backups

#### Using Windows Task Scheduler
1. **Open Task Scheduler**
2. **Create Basic Task**:
   - Name: "Odoo Daily Backup"
   - Trigger: Daily at 2:00 AM
   - Action: Start Program
   - Program: `C:\path\to\odoo\backup-odoo.bat`

#### Backup Verification
```cmd
# Test database backup
pg_restore --list backup_full.sql

# Test filestore backup
dir backup\filestore\

# Test configuration backup
type backup\odoo-windows.conf
```

---

## 📞 Support & Maintenance

### Regular Maintenance Tasks

#### Weekly Tasks
- [ ] Check log files for errors
- [ ] Verify backup completion
- [ ] Monitor disk space
- [ ] Check system performance

#### Monthly Tasks
- [ ] Update Odoo (minor versions)
- [ ] Update Python packages: `pip list --outdated`
- [ ] Clean old log files
- [ ] Review security settings
- [ ] Database maintenance (VACUUM, ANALYZE)

#### Quarterly Tasks
- [ ] Review and update passwords
- [ ] Check for PostgreSQL updates
- [ ] Review firewall rules
- [ ] Test disaster recovery procedures

### Getting Help

#### Log Files
- **Current log**: `logs\odoo.log`
- **Archived logs**: `logs\archived\`
- **System logs**: Windows Event Viewer

#### Useful Commands
```cmd
# System information
systeminfo | findstr "OS Name OS Version"

# Python information
python --version
pip list

# PostgreSQL information
psql --version
psql -U postgres -c "SELECT version();"

# Odoo information
python -c "import odoo; print(odoo.release.version)"
```

#### Community Resources
- **Odoo Documentation**: https://www.odoo.com/documentation/17.0/
- **Odoo Community**: https://www.odoo.com/forum/
- **PostgreSQL Documentation**: https://www.postgresql.org/docs/

---

## 📝 Quick Reference Card

### Essential Commands
```cmd
# Start Odoo
start-odoo-windows.bat

# Stop Odoo
stop-odoo-windows.bat

# Restart Odoo
restart-odoo-windows.bat

# View logs
logs-odoo-windows.bat

# Setup (first time only)
setup-windows-environment.bat
setup-database.bat
```

### Key Directories
- **Logs**: `logs\odoo.log`
- **Data**: `data\filestore\`
- **Config**: `odoo-windows.conf`
- **Virtual Env**: `odoo_env\`

### Default Access
- **Web URL**: http://192.168.0.21:8069
- **Admin User**: admin
- **Admin Password**: AdminSecure2024!
- **Database**: odoo_prod

### Emergency Procedures
```cmd
# Force stop all Python processes
taskkill /F /IM python.exe

# Reset environment
rmdir /s odoo_env
setup-windows-environment.bat

# Reset database
dropdb -U postgres odoo_prod
setup-database.bat
```

---

**🎉 Your Odoo 17 Windows deployment is ready!**

For questions or issues, check the troubleshooting section or review the log files using `logs-odoo-windows.bat`.