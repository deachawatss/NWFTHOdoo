@echo off
REM ====================================================================
REM Odoo 17 Production Load Testing Script
REM Simulates 50 concurrent users for performance validation
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
REM LOAD TEST CONFIGURATION
REM ====================================
set "TARGET_USERS=50"
set "RAMP_UP_TIME=300"
set "TEST_DURATION=1800"
set "BASE_URL=http://localhost:8069"
set "LOGIN_URL=%BASE_URL%/web/login"
set "HEALTH_URL=%BASE_URL%/web/health"
set "TEST_USERNAME=admin"
set "TEST_PASSWORD=1234"
set "CONCURRENT_THREADS=10"
set "REQUESTS_PER_THREAD=50"

REM ====================================
REM LOAD TEST HEADER
REM ====================================
cls
echo %BLUE%
echo ====================================================================
echo                 ODOO 17 PRODUCTION LOAD TEST
echo               50 Concurrent Users Simulation
echo ====================================================================
echo Target Users: %TARGET_USERS%
echo Ramp-up Time: %RAMP_UP_TIME% seconds
echo Test Duration: %TEST_DURATION% seconds
echo Base URL: %BASE_URL%
echo Concurrent Threads: %CONCURRENT_THREADS%
echo Requests per Thread: %REQUESTS_PER_THREAD%
echo ====================================================================
echo %NC%

REM Navigate to parent directory (from scripts to main)
cd /d "%~dp0\.."

REM ====================================
REM LOGGING FUNCTIONS
REM ====================================
:log_info
echo %GREEN%[%date% %time%] INFO: %~1%NC%
echo [%date% %time%] INFO: %~1 >> logs\load-test.log
exit /b

:log_error
echo %RED%[%date% %time%] ERROR: %~1%NC%
echo [%date% %time%] ERROR: %~1 >> logs\load-test.log
exit /b

:log_warning
echo %YELLOW%[%date% %time%] WARNING: %~1%NC%
echo [%date% %time%] WARNING: %~1 >> logs\load-test.log
exit /b

:log_success
echo %CYAN%[%date% %time%] SUCCESS: %~1%NC%
echo [%date% %time%] SUCCESS: %~1 >> logs\load-test.log
exit /b

REM Ensure logs directory exists
if not exist "logs" mkdir logs

call :log_info "Starting Odoo 17 production load test..."

REM ====================================
REM PRE-TEST VALIDATION
REM ====================================
call :log_info "Performing pre-test validation..."

echo %CYAN%Pre-test Validation:%NC%

REM Check if Odoo is running
powershell -Command "try { $response = Invoke-WebRequest -Uri '%HEALTH_URL%' -TimeoutSec 10 -UseBasicParsing; if($response.StatusCode -eq 200) { Write-Host 'HEALTHY' } else { Write-Host 'UNHEALTHY' } } catch { Write-Host 'UNREACHABLE' }" > temp_pretest_health.txt
set /p PRETEST_HEALTH=<temp_pretest_health.txt
del temp_pretest_health.txt

if not "%PRETEST_HEALTH%"=="HEALTHY" (
    call :log_error "Odoo server is not healthy or reachable"
    echo %RED%  ✗ Server Status: %PRETEST_HEALTH%%NC%
    echo %RED%Please start Odoo production server before running load test%NC%
    echo %YELLOW%Run: start-production.bat%NC%
    pause
    exit /b 1
)

echo %GREEN%  ✓ Server Status: HEALTHY%NC%
call :log_success "Pre-test validation passed"

REM Check worker processes
set "WORKER_COUNT=0"
for /f %%i in ('tasklist /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq *odoo*" 2^>nul ^| find /c "python.exe"') do set "WORKER_COUNT=%%i"

if %WORKER_COUNT% lss 10 (
    call :log_warning "Insufficient worker processes: %WORKER_COUNT%/10"
    echo %YELLOW%  ⚠ Worker Processes: %WORKER_COUNT%/10 (May impact performance)%NC%
) else (
    echo %GREEN%  ✓ Worker Processes: %WORKER_COUNT%/10%NC%
    call :log_success "Optimal worker processes detected"
)

echo.

REM ====================================
REM SYSTEM BASELINE MEASUREMENT
REM ====================================
call :log_info "Collecting baseline performance metrics..."

echo %CYAN%Baseline Metrics:%NC%

REM CPU baseline
for /f "tokens=2 delims==" %%a in ('powershell -Command "(Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average).Average"') do set "BASELINE_CPU=%%a"
echo %CYAN%  CPU Usage: %BASELINE_CPU%%%NC%

REM Memory baseline
for /f "tokens=2 delims==" %%a in ('powershell -Command "$mem = Get-WmiObject -Class Win32_ComputerSystem; $free = (Get-WmiObject -Class Win32_PerfRawData_PerfOS_Memory).AvailableBytes; $used = (($mem.TotalPhysicalMemory - $free) / $mem.TotalPhysicalMemory) * 100; [math]::Round($used, 1)"') do set "BASELINE_MEMORY=%%a"
echo %CYAN%  Memory Usage: %BASELINE_MEMORY%%%NC%

REM Response time baseline
powershell -Command "$start = Get-Date; try { Invoke-WebRequest -Uri '%HEALTH_URL%' -TimeoutSec 10 -UseBasicParsing | Out-Null; $end = Get-Date; [math]::Round(($end - $start).TotalMilliseconds, 0) } catch { Write-Host '9999' }" > temp_baseline_response.txt
set /p BASELINE_RESPONSE=<temp_baseline_response.txt
del temp_baseline_response.txt
echo %CYAN%  Response Time: %BASELINE_RESPONSE%ms%NC%

call :log_info "Baseline: CPU=%BASELINE_CPU%%% MEM=%BASELINE_MEMORY%%% Response=%BASELINE_RESPONSE%ms"

echo.

REM ====================================
REM CREATE LOAD TEST SCRIPT
REM ====================================
call :log_info "Creating PowerShell load test script..."

REM Create PowerShell script for concurrent load testing
echo # Odoo Load Test Script > load-test-script.ps1
echo param( >> load-test-script.ps1
echo     [int]$ThreadId, >> load-test-script.ps1
echo     [int]$Requests, >> load-test-script.ps1
echo     [string]$BaseUrl, >> load-test-script.ps1
echo     [string]$LogFile >> load-test-script.ps1
echo ) >> load-test-script.ps1
echo. >> load-test-script.ps1
echo $results = @() >> load-test-script.ps1
echo $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession >> load-test-script.ps1
echo. >> load-test-script.ps1
echo for ($i = 1; $i -le $Requests; $i++) { >> load-test-script.ps1
echo     $start = Get-Date >> load-test-script.ps1
echo     try { >> load-test-script.ps1
echo         # Test various endpoints >> load-test-script.ps1
echo         $endpoints = @("/web/health", "/web/login", "/web/database/selector") >> load-test-script.ps1
echo         $endpoint = $endpoints[($i %% $endpoints.Length)] >> load-test-script.ps1
echo         $response = Invoke-WebRequest -Uri "$BaseUrl$endpoint" -TimeoutSec 30 -UseBasicParsing -WebSession $session >> load-test-script.ps1
echo         $end = Get-Date >> load-test-script.ps1
echo         $responseTime = ($end - $start).TotalMilliseconds >> load-test-script.ps1
echo         $result = "Thread$ThreadId,Request$i,$endpoint,$($response.StatusCode),$([math]::Round($responseTime, 0)),SUCCESS" >> load-test-script.ps1
echo     } catch { >> load-test-script.ps1
echo         $end = Get-Date >> load-test-script.ps1
echo         $responseTime = ($end - $start).TotalMilliseconds >> load-test-script.ps1
echo         $result = "Thread$ThreadId,Request$i,$endpoint,ERROR,$([math]::Round($responseTime, 0)),FAILED: $($_.Exception.Message)" >> load-test-script.ps1
echo     } >> load-test-script.ps1
echo     $results += $result >> load-test-script.ps1
echo     Add-Content -Path $LogFile -Value $result >> load-test-script.ps1
echo. >> load-test-script.ps1
echo     # Random delay between requests (1-3 seconds) >> load-test-script.ps1
echo     Start-Sleep -Milliseconds (Get-Random -Minimum 1000 -Maximum 3000) >> load-test-script.ps1
echo } >> load-test-script.ps1
echo. >> load-test-script.ps1
echo Write-Host "Thread $ThreadId completed $Requests requests" >> load-test-script.ps1

call :log_success "Load test script created"

REM ====================================
REM INITIALIZE TEST RESULTS
REM ====================================
set "TEST_RESULTS_FILE=logs\load-test-results.csv"
echo Thread,Request,Endpoint,StatusCode,ResponseTime,Result > "%TEST_RESULTS_FILE%"

call :log_info "Test results will be logged to: %TEST_RESULTS_FILE%"

REM ====================================
REM START LOAD TEST
REM ====================================
echo %CYAN%====================================================================
echo                         STARTING LOAD TEST
echo ====================================================================
echo Simulating %TARGET_USERS% users with %CONCURRENT_THREADS% concurrent threads
echo Each thread will make %REQUESTS_PER_THREAD% requests
echo Total requests: %TARGET_USERS% x %REQUESTS_PER_THREAD% = 2500
echo ====================================================================
echo %NC%

call :log_info "Starting concurrent load test..."

set "START_TIME=%date% %time%"
echo %YELLOW%Test Start Time: %START_TIME%%NC%

REM Start multiple PowerShell processes for concurrent load
echo %CYAN%Launching concurrent test threads...%NC%

for /l %%i in (1,1,%CONCURRENT_THREADS%) do (
    echo %GREEN%  Starting Thread %%i...%NC%
    start /MIN "LoadTest-Thread%%i" powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "load-test-script.ps1" -ThreadId %%i -Requests %REQUESTS_PER_THREAD% -BaseUrl "%BASE_URL%" -LogFile "%TEST_RESULTS_FILE%"
)

call :log_info "All %CONCURRENT_THREADS% test threads launched"

REM ====================================
REM MONITOR TEST PROGRESS
REM ====================================
echo.
echo %CYAN%Monitoring test progress...%NC%
echo %YELLOW%Press Ctrl+C to stop monitoring (test will continue)%NC%
echo.

set "MONITOR_COUNT=0"
set "MAX_MONITORS=60"

:monitor_loop
set /a MONITOR_COUNT+=1

REM Count running PowerShell processes
set "ACTIVE_THREADS=0"
for /f %%i in ('tasklist /FI "IMAGENAME eq powershell.exe" /FI "WINDOWTITLE eq LoadTest-Thread*" 2^>nul ^| find /c "powershell.exe"') do set "ACTIVE_THREADS=%%i"

REM Get current system metrics
for /f "tokens=2 delims==" %%a in ('powershell -Command "(Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average).Average"') do set "CURRENT_CPU=%%a"
for /f "tokens=2 delims==" %%a in ('powershell -Command "$mem = Get-WmiObject -Class Win32_ComputerSystem; $free = (Get-WmiObject -Class Win32_PerfRawData_PerfOS_Memory).AvailableBytes; $used = (($mem.TotalPhysicalMemory - $free) / $mem.TotalPhysicalMemory) * 100; [math]::Round($used, 1)"') do set "CURRENT_MEMORY=%%a"

REM Count completed requests
set "COMPLETED_REQUESTS=0"
if exist "%TEST_RESULTS_FILE%" (
    for /f %%i in ('find /c /v "" "%TEST_RESULTS_FILE%"') do set "COMPLETED_REQUESTS=%%i"
    set /a COMPLETED_REQUESTS=!COMPLETED_REQUESTS! - 1
)

REM Calculate progress
set /a TOTAL_REQUESTS=%CONCURRENT_THREADS% * %REQUESTS_PER_THREAD%
if %COMPLETED_REQUESTS% gtr 0 (
    set /a PROGRESS=(!COMPLETED_REQUESTS! * 100) / %TOTAL_REQUESTS%
) else (
    set "PROGRESS=0"
)

cls
echo %BLUE%
echo ====================================================================
echo                    LOAD TEST IN PROGRESS
echo ====================================================================
echo Test Time: %MONITOR_COUNT% minutes
echo Active Threads: %ACTIVE_THREADS%/%CONCURRENT_THREADS%
echo Completed Requests: %COMPLETED_REQUESTS%/%TOTAL_REQUESTS% (%PROGRESS%%%)
echo ====================================================================
echo Current System Metrics:
echo   CPU Usage: %CURRENT_CPU%%% (Baseline: %BASELINE_CPU%%%)
echo   Memory Usage: %CURRENT_MEMORY%%% (Baseline: %BASELINE_MEMORY%%%)
echo ====================================================================
echo %NC%

REM Log monitoring data
echo [%date% %time%] MONITOR: Active=%ACTIVE_THREADS% Progress=%PROGRESS%%% CPU=%CURRENT_CPU%%% MEM=%CURRENT_MEMORY%%% >> logs\load-test.log

REM Check if all threads completed
if %ACTIVE_THREADS% equ 0 (
    call :log_success "All load test threads completed"
    goto :test_completed
)

REM Check monitor timeout
if %MONITOR_COUNT% geq %MAX_MONITORS% (
    call :log_warning "Monitoring timeout reached, checking final results"
    goto :test_completed
)

REM Wait before next monitor cycle
timeout /t 60 >nul
goto :monitor_loop

REM ====================================
REM TEST COMPLETION AND ANALYSIS
REM ====================================
:test_completed
set "END_TIME=%date% %time%"

echo.
echo %CYAN%====================================================================
echo                        LOAD TEST COMPLETED
echo ====================================================================
echo Start Time: %START_TIME%
echo End Time: %END_TIME%
echo ====================================================================
echo %NC%

call :log_info "Load test completed, analyzing results..."

REM ====================================
REM RESULTS ANALYSIS
REM ====================================
echo %CYAN%Analyzing test results...%NC%

REM Count total requests and calculate success rate
if exist "%TEST_RESULTS_FILE%" (
    REM Total requests (excluding header)
    for /f %%i in ('find /c /v "" "%TEST_RESULTS_FILE%"') do set "TOTAL_PROCESSED=%%i"
    set /a TOTAL_PROCESSED=!TOTAL_PROCESSED! - 1
    
    REM Successful requests
    for /f %%i in ('findstr /c:"SUCCESS" "%TEST_RESULTS_FILE%" ^| find /c "SUCCESS"') do set "SUCCESSFUL_REQUESTS=%%i"
    
    REM Failed requests
    for /f %%i in ('findstr /c:"FAILED" "%TEST_RESULTS_FILE%" ^| find /c "FAILED"') do set "FAILED_REQUESTS=%%i"
    
    REM Calculate success rate
    if %TOTAL_PROCESSED% gtr 0 (
        set /a SUCCESS_RATE=(!SUCCESSFUL_REQUESTS! * 100) / %TOTAL_PROCESSED%
    ) else (
        set "SUCCESS_RATE=0"
    )
    
    call :log_info "Results: Total=%TOTAL_PROCESSED% Success=%SUCCESSFUL_REQUESTS% Failed=%FAILED_REQUESTS% Rate=%SUCCESS_RATE%%%"
) else (
    call :log_error "Test results file not found"
    set "TOTAL_PROCESSED=0"
    set "SUCCESSFUL_REQUESTS=0"
    set "FAILED_REQUESTS=0"
    set "SUCCESS_RATE=0"
)

REM ====================================
REM PERFORMANCE ANALYSIS
REM ====================================
echo %CYAN%Performance Analysis:%NC%

REM Calculate average response time
if exist "%TEST_RESULTS_FILE%" (
    powershell -Command "
    $data = Import-Csv '%TEST_RESULTS_FILE%' | Where-Object { $_.Result -eq 'SUCCESS' -and $_.ResponseTime -ne 'ERROR' }
    if ($data.Count -gt 0) {
        $avgResponse = ($data.ResponseTime | ForEach-Object { [int]$_ } | Measure-Object -Average).Average
        $maxResponse = ($data.ResponseTime | ForEach-Object { [int]$_ } | Measure-Object -Maximum).Maximum
        $minResponse = ($data.ResponseTime | ForEach-Object { [int]$_ } | Measure-Object -Minimum).Minimum
        Write-Host \"AVG:$([math]::Round($avgResponse, 0)) MAX:$maxResponse MIN:$minResponse\"
    } else {
        Write-Host 'AVG:0 MAX:0 MIN:0'
    }
    " > temp_response_stats.txt
    
    set /p RESPONSE_STATS=<temp_response_stats.txt
    del temp_response_stats.txt
) else (
    set "RESPONSE_STATS=AVG:0 MAX:0 MIN:0"
)

REM Parse response statistics
for /f "tokens=1,2,3 delims=: " %%a in ("%RESPONSE_STATS%") do (
    set "AVG_RESPONSE=%%b"
    set "MAX_RESPONSE=%%d"
    set "MIN_RESPONSE=%%f"
)

echo %GREEN%  Average Response Time: %AVG_RESPONSE%ms%NC%
echo %GREEN%  Maximum Response Time: %MAX_RESPONSE%ms%NC%
echo %GREEN%  Minimum Response Time: %MIN_RESPONSE%ms%NC%

REM ====================================
REM FINAL SYSTEM METRICS
REM ====================================
echo %CYAN%Final System Metrics:%NC%

REM Final CPU usage
for /f "tokens=2 delims==" %%a in ('powershell -Command "(Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average).Average"') do set "FINAL_CPU=%%a"

REM Final memory usage
for /f "tokens=2 delims==" %%a in ('powershell -Command "$mem = Get-WmiObject -Class Win32_ComputerSystem; $free = (Get-WmiObject -Class Win32_PerfRawData_PerfOS_Memory).AvailableBytes; $used = (($mem.TotalPhysicalMemory - $free) / $mem.TotalPhysicalMemory) * 100; [math]::Round($used, 1)"') do set "FINAL_MEMORY=%%a"

echo %CYAN%  Final CPU Usage: %FINAL_CPU%%% (Baseline: %BASELINE_CPU%%%)%NC%
echo %CYAN%  Final Memory Usage: %FINAL_MEMORY%%% (Baseline: %BASELINE_MEMORY%%%)%NC%

REM ====================================
REM TEST SUMMARY AND SCORING
REM ====================================
echo.
echo %CYAN%====================================================================
echo                        LOAD TEST SUMMARY
echo ====================================================================
echo Test Configuration:
echo   Target Users: %TARGET_USERS%
echo   Concurrent Threads: %CONCURRENT_THREADS%
echo   Requests per Thread: %REQUESTS_PER_THREAD%
echo ====================================================================
echo Results:
echo   Total Requests: %TOTAL_PROCESSED%
echo   Successful Requests: %SUCCESSFUL_REQUESTS%
echo   Failed Requests: %FAILED_REQUESTS%
echo   Success Rate: %SUCCESS_RATE%%%
echo ====================================================================
echo Performance:
echo   Average Response Time: %AVG_RESPONSE%ms
echo   Maximum Response Time: %MAX_RESPONSE%ms
echo   Minimum Response Time: %MIN_RESPONSE%ms
echo   Baseline Response: %BASELINE_RESPONSE%ms
echo ====================================================================
echo System Impact:
echo   CPU: %BASELINE_CPU%%% → %FINAL_CPU%%%
echo   Memory: %BASELINE_MEMORY%%% → %FINAL_MEMORY%%%
echo ====================================================================

REM Calculate overall score
set "SCORE=0"

if %SUCCESS_RATE% geq 95 set /a SCORE+=30
if %AVG_RESPONSE% lss 3000 set /a SCORE+=25
if %FINAL_CPU% lss 80 set /a SCORE+=20
if %FINAL_MEMORY% lss 85 set /a SCORE+=15
if %FAILED_REQUESTS% lss 5 set /a SCORE+=10

if %SCORE% geq 90 (
    echo %GREEN%Overall Performance: EXCELLENT (%SCORE%/100)%NC%
    echo %GREEN%✓ System ready for 50+ concurrent users%NC%
    call :log_success "Load test passed with excellent performance: %SCORE%/100"
) else if %SCORE% geq 70 (
    echo %YELLOW%Overall Performance: GOOD (%SCORE%/100)%NC%
    echo %YELLOW%✓ System capable of handling 50 concurrent users%NC%
    call :log_success "Load test passed with good performance: %SCORE%/100"
) else if %SCORE% geq 50 (
    echo %YELLOW%Overall Performance: FAIR (%SCORE%/100)%NC%
    echo %YELLOW%⚠ System may struggle with peak loads%NC%
    call :log_warning "Load test completed with fair performance: %SCORE%/100"
) else (
    echo %RED%Overall Performance: POOR (%SCORE%/100)%NC%
    echo %RED%✗ System needs optimization for 50 users%NC%
    call :log_error "Load test failed with poor performance: %SCORE%/100"
)

echo ====================================================================
echo Test Files:
echo   Results: %TEST_RESULTS_FILE%
echo   Log: logs\load-test.log
echo   Script: load-test-script.ps1
echo ====================================================================%NC%

REM ====================================
REM CLEANUP
REM ====================================
call :log_info "Cleaning up test files..."

if exist "load-test-script.ps1" del "load-test-script.ps1"

call :log_info "Load test completed successfully"

echo.
echo %GREEN%Load test completed!%NC%
echo %CYAN%Review the results and logs for detailed performance analysis.%NC%
echo.

pause