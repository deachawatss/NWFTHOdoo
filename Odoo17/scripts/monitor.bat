@echo off
REM ====================================================================
REM Odoo 17 Production Performance Monitor
REM Real-time performance monitoring for 50-user deployment
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
REM MONITORING CONFIGURATION
REM ====================================
set "MONITOR_INTERVAL=30"
set "SAMPLE_COUNT=120"
set "LOG_FILE=..\logs\performance.log"
set "ALERT_CPU_THRESHOLD=80"
set "ALERT_MEMORY_THRESHOLD=85"
set "ALERT_RESPONSE_THRESHOLD=3000"
set "HEALTH_URL=http://localhost:8069/web/health"

REM ====================================
REM MONITORING HEADER
REM ====================================
cls
echo %BLUE%
echo ====================================================================
echo              ODOO 17 PRODUCTION PERFORMANCE MONITOR
echo                Real-time System Monitoring
echo ====================================================================
echo Monitor Interval: %MONITOR_INTERVAL% seconds
echo Sample Count: %SAMPLE_COUNT% samples
echo Target Users: 50 concurrent
echo Health URL: %HEALTH_URL%
echo ====================================================================
echo %NC%

REM Navigate to parent directory (from scripts to main)
cd /d "%~dp0\.."

REM Ensure logs directory exists
if not exist "logs" mkdir logs

echo Starting performance monitoring...
echo Press Ctrl+C to stop monitoring
echo.

REM ====================================
REM MONITORING LOOP
REM ====================================
set "SAMPLE_NUM=0"
set "ALERT_COUNT=0"

:monitor_loop
set /a SAMPLE_NUM+=1

REM Clear previous data
cls
echo %CYAN%====================================================================
echo                    PERFORMANCE MONITOR - SAMPLE %SAMPLE_NUM%
echo ====================================================================
echo Timestamp: %date% %time%
echo Target: 50 concurrent users
echo Monitoring interval: %MONITOR_INTERVAL%s
echo ====================================================================
echo %NC%

REM ====================================
REM SYSTEM METRICS COLLECTION
REM ====================================
echo %YELLOW%System Resources:%NC%

REM CPU Usage
for /f "tokens=2 delims==" %%a in ('powershell -Command "(Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average).Average"') do set "CPU_USAGE=%%a"
if !CPU_USAGE! gtr %ALERT_CPU_THRESHOLD% (
    echo %RED%  CPU Usage: !CPU_USAGE!%% ⚠ HIGH%NC%
    set /a ALERT_COUNT+=1
    echo [%date% %time%] ALERT: High CPU usage: !CPU_USAGE!%% >> "%LOG_FILE%"
) else (
    echo %GREEN%  CPU Usage: !CPU_USAGE!%% ✓%NC%
)

REM Memory Usage
for /f "tokens=2 delims==" %%a in ('powershell -Command "$mem = Get-WmiObject -Class Win32_ComputerSystem; $free = (Get-WmiObject -Class Win32_PerfRawData_PerfOS_Memory).AvailableBytes; $used = (($mem.TotalPhysicalMemory - $free) / $mem.TotalPhysicalMemory) * 100; [math]::Round($used, 1)"') do set "MEMORY_USAGE=%%a"
if !MEMORY_USAGE! gtr %ALERT_MEMORY_THRESHOLD% (
    echo %RED%  Memory Usage: !MEMORY_USAGE!%% ⚠ HIGH%NC%
    set /a ALERT_COUNT+=1
    echo [%date% %time%] ALERT: High memory usage: !MEMORY_USAGE!%% >> "%LOG_FILE%"
) else (
    echo %GREEN%  Memory Usage: !MEMORY_USAGE!%% ✓%NC%
)

REM Disk Usage
for /f "tokens=2 delims==" %%a in ('powershell -Command "$disk = Get-WmiObject -Class Win32_LogicalDisk -Filter \"DeviceID='C:'\"; [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)"') do set "DISK_USAGE=%%a"
echo %CYAN%  Disk Usage: !DISK_USAGE!%%%NC%

echo.

REM ====================================
REM PROCESS MONITORING
REM ====================================
echo %YELLOW%Process Information:%NC%

REM Count Odoo worker processes
set "WORKER_COUNT=0"
for /f %%i in ('tasklist /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq *odoo*" 2^>nul ^| find /c "python.exe"') do set "WORKER_COUNT=%%i"

if %WORKER_COUNT% lss 10 (
    echo %RED%  Worker Processes: %WORKER_COUNT%/10 ⚠ LOW%NC%
    set /a ALERT_COUNT+=1
    echo [%date% %time%] ALERT: Low worker count: %WORKER_COUNT%/10 >> "%LOG_FILE%"
) else (
    echo %GREEN%  Worker Processes: %WORKER_COUNT%/10 ✓%NC%
)

REM Memory usage per worker
if %WORKER_COUNT% gtr 0 (
    powershell -Command "Get-Process python -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowTitle -like '*odoo*'} | ForEach-Object { [math]::Round($_.WorkingSet64/1MB, 0) } | Measure-Object -Average | Select-Object -ExpandProperty Average" > temp_worker_memory.txt
    set /p WORKER_MEMORY=<temp_worker_memory.txt
    del temp_worker_memory.txt
    
    if !WORKER_MEMORY! gtr 3000 (
        echo %YELLOW%  Avg Worker Memory: !WORKER_MEMORY! MB ⚠%NC%
    ) else (
        echo %GREEN%  Avg Worker Memory: !WORKER_MEMORY! MB ✓%NC%
    )
)

echo.

REM ====================================
REM NETWORK PERFORMANCE
REM ====================================
echo %YELLOW%Network Performance:%NC%

REM Response Time Test
powershell -Command "$start = Get-Date; try { Invoke-WebRequest -Uri '%HEALTH_URL%' -TimeoutSec 10 -UseBasicParsing | Out-Null; $end = Get-Date; [math]::Round(($end - $start).TotalMilliseconds, 0) } catch { Write-Host '9999' }" > temp_response_time.txt
set /p RESPONSE_TIME=<temp_response_time.txt
del temp_response_time.txt

if %RESPONSE_TIME% gtr %ALERT_RESPONSE_THRESHOLD% (
    echo %RED%  Response Time: %RESPONSE_TIME%ms ⚠ SLOW%NC%
    set /a ALERT_COUNT+=1
    echo [%date% %time%] ALERT: Slow response time: %RESPONSE_TIME%ms >> "%LOG_FILE%"
) else if %RESPONSE_TIME% gtr 1000 (
    echo %YELLOW%  Response Time: %RESPONSE_TIME%ms ⚠%NC%
) else (
    echo %GREEN%  Response Time: %RESPONSE_TIME%ms ✓%NC%
)

REM Active Network Connections
for /f %%i in ('netstat -an ^| findstr ":8069.*ESTABLISHED" ^| find /c "ESTABLISHED"') do set "ACTIVE_CONNECTIONS=%%i"
echo %CYAN%  Active Connections: !ACTIVE_CONNECTIONS!%NC%

echo.

REM ====================================
REM DATABASE PERFORMANCE
REM ====================================
echo %YELLOW%Database Performance:%NC%

REM Test database response time
powershell -Command "$start = Get-Date; try { $conn = New-Object System.Data.Odbc.OdbcConnection('Driver={PostgreSQL Unicode};Server=localhost;Port=5432;Database=postgres;Uid=admin;Pwd=1234;'); $conn.Open(); $conn.Close(); $end = Get-Date; [math]::Round(($end - $start).TotalMilliseconds, 0) } catch { Write-Host '9999' }" > temp_db_response.txt
set /p DB_RESPONSE_TIME=<temp_db_response.txt
del temp_db_response.txt

if %DB_RESPONSE_TIME% gtr 1000 (
    echo %RED%  DB Response Time: %DB_RESPONSE_TIME%ms ⚠ SLOW%NC%
    set /a ALERT_COUNT+=1
    echo [%date% %time%] ALERT: Slow database response: %DB_RESPONSE_TIME%ms >> "%LOG_FILE%"
) else (
    echo %GREEN%  DB Response Time: %DB_RESPONSE_TIME%ms ✓%NC%
)

REM PostgreSQL connection count
for /f %%i in ('netstat -an ^| findstr ":5432.*ESTABLISHED" ^| find /c "ESTABLISHED"') do set "DB_CONNECTIONS=%%i"
echo %CYAN%  DB Connections: !DB_CONNECTIONS!%NC%

echo.

REM ====================================
REM LOG ANALYSIS
REM ====================================
echo %YELLOW%Recent Activity:%NC%

REM Check for recent errors in log
if exist "logs\odoo-prod.log" (
    powershell -Command "Get-Content 'logs\odoo-prod.log' -Tail 20 | Where-Object { $_ -match 'ERROR|CRITICAL' } | Measure-Object | Select-Object -ExpandProperty Count" > temp_recent_errors.txt
    set /p RECENT_ERRORS=<temp_recent_errors.txt
    del temp_recent_errors.txt
    
    if !RECENT_ERRORS! gtr 0 (
        echo %RED%  Recent Errors: !RECENT_ERRORS! ⚠%NC%
        set /a ALERT_COUNT+=1
    ) else (
        echo %GREEN%  Recent Errors: 0 ✓%NC%
    )
) else (
    echo %YELLOW%  Log File: NOT FOUND ⚠%NC%
)

echo.

REM ====================================
REM PERFORMANCE TRENDING
REM ====================================
echo %YELLOW%Performance Trends:%NC%

REM Log current metrics for trending
echo %date%,%time%,%CPU_USAGE%,%MEMORY_USAGE%,%DISK_USAGE%,%WORKER_COUNT%,%RESPONSE_TIME%,%DB_RESPONSE_TIME%,%ACTIVE_CONNECTIONS%,%DB_CONNECTIONS% >> logs\performance-metrics.csv

REM Calculate 5-minute average response time (if enough samples exist)
if exist "logs\performance-metrics.csv" (
    powershell -Command "
    $metrics = Import-Csv 'logs\performance-metrics.csv' -Header @('Date','Time','CPU','Memory','Disk','Workers','ResponseTime','DBResponseTime','Connections','DBConnections')
    $recent = $metrics | Select-Object -Last 10
    if ($recent.Count -gt 1) {
        $avgResponse = ($recent.ResponseTime | Where-Object { $_ -ne '9999' } | Measure-Object -Average).Average
        if ($avgResponse) { [math]::Round($avgResponse, 0) } else { 'N/A' }
    } else { 'N/A' }
    " > temp_avg_response.txt
    
    set /p AVG_RESPONSE=<temp_avg_response.txt
    del temp_avg_response.txt
    
    echo %CYAN%  5-min Avg Response: !AVG_RESPONSE!ms%NC%
)

echo.

REM ====================================
REM ALERT SUMMARY
REM ====================================
if %ALERT_COUNT% gtr 0 (
    echo %RED%🚨 ALERTS THIS CYCLE: %ALERT_COUNT%
    echo Check logs for details: %LOG_FILE%%NC%
) else (
    echo %GREEN%✓ NO ALERTS - SYSTEM OPERATING NORMALLY%NC%
)

echo.
echo %CYAN%====================================================================
echo Next update in %MONITOR_INTERVAL% seconds... (Sample %SAMPLE_NUM%/%SAMPLE_COUNT%)
echo Press Ctrl+C to stop monitoring
echo ====================================================================%NC%

REM Log summary metrics
echo [%date% %time%] MONITOR: CPU=%CPU_USAGE%%% MEM=%MEMORY_USAGE%%% Workers=%WORKER_COUNT% Response=%RESPONSE_TIME%ms Alerts=%ALERT_COUNT% >> "%LOG_FILE%"

REM Check if we've reached the sample limit
if %SAMPLE_NUM% geq %SAMPLE_COUNT% (
    echo.
    echo %YELLOW%Monitoring completed - reached %SAMPLE_COUNT% samples limit%NC%
    goto :monitoring_summary
)

REM Wait for next monitoring cycle
timeout /t %MONITOR_INTERVAL% >nul

REM Reset alert count for next cycle
set "ALERT_COUNT=0"

goto :monitor_loop

REM ====================================
REM MONITORING SUMMARY
REM ====================================
:monitoring_summary
echo.
echo %CYAN%====================================================================
echo                        MONITORING SUMMARY
echo ====================================================================
echo Total Samples: %SAMPLE_NUM%
echo Monitoring Duration: %SAMPLE_NUM% x %MONITOR_INTERVAL%s
echo Performance Log: %LOG_FILE%
echo Metrics CSV: logs\performance-metrics.csv
echo ====================================================================
echo %NC%

echo %GREEN%Monitoring session completed successfully.%NC%
echo Review performance logs for detailed analysis.
echo.

pause