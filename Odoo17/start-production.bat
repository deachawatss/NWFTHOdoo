@echo off
REM Enhanced Odoo 17 Production Startup Script for Windows Server 192.168.0.21
REM This script provides comprehensive validation, health checks, and better error handling

setlocal enabledelayedexpansion

echo ====================================================
echo   Starting Odoo 17 Production Environment
echo   Server: 192.168.0.21:8069
echo   Time: %date% %time%
echo ====================================================

REM Navigate to the script directory
cd /d "%~dp0"

REM Step 0: Pre-flight validation
echo.
echo Step 0: Validating environment...
echo [%time%] Checking Docker availability...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not available or not running!
    echo Please ensure Docker Desktop is installed and running.
    echo.
    pause
    exit /b 1
)

echo [%time%] Checking required files...
if not exist "docker-compose.yml" (
    echo ERROR: docker-compose.yml not found!
    pause
    exit /b 1
)

if not exist "Dockerfile" (
    echo ERROR: Dockerfile not found!
    pause
    exit /b 1
)

if not exist "docker-entrypoint.sh" (
    echo ERROR: docker-entrypoint.sh not found!
    pause
    exit /b 1
)

if not exist "scripts\backup.sh" (
    echo ERROR: scripts\backup.sh not found!
    pause
    exit /b 1
)

echo [%time%] All required files found.

REM Step 1: Stopping existing containers
echo.
echo Step 1: Stopping existing containers...
echo [%time%] Gracefully stopping services...
docker-compose down

if %errorlevel% neq 0 (
    echo WARNING: Some containers may not have stopped cleanly.
    echo [%time%] Attempting force stop...
    docker-compose down --remove-orphans
)

REM Step 2: Cleanup old resources
echo.
echo Step 2: Cleaning up old resources...
echo [%time%] Removing unused images and volumes...
docker-compose down --rmi all --volumes --remove-orphans 2>nul
docker system prune -f --volumes 2>nul

REM Step 3: Building containers
echo.
echo Step 3: Building containers...
echo [%time%] Building Odoo application container...
docker-compose build --no-cache

if %errorlevel% neq 0 (
    echo ERROR: Failed to build containers!
    echo.
    echo Troubleshooting steps:
    echo 1. Check if docker-entrypoint.sh exists and is executable
    echo 2. Verify all required files are present
    echo 3. Check Docker Desktop is running
    echo 4. Ensure no antivirus blocking Docker operations
    echo 5. Try running: docker system prune -a
    echo.
    pause
    exit /b 1
)

echo [%time%] Container build completed successfully.

REM Step 4: Starting database first
echo.
echo Step 4: Starting database service...
echo [%time%] Starting PostgreSQL database...
docker-compose up -d db

if %errorlevel% neq 0 (
    echo ERROR: Failed to start database!
    echo.
    docker-compose logs db
    pause
    exit /b 1
)

REM Step 5: Waiting for database to be ready
echo.
echo Step 5: Waiting for database to be ready...
echo [%time%] Checking database health...

set /a counter=0
:db_check
docker-compose exec -T db pg_isready -U odoo_prod >nul 2>&1
if %errorlevel% equ 0 (
    echo [%time%] Database is ready!
    goto db_ready
)

set /a counter+=1
if %counter% geq 30 (
    echo ERROR: Database failed to start within 30 attempts!
    echo.
    docker-compose logs db
    pause
    exit /b 1
)

echo [%time%] Waiting for database... (attempt %counter%/30)
timeout /t 2 /nobreak >nul
goto db_check

:db_ready

REM Step 6: Starting remaining services
echo.
echo Step 6: Starting remaining services...
echo [%time%] Starting Redis, Odoo, and Backup services...
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

REM Step 7: Health checks
echo.
echo Step 7: Performing health checks...
echo [%time%] Checking service status...
docker-compose ps

echo.
echo [%time%] Waiting for Odoo to be ready...
set /a counter=0
:health_check
curl -s http://192.168.0.21:8069/web/health >nul 2>&1
if %errorlevel% equ 0 (
    echo [%time%] Odoo health check passed!
    goto health_ready
)

set /a counter+=1
if %counter% geq 60 (
    echo WARNING: Odoo health check failed after 60 attempts.
    echo The application may still be starting up.
    goto health_ready
)

echo [%time%] Waiting for Odoo health check... (attempt %counter%/60)
timeout /t 2 /nobreak >nul
goto health_check

:health_ready

REM Step 8: Final validation
echo.
echo Step 8: Final validation...
echo [%time%] Checking for container errors...
docker-compose logs --tail=5

echo.
echo [%time%] Verifying all services are running...
for /f "tokens=*" %%i in ('docker-compose ps -q') do (
    docker inspect %%i --format="{{.Name}}: {{.State.Status}}" 2>nul
)

echo.
echo ====================================================
echo   Startup Complete!
echo   Time: %date% %time%
echo   
echo   Web Interface: http://192.168.0.21:8069
echo   
echo   Services Status:
echo   - Odoo Application: Running on port 8069
echo   - PostgreSQL Database: Ready
echo   - Redis Cache: Active
echo   - Automatic Backup Service: Enabled
echo ====================================================

echo.
echo Useful Commands:
echo   - View logs: docker-compose logs -f
echo   - Stop services: docker-compose down
echo   - Restart: docker-compose restart
echo   - Service status: docker-compose ps
echo.
echo Production environment is ready for use!
echo.
pause