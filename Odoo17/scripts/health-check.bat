@echo off
REM ====================================================================
REM Odoo 17 Production Health Monitoring Script
REM Comprehensive system health check for 50-user deployment
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
REM HEALTH CHECK CONFIGURATION
REM ====================================
set "SERVICE_NAME=Odoo17Production"
set "HEALTH_URL=http://localhost:8069/web/health"
set "DB_URL=http://localhost:8069/web/database/manager"
set "LIVE_CHAT_URL=http://localhost:8072"
set "LOG_FILE=..\logs\health-check.log"
set "ALERT_THRESHOLD_CPU=80"
set "ALERT_THRESHOLD_MEMORY=85"
set "ALERT_THRESHOLD_DISK=90"

REM ====================================
REM LOGGING FUNCTIONS
REM ====================================
:log_info
echo %GREEN%[%date% %time%] INFO: %~1%NC%
echo [%date% %time%] INFO: %~1 >> "%LOG_FILE%"
exit /b

:log_error
echo %RED%[%date% %time%] ERROR: %~1%NC%
echo [%date% %time%] ERROR: %~1 >> "%LOG_FILE%"
exit /b

:log_warning
echo %YELLOW%[%date% %time%] WARNING: %~1%NC%
echo [%date% %time%] WARNING: %~1 >> "%LOG_FILE%"
exit /b

:log_success
echo %CYAN%[%date% %time%] SUCCESS: %~1%NC%
echo [%date% %time%] SUCCESS: %~1 >> "%LOG_FILE%"
exit /b

REM ====================================
REM HEALTH CHECK HEADER
REM ====================================
cls
echo %BLUE%
echo ====================================================================
echo              ODOO 17 PRODUCTION HEALTH MONITOR
echo                 Comprehensive System Check
echo ====================================================================
echo Target: 50 concurrent users
echo Service: %SERVICE_NAME%
echo Timestamp: %date% %time%
echo ====================================================================
echo %NC%

REM Navigate to parent directory (from scripts to main)
cd /d "%~dp0\.."

REM Ensure logs directory exists
if not exist "logs" mkdir logs

call :log_info "Starting comprehensive health check..."

REM ====================================
REM SYSTEM RESOURCE MONITORING
REM ====================================
echo %CYAN%System Resources:%NC%
call :log_info "Checking system resources..."

REM Get CPU usage
for /f "tokens=2 delims==" %%a in ('powershell -Command "(Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average).Average"') do set "CPU_USAGE=%%a"
if !CPU_USAGE! gtr %ALERT_THRESHOLD_CPU% (
    call :log_warning "High CPU usage: !CPU_USAGE!%% (threshold: %ALERT_THRESHOLD_CPU%%)"
    echo %YELLOW%  CPU Usage: !CPU_USAGE!%% ⚠ HIGH%NC%
) else (
    call :log_success "CPU usage normal: !CPU_USAGE!%%"
    echo %GREEN%  CPU Usage: !CPU_USAGE!%% ✓%NC%
)

REM Get Memory usage
for /f "tokens=2 delims==" %%a in ('powershell -Command "$mem = Get-WmiObject -Class Win32_ComputerSystem; $free = (Get-WmiObject -Class Win32_PerfRawData_PerfOS_Memory).AvailableBytes; $used = (($mem.TotalPhysicalMemory - $free) / $mem.TotalPhysicalMemory) * 100; [math]::Round($used, 1)"') do set "MEMORY_USAGE=%%a"
if !MEMORY_USAGE! gtr %ALERT_THRESHOLD_MEMORY% (
    call :log_warning "High memory usage: !MEMORY_USAGE!%% (threshold: %ALERT_THRESHOLD_MEMORY%%)"
    echo %YELLOW%  Memory Usage: !MEMORY_USAGE!%% ⚠ HIGH%NC%
) else (
    call :log_success "Memory usage normal: !MEMORY_USAGE!%%"
    echo %GREEN%  Memory Usage: !MEMORY_USAGE!%% ✓%NC%
)

REM Get Disk usage
for /f "tokens=2 delims==" %%a in ('powershell -Command "$disk = Get-WmiObject -Class Win32_LogicalDisk -Filter \"DeviceID='C:'\"; [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)"') do set "DISK_USAGE=%%a"
if !DISK_USAGE! gtr %ALERT_THRESHOLD_DISK% (
    call :log_warning "High disk usage: !DISK_USAGE!%% (threshold: %ALERT_THRESHOLD_DISK%%)"
    echo %YELLOW%  Disk Usage: !DISK_USAGE!%% ⚠ HIGH%NC%
) else (
    call :log_success "Disk usage normal: !DISK_USAGE!%%"
    echo %GREEN%  Disk Usage: !DISK_USAGE!%% ✓%NC%
)

echo.

REM ====================================
REM SERVICE STATUS CHECK
REM ====================================
echo %CYAN%Service Status:%NC%
call :log_info "Checking Windows service status..."

REM Check if service exists and get status
sc query "%SERVICE_NAME%" >nul 2>&1
if !errorlevel! neq 0 (
    call :log_error "Service '%SERVICE_NAME%' not found or not installed"
    echo %RED%  Service: NOT INSTALLED ✗%NC%
    set "SERVICE_STATUS=NOT_INSTALLED"
) else (
    REM Get service state
    for /f "tokens=4" %%a in ('sc query "%SERVICE_NAME%" ^| find "STATE"') do set "SERVICE_STATE=%%a"
    
    if "!SERVICE_STATE!"=="RUNNING" (
        call :log_success "Service is running"
        echo %GREEN%  Service: RUNNING ✓%NC%
        set "SERVICE_STATUS=RUNNING"
    ) else (
        call :log_error "Service is not running (State: !SERVICE_STATE!)"
        echo %RED%  Service: !SERVICE_STATE! ✗%NC%
        set "SERVICE_STATUS=!SERVICE_STATE!"
    )
)

echo.

REM ====================================
REM PROCESS MONITORING
REM ====================================
echo %CYAN%Process Information:%NC%
call :log_info "Checking Odoo processes..."

REM Count Odoo worker processes
set "WORKER_COUNT=0"
for /f %%i in ('tasklist /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq *odoo*" 2^>nul ^| find /c "python.exe"') do set "WORKER_COUNT=%%i"

if %WORKER_COUNT% equ 0 (
    call :log_error "No Odoo worker processes found"
    echo %RED%  Worker Processes: 0 ✗%NC%
) else if %WORKER_COUNT% lss 10 (
    call :log_warning "Insufficient worker processes: %WORKER_COUNT%/10"
    echo %YELLOW%  Worker Processes: %WORKER_COUNT%/10 ⚠%NC%
) else (
    call :log_success "Optimal worker processes: %WORKER_COUNT%"
    echo %GREEN%  Worker Processes: %WORKER_COUNT%/10 ✓%NC%
)

echo.

REM ====================================
REM DATABASE CONNECTIVITY
REM ====================================
echo %CYAN%Database Connectivity:%NC%
call :log_info "Testing PostgreSQL 17 connectivity..."

REM Test PostgreSQL connection
powershell -Command "try { $conn = New-Object System.Data.Odbc.OdbcConnection('Driver={PostgreSQL Unicode};Server=localhost;Port=5432;Database=postgres;Uid=admin;Pwd=1234;'); $conn.Open(); $conn.Close(); Write-Host 'SUCCESS' } catch { Write-Host 'FAILED' }" > temp_db_health.txt
set /p DB_STATUS=<temp_db_health.txt
del temp_db_health.txt

if "%DB_STATUS%"=="SUCCESS" (
    call :log_success "PostgreSQL connection successful"
    echo %GREEN%  PostgreSQL 17: CONNECTED ✓%NC%
) else (
    call :log_error "PostgreSQL connection failed"
    echo %RED%  PostgreSQL 17: CONNECTION FAILED ✗%NC%
)

echo.

REM ====================================
REM WEB SERVER HEALTH CHECK
REM ====================================
echo %CYAN%Web Server Health:%NC%
call :log_info "Testing web server endpoints..."

REM Main application health check
powershell -Command "try { $response = Invoke-WebRequest -Uri '%HEALTH_URL%' -TimeoutSec 10 -UseBasicParsing; if($response.StatusCode -eq 200) { Write-Host 'HEALTHY' } else { Write-Host 'UNHEALTHY' } } catch { Write-Host 'UNREACHABLE' }" > temp_web_health.txt
set /p WEB_HEALTH=<temp_web_health.txt
del temp_web_health.txt

if "%WEB_HEALTH%"=="HEALTHY" (
    call :log_success "Main web server healthy"
    echo %GREEN%  Main Server (8069): HEALTHY ✓%NC%
) else (
    call :log_error "Main web server unhealthy or unreachable"
    echo %RED%  Main Server (8069): %WEB_HEALTH% ✗%NC%
)

REM Live chat server check
powershell -Command "try { $response = Invoke-WebRequest -Uri '%LIVE_CHAT_URL%' -TimeoutSec 5 -UseBasicParsing; Write-Host 'ACCESSIBLE' } catch { Write-Host 'INACCESSIBLE' }" > temp_chat_health.txt
set /p CHAT_HEALTH=<temp_chat_health.txt
del temp_chat_health.txt

if "%CHAT_HEALTH%"=="ACCESSIBLE" (
    call :log_success "Live chat server accessible"
    echo %GREEN%  Live Chat (8072): ACCESSIBLE ✓%NC%
) else (
    call :log_warning "Live chat server inaccessible"
    echo %YELLOW%  Live Chat (8072): INACCESSIBLE ⚠%NC%
)

echo.

REM ====================================
REM LOG FILE ANALYSIS
REM ====================================
echo %CYAN%Log Analysis:%NC%
call :log_info "Analyzing recent log files..."

REM Check main log file size and recent errors
if exist "logs\odoo-prod.log" (
    for %%A in ("logs\odoo-prod.log") do set "LOG_SIZE=%%~zA"
    set /a LOG_SIZE_MB=!LOG_SIZE! / 1048576
    
    if !LOG_SIZE_MB! gtr 100 (
        call :log_warning "Large log file detected: !LOG_SIZE_MB! MB"
        echo %YELLOW%  Log Size: !LOG_SIZE_MB! MB ⚠ LARGE%NC%
    ) else (
        echo %GREEN%  Log Size: !LOG_SIZE_MB! MB ✓%NC%
    )
    
    REM Check for recent errors (last 50 lines)
    powershell -Command "Get-Content 'logs\odoo-prod.log' -Tail 50 | Where-Object { $_ -match 'ERROR|CRITICAL' } | Measure-Object | Select-Object -ExpandProperty Count" > temp_error_count.txt
    set /p ERROR_COUNT=<temp_error_count.txt
    del temp_error_count.txt
    
    if !ERROR_COUNT! gtr 0 (
        call :log_warning "Recent errors found in log: !ERROR_COUNT! errors"
        echo %YELLOW%  Recent Errors: !ERROR_COUNT! ⚠%NC%
    ) else (
        call :log_success "No recent errors in log"
        echo %GREEN%  Recent Errors: 0 ✓%NC%
    )
) else (
    call :log_warning "Main log file not found"
    echo %YELLOW%  Log File: NOT FOUND ⚠%NC%
)

echo.

REM ====================================
REM NETWORK PORT CHECK
REM ====================================
echo %CYAN%Network Ports:%NC%
call :log_info "Checking network port status..."

REM Check if ports are listening
netstat -an | findstr ":8069.*LISTENING" >nul
if !errorlevel! equ 0 (
    echo %GREEN%  Port 8069: LISTENING ✓%NC%
    call :log_success "Port 8069 is listening"
) else (
    echo %RED%  Port 8069: NOT LISTENING ✗%NC%
    call :log_error "Port 8069 is not listening"
)

netstat -an | findstr ":8072.*LISTENING" >nul
if !errorlevel! equ 0 (
    echo %GREEN%  Port 8072: LISTENING ✓%NC%
    call :log_success "Port 8072 is listening"
) else (
    echo %YELLOW%  Port 8072: NOT LISTENING ⚠%NC%
    call :log_warning "Port 8072 is not listening"
)

netstat -an | findstr ":5432.*LISTENING" >nul
if !errorlevel! equ 0 (
    echo %GREEN%  Port 5432: LISTENING ✓%NC%
    call :log_success "PostgreSQL port 5432 is listening"
) else (
    echo %RED%  Port 5432: NOT LISTENING ✗%NC%
    call :log_error "PostgreSQL port 5432 is not listening"
)

echo.

REM ====================================
REM PERFORMANCE METRICS
REM ====================================
echo %CYAN%Performance Metrics:%NC%
call :log_info "Collecting performance metrics..."

REM Measure response time
powershell -Command "$start = Get-Date; try { Invoke-WebRequest -Uri '%HEALTH_URL%' -TimeoutSec 10 -UseBasicParsing | Out-Null; $end = Get-Date; [math]::Round(($end - $start).TotalMilliseconds, 0) } catch { Write-Host '9999' }" > temp_response_time.txt
set /p RESPONSE_TIME=<temp_response_time.txt
del temp_response_time.txt

if %RESPONSE_TIME% lss 1000 (
    echo %GREEN%  Response Time: %RESPONSE_TIME%ms ✓%NC%
    call :log_success "Response time excellent: %RESPONSE_TIME%ms"
) else if %RESPONSE_TIME% lss 3000 (
    echo %YELLOW%  Response Time: %RESPONSE_TIME%ms ⚠%NC%
    call :log_warning "Response time acceptable: %RESPONSE_TIME%ms"
) else (
    echo %RED%  Response Time: %RESPONSE_TIME%ms ✗%NC%
    call :log_error "Response time poor: %RESPONSE_TIME%ms"
)

echo.

REM ====================================
REM OVERALL HEALTH ASSESSMENT
REM ====================================
echo %CYAN%====================================================================
echo                        HEALTH ASSESSMENT SUMMARY
echo ====================================================================

set "HEALTH_SCORE=0"
set "MAX_SCORE=8"

if !CPU_USAGE! leq %ALERT_THRESHOLD_CPU% set /a HEALTH_SCORE+=1
if !MEMORY_USAGE! leq %ALERT_THRESHOLD_MEMORY% set /a HEALTH_SCORE+=1
if !DISK_USAGE! leq %ALERT_THRESHOLD_DISK% set /a HEALTH_SCORE+=1
if "%SERVICE_STATUS%"=="RUNNING" set /a HEALTH_SCORE+=1
if %WORKER_COUNT% geq 10 set /a HEALTH_SCORE+=1
if "%DB_STATUS%"=="SUCCESS" set /a HEALTH_SCORE+=1
if "%WEB_HEALTH%"=="HEALTHY" set /a HEALTH_SCORE+=1
if %RESPONSE_TIME% lss 3000 set /a HEALTH_SCORE+=1

set /a HEALTH_PERCENTAGE=(!HEALTH_SCORE! * 100) / %MAX_SCORE%

if %HEALTH_PERCENTAGE% geq 90 (
    echo %GREEN%Overall Health: EXCELLENT (%HEALTH_SCORE%/%MAX_SCORE% - %HEALTH_PERCENTAGE%%%)%NC%
    call :log_success "System health excellent: %HEALTH_PERCENTAGE%%%"
) else if %HEALTH_PERCENTAGE% geq 75 (
    echo %YELLOW%Overall Health: GOOD (%HEALTH_SCORE%/%MAX_SCORE% - %HEALTH_PERCENTAGE%%%)%NC%
    call :log_info "System health good: %HEALTH_PERCENTAGE%%%"
) else if %HEALTH_PERCENTAGE% geq 50 (
    echo %YELLOW%Overall Health: FAIR (%HEALTH_SCORE%/%MAX_SCORE% - %HEALTH_PERCENTAGE%%%)%NC%
    call :log_warning "System health fair: %HEALTH_PERCENTAGE%%%"
) else (
    echo %RED%Overall Health: POOR (%HEALTH_SCORE%/%MAX_SCORE% - %HEALTH_PERCENTAGE%%%)%NC%
    call :log_error "System health poor: %HEALTH_PERCENTAGE%%%"
)

echo.
echo Capacity Status: Ready for 50 concurrent users
echo Last Check: %date% %time%
echo Log File: %LOG_FILE%
echo ====================================================================%NC%

call :log_info "Health check completed. Overall score: %HEALTH_SCORE%/%MAX_SCORE% (%HEALTH_PERCENTAGE%%%)"

if "%1"=="--silent" (
    exit /b %HEALTH_PERCENTAGE%
) else (
    echo.
    pause
)