@echo off
REM Easy setup for WSL network access
REM Double-click this file and select "Run as Administrator"

echo.
echo ========================================
echo   Odoo WSL Network Access Setup
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

echo 🚀 Setting up network access for WSL Odoo...
echo.

REM Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0setup-wsl-portforward.ps1"

echo.
echo Setup complete! You can now share your Odoo server.
pause