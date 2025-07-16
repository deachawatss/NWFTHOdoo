@echo off
REM Odoo 17 Production Startup Script for Windows Server 192.168.0.21
REM This script will build and start your Odoo production environment

echo ====================================================
echo   Starting Odoo 17 Production Environment
echo   Server: 192.168.0.21
echo ====================================================

REM Navigate to the script directory
cd /d "%~dp0"

echo.
echo Building Docker containers...
docker-compose build

if %errorlevel% neq 0 (
    echo ERROR: Failed to build containers!
    pause
    exit /b 1
)

echo.
echo Starting services...
docker-compose up -d

if %errorlevel% neq 0 (
    echo ERROR: Failed to start services!
    pause
    exit /b 1
)

echo.
echo ====================================================
echo   Odoo 17 is starting up...
echo   
echo   Web Interface: http://192.168.0.21
echo   
echo   Services started:
echo   - Odoo Application (Port 80)
echo   - PostgreSQL Database
echo   - Redis Cache
echo   - Automatic Backup Service
echo ====================================================

echo.
echo Checking service status...
docker-compose ps

echo.
echo To view logs: docker-compose logs -f
echo To stop services: docker-compose down
echo.
pause