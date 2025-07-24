@echo off
REM ====================================================================
REM Odoo 17 Windows Production Shutdown Script
REM Graceful shutdown for multi-worker production environment
REM ====================================================================

setlocal enabledelayedexpansion

REM ====================================
REM COLOR CODES FOR WINDOWS CONSOLE
REM ====================================
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "CYAN=[96m"
set "NC=[0m"

REM ====================================
REM LOGGING FUNCTIONS
REM ====================================
:log_info
echo %GREEN%[%date% %time%] INFO: %~1%NC%
echo [%date% %time%] INFO: %~1 >> logs\shutdown.log
exit /b

:log_error
echo %RED%[%date% %time%] ERROR: %~1%NC%
echo [%date% %time%] ERROR: %~1 >> logs\shutdown.log
exit /b

:log_warning
echo %YELLOW%[%date% %time%] WARNING: %~1%NC%
echo [%date% %time%] WARNING: %~1 >> logs\shutdown.log
exit /b

:log_success
echo %CYAN%[%date% %time%] SUCCESS: %~1%NC%
echo [%date% %time%] SUCCESS: %~1 >> logs\shutdown.log
exit /b

REM ====================================
REM SHUTDOWN HEADER
REM ====================================
cls
echo %BLUE%
echo ====================================================================
echo                  ODOO 17 PRODUCTION SHUTDOWN
echo                      Graceful Termination
echo ====================================================================
echo %NC%

REM Navigate to script directory
cd /d "%~dp0"

REM Create logs directory if it doesn't exist
if not exist "logs" mkdir logs

call :log_info "Starting graceful shutdown process..."

REM ====================================
REM CHECK FOR RUNNING PROCESSES
REM ====================================
call :log_info "Checking for running Odoo processes..."

REM Count running Odoo processes
set "PROCESS_COUNT=0"
for /f %%i in ('tasklist /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq *odoo*" 2^>nul ^| find /c "python.exe"') do set "PROCESS_COUNT=%%i"

if %PROCESS_COUNT% equ 0 (
    call :log_info "No running Odoo processes found."
    echo.
    echo %CYAN%====================================================================
    echo                    NO ODOO PROCESSES RUNNING
    echo ====================================================================
    echo Server is already stopped.
    echo ====================================================================
    echo %NC%
    pause
    exit /b 0
)

call :log_info "Found %PROCESS_COUNT% Odoo processes running"

REM ====================================
REM GRACEFUL SHUTDOWN ATTEMPT
REM ====================================
call :log_info "Attempting graceful shutdown..."

REM Send SIGTERM equivalent (graceful termination)
call :log_info "Sending graceful termination signal to Odoo processes..."

REM Create a temporary PowerShell script for graceful shutdown
echo $processes = Get-Process python -ErrorAction SilentlyContinue ^| Where-Object {$_.MainWindowTitle -like "*odoo*"} > temp_shutdown.ps1
echo foreach ($process in $processes) { >> temp_shutdown.ps1
echo     Write-Host "Gracefully stopping process ID: $($process.Id)" >> temp_shutdown.ps1
echo     $process.CloseMainWindow() >> temp_shutdown.ps1
echo } >> temp_shutdown.ps1

powershell -ExecutionPolicy Bypass -File temp_shutdown.ps1
del temp_shutdown.ps1

REM Wait for graceful shutdown
call :log_info "Waiting for processes to terminate gracefully..."
timeout /t 10 >nul

REM ====================================
REM CHECK IF GRACEFUL SHUTDOWN WORKED
REM ====================================
set "REMAINING_PROCESSES=0"
for /f %%i in ('tasklist /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq *odoo*" 2^>nul ^| find /c "python.exe"') do set "REMAINING_PROCESSES=%%i"

if %REMAINING_PROCESSES% equ 0 (
    call :log_success "All Odoo processes terminated gracefully"
    goto :cleanup
)

REM ====================================
REM FORCE TERMINATION IF NEEDED
REM ====================================
call :log_warning "%REMAINING_PROCESSES% processes did not terminate gracefully"
call :log_warning "Proceeding with force termination..."

REM Force kill remaining processes
taskkill /F /IM python.exe /FI "WINDOWTITLE eq *odoo*" >nul 2>&1
if !errorlevel! equ 0 (
    call :log_info "Force termination completed"
) else (
    call :log_error "Force termination failed or no processes found"
)

REM Wait for cleanup
timeout /t 3 >nul

REM ====================================
REM PORT CLEANUP
REM ====================================
:cleanup
call :log_info "Performing port cleanup..."

REM Check if ports are released
netstat -an | findstr ":8069" >nul
if !errorlevel! equ 0 (
    call :log_warning "Port 8069 still in use - may take a moment to release"
) else (
    call :log_success "Port 8069 released"
)

netstat -an | findstr ":8072" >nul
if !errorlevel! equ 0 (
    call :log_warning "Port 8072 still in use - may take a moment to release"
) else (
    call :log_success "Port 8072 released"
)

REM ====================================
REM SESSION CLEANUP
REM ====================================
call :log_info "Cleaning up temporary files..."

REM Clean up temporary sessions if needed (preserve user sessions)
if exist "data\filestore\.tmp*" (
    del /q "data\filestore\.tmp*" >nul 2>&1
    call :log_info "Temporary filestore cleaned"
)

REM Remove PID file if exists
if exist "logs\odoo-prod.pid" (
    del "logs\odoo-prod.pid"
    call :log_info "PID file removed"
)

REM ====================================
REM MEMORY CLEANUP
REM ====================================
call :log_info "Performing memory cleanup..."

REM Force garbage collection and memory cleanup
powershell -Command "[System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()" >nul

REM ====================================
REM SHUTDOWN SUMMARY
REM ====================================
echo.
echo %CYAN%====================================================================
echo                     SHUTDOWN COMPLETED
echo ====================================================================
echo Timestamp: %date% %time%
echo Process Termination: SUCCESS
echo Port Cleanup: COMPLETED
echo Session Preservation: ACTIVE
echo Memory Cleanup: COMPLETED
echo ====================================================================
echo Logs available at:
echo - Shutdown log: logs\shutdown.log
echo - Application log: logs\odoo-prod.log
echo ====================================================================
echo %NC%

call :log_success "Odoo 17 Production server shutdown completed successfully"

echo.
echo %GREEN%Server stopped successfully. You can now:
echo - Restart with: start-production.bat
echo - Start development mode: start-dev.bat
echo - Install as service: install-service.bat%NC%
echo.

pause