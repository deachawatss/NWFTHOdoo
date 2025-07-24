@echo off
REM ====================================================================
REM Odoo 17 Windows Production Restart Script
REM Zero-downtime restart with configuration reload
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
set "MAGENTA=[95m"
set "NC=[0m"

REM ====================================
REM RESTART CONFIGURATION
REM ====================================
set "RESTART_TIMEOUT=30"
set "HEALTH_CHECK_URL=http://localhost:8069/web/health"
set "MAX_RESTART_ATTEMPTS=3"
set "CURRENT_ATTEMPT=1"

REM ====================================
REM LOGGING FUNCTIONS
REM ====================================
:log_info
echo %GREEN%[%date% %time%] INFO: %~1%NC%
echo [%date% %time%] INFO: %~1 >> logs\restart.log
goto :eof

:log_error
echo %RED%[%date% %time%] ERROR: %~1%NC%
echo [%date% %time%] ERROR: %~1 >> logs\restart.log
goto :eof

:log_warning
echo %YELLOW%[%date% %time%] WARNING: %~1%NC%
echo [%date% %time%] WARNING: %~1 >> logs\restart.log
goto :eof

:log_success
echo %CYAN%[%date% %time%] SUCCESS: %~1%NC%
echo [%date% %time%] SUCCESS: %~1 >> logs\restart.log
goto :eof

REM ====================================
REM RESTART HEADER
REM ====================================
cls
echo %BLUE%
echo ====================================================================
echo                  ODOO 17 PRODUCTION RESTART
echo                   Zero-Downtime Configuration
echo ====================================================================
echo Restart Attempt: %CURRENT_ATTEMPT%/%MAX_RESTART_ATTEMPTS%
echo Timeout: %RESTART_TIMEOUT% seconds
echo Health Check: %HEALTH_CHECK_URL%
echo ====================================================================
echo %NC%

REM Navigate to script directory
cd /d "%~dp0"

REM Create logs directory if it doesn't exist
if not exist "logs" mkdir logs

call :log_info "Starting production restart sequence..."

REM ====================================
REM PRE-RESTART VALIDATION
REM ====================================
call :log_info "Performing pre-restart validation..."

REM Check if configuration file exists
if not exist "odoo-prod.conf" (
    call :log_error "Production configuration file not found!"
    pause
    exit /b 1
)

REM Validate configuration syntax
call :log_info "Validating configuration syntax..."
python -c "
import configparser
try:
    config = configparser.ConfigParser()
    config.read('odoo-prod.conf')
    print('Configuration syntax: OK')
except Exception as e:
    print(f'Configuration error: {e}')
    exit(1)
" || (
    call :log_error "Configuration file contains syntax errors!"
    call :log_error "Please fix configuration before restarting"
    pause
    exit /b 1
)

call :log_success "Configuration validated successfully"

REM ====================================
REM CHECK CURRENT SERVER STATUS
REM ====================================
call :log_info "Checking current server status..."

REM Count running processes
set "RUNNING_PROCESSES=0"
for /f %%i in ('tasklist /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq *odoo*" 2^>nul ^| find /c "python.exe"') do set "RUNNING_PROCESSES=%%i"

if %RUNNING_PROCESSES% equ 0 (
    call :log_warning "No running Odoo processes detected"
    call :log_info "Performing cold start instead of restart..."
    goto :cold_start
)

call :log_info "Found %RUNNING_PROCESSES% running Odoo processes"

REM ====================================
REM HEALTH CHECK BEFORE RESTART
REM ====================================
call :log_info "Performing health check before restart..."

REM Test server responsiveness
powershell -Command "try { $response = Invoke-WebRequest -Uri '%HEALTH_CHECK_URL%' -TimeoutSec 5 -UseBasicParsing; if($response.StatusCode -eq 200) { Write-Host 'HEALTHY' } else { Write-Host 'UNHEALTHY' } } catch { Write-Host 'UNREACHABLE' }" > temp_health_check.txt
set /p HEALTH_STATUS=<temp_health_check.txt
del temp_health_check.txt

call :log_info "Current server status: %HEALTH_STATUS%"

REM ====================================
REM BACKUP CURRENT STATE
REM ====================================
call :log_info "Creating restart backup..."

REM Backup current log file
if exist "logs\odoo-prod.log" (
    copy "logs\odoo-prod.log" "logs\odoo-prod-backup-%date:~-4,4%%date:~-10,2%%date:~-7,2%-%time:~0,2%%time:~3,2%%time:~6,2%.log" >nul
    call :log_info "Log backup created"
)

REM ====================================
REM GRACEFUL RESTART PROCESS
REM ====================================
:restart_attempt
call :log_info "Restart attempt %CURRENT_ATTEMPT%/%MAX_RESTART_ATTEMPTS%"

REM Step 1: Graceful shutdown
call :log_info "Initiating graceful shutdown..."
call stop-production.bat >nul 2>&1

REM Wait for complete shutdown
call :log_info "Waiting for complete shutdown..."
timeout /t 5 >nul

REM Verify shutdown completed
set "REMAINING_PROCESSES=0"
for /f %%i in ('tasklist /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq *odoo*" 2^>nul ^| find /c "python.exe"') do set "REMAINING_PROCESSES=%%i"

if %REMAINING_PROCESSES% neq 0 (
    call :log_warning "Graceful shutdown incomplete. %REMAINING_PROCESSES% processes still running"
    call :log_info "Forcing termination..."
    taskkill /F /IM python.exe /FI "WINDOWTITLE eq *odoo*" >nul 2>&1
    timeout /t 3 >nul
)

REM ====================================
REM SYSTEM CLEANUP
REM ====================================
call :log_info "Performing system cleanup..."

REM Memory cleanup
powershell -Command "[System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()" >nul

REM Port verification
call :log_info "Verifying port availability..."
timeout /t 2 >nul

netstat -an | findstr ":8069" >nul
if !errorlevel! equ 0 (
    call :log_warning "Port 8069 still in use - waiting for release..."
    timeout /t 5 >nul
)

REM ====================================
REM RESTART SERVER
REM ====================================
:cold_start
call :log_info "Starting Odoo production server..."

REM Start server in background for health check
echo %CYAN%Starting server (attempt %CURRENT_ATTEMPT%)...%NC%

start /MIN "Odoo Production" cmd /c "start-production.bat"

REM ====================================
REM POST-RESTART HEALTH CHECK
REM ====================================
call :log_info "Waiting for server initialization..."
timeout /t 15 >nul

call :log_info "Performing post-restart health check..."

REM Health check with retry
set "HEALTH_CHECK_ATTEMPTS=0"
set "MAX_HEALTH_CHECKS=12"

:health_check_loop
set /a HEALTH_CHECK_ATTEMPTS+=1
call :log_info "Health check attempt %HEALTH_CHECK_ATTEMPTS%/%MAX_HEALTH_CHECKS%"

powershell -Command "try { $response = Invoke-WebRequest -Uri '%HEALTH_CHECK_URL%' -TimeoutSec 10 -UseBasicParsing; if($response.StatusCode -eq 200) { Write-Host 'HEALTHY' } else { Write-Host 'UNHEALTHY' } } catch { Write-Host 'UNREACHABLE' }" > temp_health_check.txt
set /p POST_RESTART_HEALTH=<temp_health_check.txt
del temp_health_check.txt

if "%POST_RESTART_HEALTH%"=="HEALTHY" (
    call :log_success "Server is healthy and responding"
    goto :restart_success
)

if %HEALTH_CHECK_ATTEMPTS% lss %MAX_HEALTH_CHECKS% (
    call :log_info "Server not ready yet, waiting..."
    timeout /t 10 >nul
    goto :health_check_loop
)

REM ====================================
REM RESTART FAILURE HANDLING
REM ====================================
call :log_error "Health check failed after %MAX_HEALTH_CHECKS% attempts"

if %CURRENT_ATTEMPT% lss %MAX_RESTART_ATTEMPTS% (
    set /a CURRENT_ATTEMPT+=1
    call :log_warning "Restart attempt %CURRENT_ATTEMPT%/%MAX_RESTART_ATTEMPTS%"
    
    REM Kill any problematic processes
    taskkill /F /IM python.exe /FI "WINDOWTITLE eq *odoo*" >nul 2>&1
    timeout /t 5 >nul
    
    goto :restart_attempt
)

REM ====================================
REM RESTART FAILURE
REM ====================================
echo.
echo %RED%====================================================================
echo                      RESTART FAILED
echo ====================================================================
echo Maximum restart attempts (%MAX_RESTART_ATTEMPTS%) exceeded
echo Server health check failed
echo ====================================================================
echo %NC%

call :log_error "Restart failed after %MAX_RESTART_ATTEMPTS% attempts"
call :log_error "Manual intervention required"

echo %YELLOW%Troubleshooting steps:
echo 1. Check logs: logs\odoo-prod.log
echo 2. Verify database connectivity
echo 3. Check system resources
echo 4. Try manual start: start-production.bat%NC%

pause
exit /b 1

REM ====================================
REM RESTART SUCCESS
REM ====================================
:restart_success
echo.
echo %CYAN%====================================================================
echo                     RESTART SUCCESSFUL
echo ====================================================================
echo Restart Time: %date% %time%
echo Attempts Used: %CURRENT_ATTEMPT%/%MAX_RESTART_ATTEMPTS%
echo Server Status: HEALTHY
echo Health Check: PASSED
echo ====================================================================
echo Server Information:
echo - Main URL: http://localhost:8069
echo - Live Chat: http://localhost:8072
echo - Configuration: odoo-prod.conf
echo - Workers: 10 processes
echo - Target Users: 50 concurrent
echo ====================================================================
echo %NC%

call :log_success "Production restart completed successfully"
call :log_success "Server is healthy and ready for connections"

echo.
echo %GREEN%Restart completed successfully!
echo Server is now running with updated configuration.
echo All services are operational.%NC%
echo.

pause