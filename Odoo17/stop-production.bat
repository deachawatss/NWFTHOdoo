@echo off
REM Stop Odoo 17 Production Environment

echo ====================================================
echo   Stopping Odoo 17 Production Environment
echo ====================================================

REM Navigate to the script directory
cd /d "%~dp0"

echo.
echo Stopping services gracefully...
docker-compose down

if %errorlevel% neq 0 (
    echo ERROR: Failed to stop services!
    pause
    exit /b 1
)

echo.
echo ====================================================
echo   All services stopped successfully
echo   
echo   Your data is preserved in Docker volumes
echo   To restart: run start-production.bat
echo ====================================================

echo.
pause