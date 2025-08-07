@echo off
REM Server setup for WSL Odoo external access
REM Double-click this file and select "Run as Administrator"

echo.
echo ========================================
echo   Odoo SERVER Network Access Setup
echo   Server IP: 192.168.0.21
echo ========================================
echo.

REM Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo ✅ Running as Administrator
    echo.
) else (
    echo ❌ This script requires Administrator privileges!
    echo.
    echo Right-click this file and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

echo 🖥️ Setting up SERVER network access for WSL Odoo...
echo External IP: 192.168.0.21
echo.

REM Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0server-portforward.ps1"

echo.
echo Setup complete! Your Odoo server is now accessible externally.
echo Share this URL: http://192.168.0.21
pause