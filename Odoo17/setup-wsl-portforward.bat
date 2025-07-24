@echo off
REM ====================================================================
REM WSL2 Port Forwarding Setup for Odoo Network Access
REM Forwards Windows ports to WSL2 Odoo server
REM ====================================================================

echo.
echo ====================================================================
echo              CONFIGURING WSL2 PORT FORWARDING
echo ====================================================================
echo Setting up port forwarding from Windows to WSL2 Odoo server...
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script must be run as Administrator!
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

REM Get WSL2 IP address
echo Getting WSL2 IP address...
for /f "tokens=2 delims=:" %%i in ('wsl hostname -I') do set WSL_IP=%%i
set WSL_IP=%WSL_IP: =%

if "%WSL_IP%"=="" (
    echo ERROR: Could not detect WSL2 IP address!
    echo Make sure WSL2 is running and try again.
    pause
    exit /b 1
)

echo WSL2 IP detected: %WSL_IP%
echo.

REM Remove any existing port forwarding rules
echo Removing any existing port forwarding rules...
netsh interface portproxy delete v4tov4 listenport=8069 listenaddress=0.0.0.0 >nul 2>&1
netsh interface portproxy delete v4tov4 listenport=8072 listenaddress=0.0.0.0 >nul 2>&1

REM Add port forwarding rules
echo Adding port forwarding rule for Odoo HTTP (8069)...
netsh interface portproxy add v4tov4 listenport=8069 listenaddress=0.0.0.0 connectport=8069 connectaddress=%WSL_IP%

echo Adding port forwarding rule for Odoo Long Polling (8072)...
netsh interface portproxy add v4tov4 listenport=8072 listenaddress=0.0.0.0 connectport=8072 connectaddress=%WSL_IP%

echo.
echo ====================================================================
echo              WSL2 PORT FORWARDING CONFIGURED
echo ====================================================================
echo Port forwarding rules added:
echo - Windows Port 8069 → WSL2 %WSL_IP%:8069
echo - Windows Port 8072 → WSL2 %WSL_IP%:8072
echo.
echo Your friends can now access Odoo at:
echo http://192.168.6.42:8069
echo.
echo To verify rules, run:
echo netsh interface portproxy show v4tov4
echo ====================================================================

REM Show current port forwarding rules
echo.
echo Current port forwarding rules:
netsh interface portproxy show v4tov4

echo.
pause