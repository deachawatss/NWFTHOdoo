# Why Batch Files Close Automatically & How to Fix It

## The Issue
When you double-click any `.bat` file, it executes and immediately closes when finished. This is normal Windows behavior - you can't see the output because the window closes too fast.

## Solutions

### Solution 1: Run from Command Prompt (RECOMMENDED)
1. **Open Command Prompt as Administrator**
   - Press `Windows Key + R`
   - Type `cmd` and press `Ctrl + Shift + Enter`
   - Click "Yes" when prompted

2. **Navigate to your Odoo directory**
   ```cmd
   cd /d "C:\path\to\your\Odoo17"
   ```

3. **Run the scripts**
   ```cmd
   # Configure PostgreSQL first
   scripts\configure-postgresql.bat
   
   # Start production server
   start-production.bat
   
   # Check system health
   scripts\health-check.bat
   
   # Run load test
   scripts\load-test.bat
   ```

### Solution 2: Right-Click Method
1. **Right-click** on any `.bat` file
2. Select **"Edit"** to see the script content
3. OR select **"Run as administrator"** and the window will stay open longer

### Solution 3: Modified Scripts (Already Done!)
I've already added `pause` commands to keep the windows open in most scripts. The scripts will now:
- Show all output
- Display "Press any key to close..." at the end
- Wait for you to press a key before closing

## Quick Start Guide

### Step 1: Configure Database
```cmd
# Run as Administrator
scripts\configure-postgresql.bat
```
This will:
- ✅ Configure PostgreSQL 17 for 50 users
- ✅ Create backups
- ✅ Test connectivity
- ✅ Wait for your input before closing

### Step 2: Start Production Server
```cmd
start-production.bat
```
This will:
- ✅ Start 10 worker processes
- ✅ Validate system resources
- ✅ Show startup progress
- ✅ Keep running until you press Ctrl+C

### Step 3: Monitor Health
```cmd
scripts\health-check.bat
```
This will:
- ✅ Check all system components
- ✅ Show detailed health report
- ✅ Wait for key press before closing

### Step 4: Test Performance
```cmd
scripts\load-test.bat
```
This will:
- ✅ Simulate 50 concurrent users
- ✅ Show real-time progress
- ✅ Generate performance report
- ✅ Wait for key press before closing

## Access Your Odoo Server

Once started, access your server at:
- **Main Interface**: http://localhost:8069
- **Database Manager**: http://localhost:8069/web/database/manager
- **Admin User**: admin
- **Password**: 1234

## Common Issues & Solutions

### "Script closes immediately"
- **Cause**: Normal Windows behavior
- **Solution**: Run from Command Prompt (see Solution 1 above)

### "Access Denied" or "Permission Error"
- **Cause**: Insufficient privileges
- **Solution**: Run Command Prompt as Administrator

### "PostgreSQL not found"
- **Cause**: PostgreSQL 17 not installed or not in standard location
- **Solution**: Install PostgreSQL 17 or modify paths in scripts

### "Python environment not found"
- **Cause**: Virtual environment not created
- **Solution**: Create it with `python -m venv odoo_env`

## Tips for Success

1. **Always run as Administrator** for system configuration scripts
2. **Use Command Prompt** instead of double-clicking for better control
3. **Check logs** in the `logs\` directory if something goes wrong
4. **Start with database configuration** before starting the server
5. **Monitor system resources** during operation

## Need Help?

If you're still having issues:
1. Run `scripts\health-check.bat` to diagnose problems
2. Check the log files in the `logs\` directory
3. Ensure PostgreSQL 17 is installed and running
4. Verify you have Python 3.10+ and virtual environment set up

Your native Windows deployment is ready for 50 concurrent users!