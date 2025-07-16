@echo off
REM Test Docker Fixes for Entrypoint Issues

echo ====================================================
echo   Testing Docker Entrypoint Fixes
echo ====================================================

REM Navigate to the script directory
cd /d "%~dp0"

echo.
echo Step 1: Stopping any existing containers...
docker-compose down

echo.
echo Step 2: Removing old images to force rebuild...
docker-compose build --no-cache

if %errorlevel% neq 0 (
    echo ERROR: Build failed!
    pause
    exit /b 1
)

echo.
echo Step 3: Testing container creation...
docker-compose up -d db

echo.
echo Step 4: Waiting for database...
timeout /t 30

echo.
echo Step 5: Testing Odoo container...
docker-compose up -d odoo

echo.
echo Step 6: Checking container status...
docker-compose ps

echo.
echo Step 7: Checking Odoo logs for entrypoint errors...
docker-compose logs odoo --tail=20

echo.
echo Step 8: Testing backup container...
docker-compose build backup --no-cache

echo.
echo ====================================================
echo   Test completed!
echo   Check the output above for any errors.
echo ====================================================

pause