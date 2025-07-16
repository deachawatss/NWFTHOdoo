@echo off
REM Odoo 17 Production Stop Script for Windows
REM Run this as Administrator

echo ============================================
echo       Odoo 17 Production Stop Script
echo ============================================
echo.

REM Check if Docker is running
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not running or not installed!
    echo Please start Docker Desktop and try again.
    pause
    exit /b 1
)

echo [INFO] Docker is running
echo.

REM Check if docker-compose.prod.yml exists
if not exist "docker-compose.prod.yml" (
    echo ERROR: docker-compose.prod.yml not found!
    echo Please ensure you are in the correct directory.
    pause
    exit /b 1
)

echo [INFO] Production configuration found
echo.

REM Show current running services
echo [INFO] Current running services:
docker-compose -f docker-compose.prod.yml ps

echo.
echo [INFO] Stopping Odoo 17 Production Environment...

REM Stop all services
docker-compose -f docker-compose.prod.yml down

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Failed to stop services properly!
    echo Some services may still be running.
    pause
    exit /b 1
)

echo.
echo [SUCCESS] All services stopped successfully!
echo.

REM Optionally remove volumes (commented out for safety)
REM echo [INFO] To remove all data (databases, files), run:
REM echo docker-compose -f docker-compose.prod.yml down -v
REM echo WARNING: This will delete all your data!

echo.
echo Services stopped. Data is preserved in Docker volumes.
echo To restart, run: windows-startup.bat
echo.

pause