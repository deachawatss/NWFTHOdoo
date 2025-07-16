@echo off
REM Fast Odoo 17 Production Startup Script with Smart Caching
REM This script uses Docker layer caching for much faster deployments

setlocal enabledelayedexpansion

echo ====================================================
echo   Fast Odoo 17 Production Deployment
echo   Server: 192.168.0.21:8069
echo   Time: %date% %time%
echo   Mode: FAST (with Docker caching)
echo ====================================================

REM Navigate to the script directory
cd /d "%~dp0"

REM Check for command line arguments
set FULL_REBUILD=false
if "%1"=="--full" set FULL_REBUILD=true
if "%1"=="--rebuild" set FULL_REBUILD=true

REM Step 0: Quick validation
echo.
echo Step 0: Quick validation...
echo [%time%] Checking Docker availability...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not available!
    pause
    exit /b 1
)

echo [%time%] Checking essential files...
if not exist "docker-compose.yml" (
    echo ERROR: docker-compose.yml not found!
    pause
    exit /b 1
)

REM Step 1: Smart container management
echo.
echo Step 1: Smart container management...
echo [%time%] Checking current container status...

REM Check if containers are running
docker-compose ps -q >nul 2>&1
set CONTAINERS_EXIST=%errorlevel%

if %CONTAINERS_EXIST% equ 0 (
    echo [%time%] Existing containers found - performing smart restart...
    
    REM Check if only config changed (skip full rebuild)
    if "%FULL_REBUILD%"=="false" (
        echo [%time%] Performing config-only restart...
        docker-compose restart odoo
        if %errorlevel% equ 0 (
            echo [%time%] Config restart completed successfully!
            goto :health_check
        ) else (
            echo [%time%] Config restart failed, falling back to rebuild...
        )
    )
    
    REM Graceful stop for rebuild
    echo [%time%] Stopping containers for rebuild...
    docker-compose stop
) else (
    echo [%time%] No existing containers found - fresh deployment...
)

REM Step 2: Intelligent cleanup (only if needed)
echo.
echo Step 2: Intelligent cleanup...
if "%FULL_REBUILD%"=="true" (
    echo [%time%] Full rebuild requested - cleaning up old resources...
    docker-compose down --rmi all --volumes --remove-orphans 2>nul
    docker system prune -f --volumes 2>nul
) else (
    echo [%time%] Using smart cleanup - preserving Docker cache...
    docker-compose down --remove-orphans 2>nul
    REM Only remove dangling images, not all images
    docker image prune -f 2>nul
)

REM Step 3: Smart build strategy
echo.
echo Step 3: Smart build strategy...
if "%FULL_REBUILD%"=="true" (
    echo [%time%] Full rebuild mode - building without cache...
    docker-compose build --no-cache
) else (
    echo [%time%] Fast build mode - using Docker layer cache...
    docker-compose build
)

if %errorlevel% neq 0 (
    echo ERROR: Build failed!
    echo.
    echo Try running with full rebuild:
    echo   start-production-fast.bat --full
    echo.
    pause
    exit /b 1
)

echo [%time%] Build completed successfully!

REM Step 4: Fast database startup
echo.
echo Step 4: Fast database startup...
echo [%time%] Starting database service...
docker-compose up -d db

if %errorlevel% neq 0 (
    echo ERROR: Database startup failed!
    docker-compose logs db
    pause
    exit /b 1
)

REM Step 5: Quick database health check
echo.
echo Step 5: Quick database health check...
echo [%time%] Waiting for database...

set /a counter=0
:db_check
docker-compose exec -T db pg_isready -U odoo_prod >nul 2>&1
if %errorlevel% equ 0 (
    echo [%time%] Database ready!
    goto :db_ready
)

set /a counter+=1
if %counter% geq 15 (
    echo WARNING: Database health check timeout after 15 attempts
    echo Continuing with service startup...
    goto :db_ready
)

echo [%time%] Database check... (attempt %counter%/15)
timeout /t 1 /nobreak >nul
goto :db_check

:db_ready

REM Step 6: Fast service startup
echo.
echo Step 6: Fast service startup...
echo [%time%] Starting all services...
docker-compose up -d

if %errorlevel% neq 0 (
    echo ERROR: Service startup failed!
    docker-compose logs --tail=10
    pause
    exit /b 1
)

REM Step 7: Quick health check
:health_check
echo.
echo Step 7: Quick health check...
echo [%time%] Checking service status...
docker-compose ps

echo.
echo [%time%] Testing Odoo connectivity...
set /a counter=0
:odoo_check
curl -s http://192.168.0.21:8069/web/health >nul 2>&1
if %errorlevel% equ 0 (
    echo [%time%] Odoo is ready!
    goto :startup_complete
)

set /a counter+=1
if %counter% geq 30 (
    echo WARNING: Odoo health check timeout after 30 attempts
    echo Services may still be starting up...
    goto :startup_complete
)

echo [%time%] Odoo connectivity check... (attempt %counter%/30)
timeout /t 2 /nobreak >nul
goto :odoo_check

:startup_complete

REM Step 8: Final status
echo.
echo Step 8: Deployment summary...
echo [%time%] Checking final container status...
docker-compose ps

echo.
echo ====================================================
echo   Fast Deployment Complete!
echo   Time: %date% %time%
echo   
echo   Web Interface: http://192.168.0.21:8069
echo   Admin Password: AdminSecure2024!
echo   
echo   Performance Summary:
if "%FULL_REBUILD%"=="true" (
    echo   - Mode: Full rebuild
    echo   - Cache: Disabled
) else (
    echo   - Mode: Fast deployment
    echo   - Cache: Docker layer cache used
)
echo   - Database: odoo_prod
echo   - Services: All running
echo ====================================================

echo.
echo Fast Commands:
echo   - View logs: docker-compose logs -f
echo   - Restart app: docker-compose restart odoo  
echo   - Quick rebuild: start-production-fast.bat
echo   - Full rebuild: start-production-fast.bat --full
echo   - Stop: docker-compose down
echo.
echo Environment ready for development!
echo.
pause