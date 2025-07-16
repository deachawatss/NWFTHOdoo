@echo off
REM Odoo 17 Production Startup Script for Windows
REM Run this as Administrator

echo ============================================
echo      Odoo 17 Production Startup Script
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

REM Check if .env.production exists
if not exist ".env.production" (
    echo WARNING: .env.production not found!
    echo Using default .env.prod file...
    if exist ".env.prod" (
        copy ".env.prod" ".env.production"
        echo [INFO] Copied .env.prod to .env.production
    ) else (
        echo ERROR: No environment file found!
        pause
        exit /b 1
    )
)

echo [INFO] Environment configuration found
echo.

REM Create necessary directories
if not exist "nginx\ssl" mkdir "nginx\ssl"
if not exist "backup" mkdir "backup"
if not exist "scripts" mkdir "scripts"

echo [INFO] Directory structure verified
echo.

REM Start production services
echo [INFO] Starting Odoo 17 Production Environment...
echo [INFO] This may take a few minutes on first run...
echo.

docker-compose -f docker-compose.prod.yml up -d

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Failed to start services!
    echo Check the error messages above.
    pause
    exit /b 1
)

echo.
echo [SUCCESS] Services started successfully!
echo.

REM Wait a moment for services to initialize
echo [INFO] Waiting for services to initialize...
timeout /t 10 /nobreak >nul

REM Check service status
echo [INFO] Checking service status...
docker-compose -f docker-compose.prod.yml ps

echo.
echo ============================================
echo           Deployment Status
echo ============================================

REM Check if Odoo is responding
curl -s -o nul -w "Odoo HTTP Status: %%{http_code}\n" http://localhost:8069/web/health

echo.
echo Access URLs:
echo - Odoo Web Interface: http://localhost:8069
echo - With SSL (if configured): https://NWFTH.com
echo.
echo Next Steps:
echo 1. Open your browser and go to http://localhost:8069
echo 2. Create your production database
echo 3. Configure your Odoo settings
echo 4. Install required modules
echo.
echo For monitoring, run: docker-compose -f docker-compose.prod.yml logs -f
echo To stop services, run: docker-compose -f docker-compose.prod.yml down
echo.

pause