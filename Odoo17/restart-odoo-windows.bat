@echo off
REM ====================================================
REM   Odoo 17 Windows Restart Script
REM   Stops and restarts Odoo server
REM ====================================================

setlocal enabledelayedexpansion

REM Set colors for output
set GREEN=[92m
set RED=[91m
set YELLOW=[93m
set BLUE=[94m
set NC=[0m

echo %BLUE%======================================================%NC%
echo %BLUE%       Restarting Odoo 17 - Windows Native Mode%NC%
echo %BLUE%       Time: %date% %time%%NC%
echo %BLUE%======================================================%NC%
echo.

REM Navigate to the script directory
cd /d "%~dp0"

REM Step 1: Stop existing Odoo processes
echo %GREEN%[%time%] Step 1: Stopping existing Odoo processes...%NC%

REM Look for Python processes running odoo-bin
set PROCESSES_FOUND=false

for /f "tokens=2" %%i in ('tasklist /FI "IMAGENAME eq python.exe" /FO CSV ^| findstr /C:"python.exe"') do (
    set PID=%%i
    set PID=!PID:"=!
    
    REM Check if this process is running odoo-bin
    wmic process where "ProcessId=!PID!" get CommandLine /value 2>nul | findstr /C:"odoo-bin" >nul 2>&1
    if !errorlevel! equ 0 (
        echo %YELLOW%[%time%] Found Odoo process (PID: !PID!), stopping...%NC%
        set PROCESSES_FOUND=true
        
        REM Try graceful shutdown first
        taskkill /PID !PID! >nul 2>&1
        timeout /t 3 /nobreak >nul
        
        REM Check if process still exists and force kill if needed
        tasklist /FI "PID eq !PID!" 2>nul | find "!PID!" >nul
        if !errorlevel! equ 0 (
            taskkill /F /PID !PID! >nul 2>&1
        )
    )
)

if "%PROCESSES_FOUND%"=="false" (
    echo %GREEN%[%time%] No running Odoo processes found.%NC%
) else (
    echo %GREEN%[%time%] Existing Odoo processes stopped.%NC%
    
    REM Wait a moment for cleanup
    echo %GREEN%[%time%] Waiting for cleanup...%NC%
    timeout /t 5 /nobreak >nul
)

REM Step 2: Verify environment before restart
echo %GREEN%[%time%] Step 2: Verifying environment...%NC%

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

echo %GREEN%[%time%] Environment validation passed.%NC%

REM Step 3: Prepare for restart
echo %GREEN%[%time%] Step 3: Preparing for restart...%NC%

REM Create logs directory if it doesn't exist
if not exist "logs" (
    mkdir logs
    echo %GREEN%[%time%] Created logs directory.%NC%
)

REM Archive old log file
if exist "logs\odoo.log" (
    set timestamp=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%
    set timestamp=!timestamp: =0!
    
    if not exist "logs\archived" mkdir logs\archived
    ren "logs\odoo.log" "odoo.log.!timestamp!"
    move "odoo.log.!timestamp!" "logs\archived\" >nul 2>&1
    echo %GREEN%[%time%] Previous log file archived.%NC%
)

REM Step 4: Activate virtual environment
echo %GREEN%[%time%] Step 4: Activating virtual environment...%NC%

call odoo_env\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo %RED%ERROR: Failed to activate virtual environment!%NC%
    pause
    exit /b 1
)

echo %GREEN%[%time%] Virtual environment activated.%NC%

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

REM Step 6: Check database connectivity (optional)
echo %GREEN%[%time%] Step 6: Checking database connectivity...%NC%

pg_isready -h localhost -p 5432 -U odoo_prod >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[%time%] Database connection test passed.%NC%
) else (
    echo %YELLOW%[%time%] Database connection test failed or pg_isready not available.%NC%
    echo %YELLOW%[%time%] Odoo will try to connect on startup.%NC%
)

REM Step 7: Display restart information
echo.
echo %BLUE%======================================================%NC%
echo %BLUE%Restart Configuration:%NC%
echo %BLUE%- Mode: Windows Native%NC%
echo %BLUE%- Config File: odoo-windows.conf%NC%
echo %BLUE%- Log File: logs\odoo.log%NC%
echo %BLUE%- Data Directory: data\%NC%
echo %BLUE%- Web Interface: http://192.168.0.21:8069%NC%
echo %BLUE%- Admin Password: AdminSecure2024!%NC%
echo %BLUE%======================================================%NC%
echo.

echo %GREEN%[%time%] Restarting Odoo server...%NC%
echo %YELLOW%Press Ctrl+C to stop the server%NC%
echo %YELLOW%Close this window to run Odoo in background%NC%
echo.

REM Step 8: Restart Odoo server
echo %GREEN%Restarting Odoo17 server - Please wait...%NC%
echo.

REM Give user option to run in background or foreground
echo %BLUE%Choose restart mode:%NC%
echo %BLUE%1. Foreground (see logs in this window)%NC%
echo %BLUE%2. Background (run silently, close this window)%NC%
echo %BLUE%3. Cancel restart%NC%
echo.
set /p RESTART_MODE=Enter choice (1-3): 

if "%RESTART_MODE%"=="1" (
    echo.
    echo %GREEN%Starting Odoo in foreground mode...%NC%
    echo %YELLOW%Press Ctrl+C to stop the server%NC%
    echo.
    python odoo-bin -c odoo-windows.conf --log-level=info
    
    REM This will only run if Odoo exits normally
    echo.
    echo %BLUE%======================================================%NC%
    echo %BLUE%Odoo server stopped.%NC%
    echo %BLUE%Time: %date% %time%%NC%
    echo %BLUE%======================================================%NC%
    
) else if "%RESTART_MODE%"=="2" (
    echo.
    echo %GREEN%Starting Odoo in background mode...%NC%
    echo %GREEN%Server will continue running after this window closes.%NC%
    echo.
    
    REM Start Odoo in background
    start /min "Odoo17 Server" python odoo-bin -c odoo-windows.conf --log-level=info
    
    REM Wait a moment to check if it started successfully
    timeout /t 3 /nobreak >nul
    
    REM Check if process is running
    tasklist /FI "IMAGENAME eq python.exe" /FO CSV | findstr /C:"python.exe" >nul 2>&1
    if %errorlevel% equ 0 (
        echo %GREEN%✓ Odoo server started successfully in background%NC%
        echo %BLUE%- Web Interface: http://192.168.0.21:8069%NC%
        echo %BLUE%- Log File: logs\odoo.log%NC%
        echo %BLUE%- Use stop-odoo-windows.bat to stop the server%NC%
        echo %BLUE%- Use logs-odoo-windows.bat to view logs%NC%
    ) else (
        echo %RED%✗ Failed to start Odoo server%NC%
        echo %YELLOW%Check logs\odoo.log for error details%NC%
    )
    
) else if "%RESTART_MODE%"=="3" (
    echo.
    echo %YELLOW%Restart cancelled by user.%NC%
    echo %BLUE%Odoo remains stopped.%NC%
    
) else (
    echo.
    echo %RED%Invalid choice. Restart cancelled.%NC%
    echo %BLUE%Odoo remains stopped.%NC%
)

echo.
echo %BLUE%======================================================%NC%
echo %BLUE%Available Commands:%NC%
echo %BLUE%- start-odoo-windows.bat   : Start Odoo server%NC%
echo %BLUE%- stop-odoo-windows.bat    : Stop Odoo server%NC%
echo %BLUE%- restart-odoo-windows.bat : Restart Odoo server%NC%
echo %BLUE%- logs-odoo-windows.bat    : View server logs%NC%
echo %BLUE%======================================================%NC%

echo Press any key to close this window...
pause >nul