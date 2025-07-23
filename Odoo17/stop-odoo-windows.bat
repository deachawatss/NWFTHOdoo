@echo off
REM ====================================================
REM   Odoo 17 Windows Stop Script
REM   Safely stops running Odoo processes
REM ====================================================

setlocal enabledelayedexpansion

REM Set colors for output
set GREEN=[92m
set RED=[91m
set YELLOW=[93m
set BLUE=[94m
set NC=[0m

echo %BLUE%======================================================%NC%
echo %BLUE%       Stopping Odoo 17 - Windows Native Mode%NC%
echo %BLUE%       Time: %date% %time%%NC%
echo %BLUE%======================================================%NC%
echo.

REM Navigate to the script directory
cd /d "%~dp0"

REM Step 1: Check for running Odoo processes
echo %GREEN%[%time%] Step 1: Checking for running Odoo processes...%NC%

REM Look for Python processes running odoo-bin
set PROCESSES_FOUND=false

for /f "tokens=2" %%i in ('tasklist /FI "IMAGENAME eq python.exe" /FO CSV ^| findstr /C:"python.exe"') do (
    set PID=%%i
    set PID=!PID:"=!
    
    REM Check if this process is running odoo-bin
    wmic process where "ProcessId=!PID!" get CommandLine /value 2>nul | findstr /C:"odoo-bin" >nul 2>&1
    if !errorlevel! equ 0 (
        echo %YELLOW%[%time%] Found Odoo process (PID: !PID!)%NC%
        set PROCESSES_FOUND=true
        
        REM Try graceful shutdown first
        echo %GREEN%[%time%] Attempting graceful shutdown...%NC%
        taskkill /PID !PID! >nul 2>&1
        
        REM Wait a moment for graceful shutdown
        timeout /t 5 /nobreak >nul
        
        REM Check if process still exists
        tasklist /FI "PID eq !PID!" 2>nul | find "!PID!" >nul
        if !errorlevel! equ 0 (
            echo %YELLOW%[%time%] Graceful shutdown failed, forcing termination...%NC%
            taskkill /F /PID !PID! >nul 2>&1
            if !errorlevel! equ 0 (
                echo %GREEN%[%time%] Process !PID! terminated successfully.%NC%
            ) else (
                echo %RED%[%time%] Failed to terminate process !PID!%NC%
            )
        ) else (
            echo %GREEN%[%time%] Process !PID! stopped gracefully.%NC%
        )
    )
)

if "%PROCESSES_FOUND%"=="false" (
    echo %GREEN%[%time%] No running Odoo processes found.%NC%
) else (
    echo %GREEN%[%time%] All Odoo processes have been stopped.%NC%
)

REM Step 2: Check for any remaining python processes with Odoo in command line
echo %GREEN%[%time%] Step 2: Final cleanup check...%NC%

REM More aggressive search for any remaining Odoo processes
tasklist /FI "IMAGENAME eq python.exe" /FO CSV 2>nul | findstr /C:"python.exe" >nul 2>&1
if %errorlevel% equ 0 (
    echo %YELLOW%[%time%] Checking remaining Python processes for Odoo...%NC%
    
    REM Kill any remaining python processes that might be Odoo-related
    for /f "tokens=2" %%i in ('tasklist /FI "IMAGENAME eq python.exe" /FO CSV ^| findstr /C:"python.exe"') do (
        set PID=%%i
        set PID=!PID:"=!
        
        REM Check command line for odoo-related terms
        wmic process where "ProcessId=!PID!" get CommandLine /value 2>nul | findstr /i /C:"odoo" >nul 2>&1
        if !errorlevel! equ 0 (
            echo %YELLOW%[%time%] Found remaining Odoo-related process (PID: !PID!), terminating...%NC%
            taskkill /F /PID !PID! >nul 2>&1
        )
    )
)

REM Step 3: Check for port usage (port 8069)
echo %GREEN%[%time%] Step 3: Checking port 8069 status...%NC%

netstat -an | findstr :8069 >nul 2>&1
if %errorlevel% equ 0 (
    echo %YELLOW%[%time%] Port 8069 is still in use. Checking process...%NC%
    
    REM Find process using port 8069
    for /f "tokens=5" %%i in ('netstat -ano ^| findstr :8069') do (
        set PORT_PID=%%i
        if not "!PORT_PID!"=="0" (
            echo %YELLOW%[%time%] Process !PORT_PID! is using port 8069, terminating...%NC%
            taskkill /F /PID !PORT_PID! >nul 2>&1
        )
    )
) else (
    echo %GREEN%[%time%] Port 8069 is free.%NC%
)

REM Step 4: Archive current log file
echo %GREEN%[%time%] Step 4: Archiving log file...%NC%

if exist "logs\odoo.log" (
    set timestamp=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%
    set timestamp=!timestamp: =0!
    
    if not exist "logs\archived" mkdir logs\archived
    
    copy "logs\odoo.log" "logs\archived\odoo.log.!timestamp!" >nul 2>&1
    if %errorlevel% equ 0 (
        echo %GREEN%[%time%] Log file archived as: logs\archived\odoo.log.!timestamp!%NC%
        
        REM Clear the current log file
        echo. > "logs\odoo.log"
        echo %GREEN%[%time%] Current log file cleared.%NC%
    ) else (
        echo %YELLOW%[%time%] Could not archive log file.%NC%
    )
) else (
    echo %GREEN%[%time%] No log file to archive.%NC%
)

REM Step 5: Clean up temporary files (optional)
echo %GREEN%[%time%] Step 5: Cleaning up temporary files...%NC%

REM Clean up Python cache files
if exist "__pycache__" (
    rmdir /s /q "__pycache__" 2>nul
    echo %GREEN%[%time%] Python cache cleaned.%NC%
)

REM Clean up session files (if using filesystem sessions)
if exist "data\sessions" (
    del /q "data\sessions\*" 2>nul
    echo %GREEN%[%time%] Session files cleaned.%NC%
)

REM Final status check
echo.
echo %BLUE%======================================================%NC%
echo %BLUE%Final Status Check:%NC%
echo %BLUE%======================================================%NC%

REM Check if any Odoo processes are still running
tasklist /FI "IMAGENAME eq python.exe" /FO CSV 2>nul | findstr /C:"python.exe" >nul 2>&1
if %errorlevel% equ 0 (
    set ODOO_STILL_RUNNING=false
    for /f "tokens=2" %%i in ('tasklist /FI "IMAGENAME eq python.exe" /FO CSV ^| findstr /C:"python.exe"') do (
        set PID=%%i
        set PID=!PID:"=!
        wmic process where "ProcessId=!PID!" get CommandLine /value 2>nul | findstr /i /C:"odoo" >nul 2>&1
        if !errorlevel! equ 0 (
            set ODOO_STILL_RUNNING=true
        )
    )
    
    if "!ODOO_STILL_RUNNING!"=="true" (
        echo %RED%✗ Some Odoo processes may still be running%NC%
        echo %YELLOW%  You may need to restart Windows or manually kill processes%NC%
    ) else (
        echo %GREEN%✓ All Odoo processes stopped successfully%NC%
    )
) else (
    echo %GREEN%✓ All Python processes stopped%NC%
)

REM Check port status
netstat -an | findstr :8069 >nul 2>&1
if %errorlevel% equ 0 (
    echo %YELLOW%✗ Port 8069 may still be in use%NC%
    echo %YELLOW%  Port may take a moment to be released%NC%
) else (
    echo %GREEN%✓ Port 8069 is free%NC%
)

echo %GREEN%✓ Log files archived%NC%
echo %GREEN%✓ Temporary files cleaned%NC%

echo.
echo %BLUE%======================================================%NC%
echo %BLUE%Odoo 17 Stop Complete%NC%
echo %BLUE%Time: %date% %time%%NC%
echo %BLUE%======================================================%NC%
echo.
echo %GREEN%Odoo server has been stopped.%NC%
echo %BLUE%- Log files archived to logs\archived\%NC%
echo %BLUE%- Port 8069 should be available%NC%
echo %BLUE%- Temporary files cleaned%NC%
echo.
echo %BLUE%To restart Odoo:%NC%
echo %BLUE%- Double-click start-odoo-windows.bat%NC%
echo %BLUE%- Or run: restart-odoo-windows.bat%NC%
echo.

echo Press any key to close this window...
pause >nul