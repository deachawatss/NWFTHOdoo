@echo off
REM Simple setup for WSL Odoo access (port 8069 only)
REM Double-click this file and select "Run as Administrator"

echo.
echo ========================================
echo   Simple Odoo Server Setup
echo   Server IP: 192.168.0.21:8069
echo ========================================
echo.

REM Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running as Administrator
    echo.
) else (
    echo This script requires Administrator privileges!
    echo.
    echo Right-click this file and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

echo Setting up simple network access...
echo.

REM Run the simple PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0simple-portforward.ps1"

echo.
echo Setup complete!
echo Share this URL: http://192.168.0.21:8069
pause