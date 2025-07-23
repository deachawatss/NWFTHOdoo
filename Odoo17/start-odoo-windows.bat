@echo off
REM ====================================================
REM   Odoo 17 Windows Native Startup Script
REM   Double-click this file to start Odoo17
REM   Server: 192.168.0.21:8069
REM ====================================================

setlocal enabledelayedexpansion

REM Set colors for output
set GREEN=[92m
set RED=[91m
set YELLOW=[93m
set BLUE=[94m
set NC=[0m

echo %BLUE%======================================================%NC%
echo %BLUE%       Starting Odoo 17 - Windows Native Mode%NC%
echo %BLUE%       Server: 192.168.0.21:8069%NC%
echo %BLUE%       Time: %date% %time%%NC%
echo %BLUE%======================================================%NC%
echo.

REM Navigate to the script directory
cd /d "%~dp0"

REM Step 1: Validate environment
echo %GREEN%[%time%] Step 1: Validating environment...%NC%

REM Check if required files exist
if not exist "odoo-bin" (
    echo %RED%ERROR: odoo-bin not found!%NC%
    echo Please ensure you're in the correct Odoo directory.
    pause
    exit /b 1
)

if not exist "odoo-windows.conf" (
    echo %RED%ERROR: odoo-windows.conf not found!%NC%
    echo Please ensure Windows configuration file exists.
    pause
    exit /b 1
)

if not exist "odoo_env" (
    echo %RED%ERROR: Virtual environment 'odoo_env' not found!%NC%
    echo Please run 'setup-windows-environment.bat' first.
    pause
    exit /b 1
)

if not exist "odoo_env\Scripts\activate.bat" (
    echo %RED%ERROR: Virtual environment activation script not found!%NC%
    echo Please recreate the virtual environment.
    pause
    exit /b 1
)

echo %GREEN%[%time%] Environment validation passed!%NC%

REM Step 2: Check for running Odoo processes
echo %GREEN%[%time%] Step 2: Checking for running Odoo processes...%NC%

REM Kill any existing Odoo processes
tasklist /FI "IMAGENAME eq python.exe" /FO CSV | findstr /C:"odoo-bin" >nul 2>&1
if %errorlevel% equ 0 (
    echo %YELLOW%[%time%] Found running Odoo process. Stopping it...%NC%
    taskkill /F /IM python.exe /FI "WINDOWTITLE eq Odoo*" >nul 2>&1
    timeout /t 3 /nobreak >nul
    echo %GREEN%[%time%] Existing Odoo process stopped.%NC%
) else (
    echo %GREEN%[%time%] No running Odoo process found.%NC%
)

REM Step 3: Prepare directories and logs
echo %GREEN%[%time%] Step 3: Preparing directories and logs...%NC%

REM Create logs directory if it doesn't exist
if not exist "logs" (
    mkdir logs
    echo %GREEN%[%time%] Created logs directory.%NC%
)

REM Create data directory if it doesn't exist
if not exist "data" (
    mkdir data
    echo %GREEN%[%time%] Created data directory.%NC%
)

REM Archive old log file
if exist "logs\odoo.log" (
    set timestamp=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%
    set timestamp=!timestamp: =0!
    ren "logs\odoo.log" "odoo.log.!timestamp!"
    echo %GREEN%[%time%] Old log file archived.%NC%
)

REM Step 4: Activate virtual environment
echo %GREEN%[%time%] Step 4: Activating virtual environment...%NC%
call odoo_env\Scripts\activate.bat

if %errorlevel% neq 0 (
    echo %RED%ERROR: Failed to activate virtual environment!%NC%
    pause
    exit /b 1
)

echo %GREEN%[%time%] Virtual environment activated successfully.%NC%

REM Step 5: Validate Python environment
echo %GREEN%[%time%] Step 5: Validating Python environment...%NC%

python -c "import odoo" >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%ERROR: Odoo Python package not found!%NC%
    echo Please install requirements: pip install -r requirements.txt
    pause
    exit /b 1
)

echo %GREEN%[%time%] Python environment validation passed.%NC%

REM Step 6: Check database connectivity (if pg_isready is available)
echo %GREEN%[%time%] Step 6: Checking database connectivity...%NC%

pg_isready -h localhost -p 5432 -U odoo_prod >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[%time%] Database connection test passed.%NC%
) else (
    echo %YELLOW%[%time%] Database connection test failed or pg_isready not available.%NC%
    echo %YELLOW%[%time%] Odoo will try to connect on startup.%NC%
)

REM Step 7: Display startup information
echo.
echo %BLUE%======================================================%NC%
echo %BLUE%Configuration:%NC%
echo %BLUE%- Mode: Windows Native%NC%
echo %BLUE%- Config File: odoo-windows.conf%NC%
echo %BLUE%- Log File: logs\odoo.log%NC%
echo %BLUE%- Data Directory: data\%NC%
echo %BLUE%- Web Interface: http://192.168.0.21:8069%NC%
echo %BLUE%- Admin Password: AdminSecure2024!%NC%
echo %BLUE%======================================================%NC%
echo.

echo %GREEN%[%time%] Starting Odoo server...%NC%
echo %YELLOW%Press Ctrl+C to stop the server%NC%
echo.

REM Step 8: Start Odoo server
echo %GREEN%Starting Odoo17 server - Please wait...%NC%
echo.

REM Start Odoo and capture output
python odoo-bin -c odoo-windows.conf --log-level=info

REM This will only run if Odoo exits normally (not with Ctrl+C)
echo.
echo %BLUE%======================================================%NC%
echo %BLUE%Odoo server stopped.%NC%
echo %BLUE%Log file saved as: logs\odoo.log%NC%
echo %BLUE%Time: %date% %time%%NC%
echo %BLUE%======================================================%NC%
echo.

REM Auto-open browser after a short delay (optional)
REM timeout /t 5 /nobreak >nul
REM start http://192.168.0.21:8069

echo Press any key to close this window...
pause >nul