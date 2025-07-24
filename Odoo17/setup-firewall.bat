@echo off
REM ====================================================================
REM Windows Firewall Configuration for Odoo Network Access
REM Creates inbound rules to allow network access to Odoo server
REM ====================================================================

echo.
echo ====================================================================
echo              CONFIGURING WINDOWS FIREWALL FOR ODOO
echo ====================================================================
echo Adding firewall rules to allow network access to Odoo server...
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script must be run as Administrator!
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo Adding firewall rule for Odoo HTTP port 8069...
netsh advfirewall firewall add rule name="Odoo HTTP Port 8069" dir=in action=allow protocol=TCP localport=8069 profile=private,domain

echo Adding firewall rule for Odoo Long Polling port 8072...
netsh advfirewall firewall add rule name="Odoo Long Polling Port 8072" dir=in action=allow protocol=TCP localport=8072 profile=private,domain

echo.
echo ====================================================================
echo              FIREWALL CONFIGURATION COMPLETED
echo ====================================================================
echo Rules added:
echo - Odoo HTTP Port 8069 (TCP) - ALLOWED
echo - Odoo Long Polling Port 8072 (TCP) - ALLOWED
echo.
echo Your friends can now access Odoo at:
echo http://192.168.6.42:8069
echo.
echo Note: Only works on private and domain networks for security
echo ====================================================================

pause