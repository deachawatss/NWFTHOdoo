@echo off
REM Odoo 17 Production Startup Script for Windows Server 192.168.0.21
REM This script will build and start your Odoo production environment

echo ====================================================
echo   Starting Odoo 17 Production Environment
echo   Server: 192.168.0.21:8069
echo ====================================================

REM Navigate to the script directory
cd /d "%~dp0"

echo.
echo Step 1: Stopping existing containers...
docker-compose down

echo.
echo Step 2: Cleaning up Docker cache and old images...
docker system prune -f
docker-compose build --no-cache

if %errorlevel% neq 0 (
    echo ERROR: Failed to build containers!
    echo.
    echo Troubleshooting:
    echo 1. Check if docker-entrypoint.sh exists and is executable
    echo 2. Verify all required files are present
    echo 3. Check Docker Desktop is running
    echo.
    pause
    exit /b 1
)

echo.
echo Step 3: Starting database first...
docker-compose up -d db

echo.
echo Step 4: Waiting for database to be ready...
timeout /t 30

echo.
echo Step 5: Starting remaining services...
docker-compose up -d

if %errorlevel% neq 0 (
    echo ERROR: Failed to start services!
    echo.
    echo Checking logs...
    docker-compose logs --tail=10
    echo.
    pause
    exit /b 1
)

echo.
echo ====================================================
echo   Odoo 17 is starting up...
echo   
echo   Web Interface: http://192.168.0.21:8069
echo   
echo   Services started:
echo   - Odoo Application (Port 8069)
echo   - PostgreSQL Database
echo   - Redis Cache
echo   - Automatic Backup Service
echo ====================================================

echo.
echo Step 6: Checking service status...
docker-compose ps

echo.
echo Step 7: Checking for any container errors...
docker-compose logs --tail=5

echo.
echo ====================================================
echo   Startup Complete!
echo   
echo   Commands:
echo   - View logs: docker-compose logs -f
echo   - Stop services: docker-compose down
echo   - Restart: docker-compose restart
echo ====================================================
echo.
pause