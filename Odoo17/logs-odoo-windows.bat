@echo off
REM ====================================================
REM   Odoo 17 Windows Log Viewer Script
REM   View current and archived log files
REM ====================================================

setlocal enabledelayedexpansion

REM Set colors for output
set GREEN=[92m
set RED=[91m
set YELLOW=[93m
set BLUE=[94m
set NC=[0m

echo %BLUE%======================================================%NC%
echo %BLUE%       Odoo 17 Log Viewer - Windows Native Mode%NC%
echo %BLUE%       Time: %date% %time%%NC%
echo %BLUE%======================================================%NC%
echo.

REM Navigate to the script directory
cd /d "%~dp0"

REM Step 1: Check log directory
echo %GREEN%[%time%] Checking log files...%NC%

if not exist "logs" (
    echo %RED%ERROR: logs directory not found!%NC%
    echo Please ensure Odoo has been started at least once.
    pause
    exit /b 1
)

REM Step 2: Display log menu
:MENU
echo.
echo %BLUE%======================================================%NC%
echo %BLUE%Log Viewing Options:%NC%
echo %BLUE%======================================================%NC%

REM Check current log file
if exist "logs\odoo.log" (
    for %%I in ("logs\odoo.log") do set LOG_SIZE=%%~zI
    for /f %%i in ('find /c /v "" ^< "logs\odoo.log"') do set LOG_LINES=%%i
    
    echo %GREEN%✓ Current log file: logs\odoo.log%NC%
    echo %BLUE%  Size: !LOG_SIZE! bytes, Lines: !LOG_LINES!%NC%
) else (
    echo %YELLOW%✗ No current log file found%NC%
    set LOG_SIZE=0
    set LOG_LINES=0
)

REM Check archived logs
if exist "logs\archived\*.log.*" (
    set ARCHIVED_COUNT=0
    for %%f in ("logs\archived\*.log.*") do set /a ARCHIVED_COUNT+=1
    echo %GREEN%✓ Archived logs: !ARCHIVED_COUNT! files%NC%
) else (
    echo %YELLOW%✗ No archived logs found%NC%
    set ARCHIVED_COUNT=0
)

echo.
echo %BLUE%Choose an option:%NC%
echo %BLUE%1. View current log (last 50 lines)%NC%
echo %BLUE%2. View current log (last 100 lines)%NC%
echo %BLUE%3. View current log (all content)%NC%
echo %BLUE%4. Monitor log in real-time (tail -f)%NC%
echo %BLUE%5. Search current log for errors%NC%
echo %BLUE%6. Search current log for warnings%NC%
echo %BLUE%7. Search current log (custom pattern)%NC%
echo %BLUE%8. View archived logs%NC%
echo %BLUE%9. Clear current log file%NC%
echo %BLUE%0. Exit%NC%
echo.

set /p CHOICE=Enter your choice (0-9): 

if "%CHOICE%"=="1" goto VIEW_LAST_50
if "%CHOICE%"=="2" goto VIEW_LAST_100
if "%CHOICE%"=="3" goto VIEW_ALL
if "%CHOICE%"=="4" goto MONITOR_REALTIME
if "%CHOICE%"=="5" goto SEARCH_ERRORS
if "%CHOICE%"=="6" goto SEARCH_WARNINGS
if "%CHOICE%"=="7" goto SEARCH_CUSTOM
if "%CHOICE%"=="8" goto VIEW_ARCHIVED
if "%CHOICE%"=="9" goto CLEAR_LOG
if "%CHOICE%"=="0" goto EXIT
echo %RED%Invalid choice. Please try again.%NC%
goto MENU

:VIEW_LAST_50
echo.
echo %GREEN%======== Last 50 lines of odoo.log ========%NC%
if exist "logs\odoo.log" (
    powershell -Command "Get-Content 'logs\odoo.log' -Tail 50"
) else (
    echo %YELLOW%No current log file found.%NC%
)
echo.
pause
goto MENU

:VIEW_LAST_100
echo.
echo %GREEN%======== Last 100 lines of odoo.log ========%NC%
if exist "logs\odoo.log" (
    powershell -Command "Get-Content 'logs\odoo.log' -Tail 100"
) else (
    echo %YELLOW%No current log file found.%NC%
)
echo.
pause
goto MENU

:VIEW_ALL
echo.
echo %GREEN%======== Complete odoo.log content ========%NC%
if exist "logs\odoo.log" (
    if !LOG_SIZE! gtr 1048576 (
        echo %YELLOW%Warning: Log file is large (!LOG_SIZE! bytes). This may take a while.%NC%
        set /p CONTINUE=Continue? (Y/N): 
        if /i not "!CONTINUE!"=="Y" goto MENU
    )
    type "logs\odoo.log"
) else (
    echo %YELLOW%No current log file found.%NC%
)
echo.
pause
goto MENU

:MONITOR_REALTIME
echo.
echo %GREEN%======== Real-time log monitoring ========%NC%
echo %YELLOW%Press Ctrl+C to stop monitoring%NC%
echo.
if exist "logs\odoo.log" (
    REM Use PowerShell for real-time monitoring
    powershell -Command "& {Get-Content 'logs\odoo.log' -Wait -Tail 10}"
) else (
    echo %YELLOW%No current log file found. Waiting for log file creation...%NC%
    REM Wait for log file to be created
    :WAIT_FOR_LOG
    if exist "logs\odoo.log" (
        powershell -Command "& {Get-Content 'logs\odoo.log' -Wait -Tail 10}"
    ) else (
        timeout /t 2 /nobreak >nul
        goto WAIT_FOR_LOG
    )
)
echo.
echo %GREEN%Real-time monitoring stopped.%NC%
pause
goto MENU

:SEARCH_ERRORS
echo.
echo %GREEN%======== Searching for ERRORS in log ========%NC%
if exist "logs\odoo.log" (
    findstr /i /n "error" "logs\odoo.log"
    if %errorlevel% neq 0 (
        echo %GREEN%No errors found in current log.%NC%
    )
) else (
    echo %YELLOW%No current log file found.%NC%
)
echo.
pause
goto MENU

:SEARCH_WARNINGS
echo.
echo %GREEN%======== Searching for WARNINGS in log ========%NC%
if exist "logs\odoo.log" (
    findstr /i /n "warning warn" "logs\odoo.log"
    if %errorlevel% neq 0 (
        echo %GREEN%No warnings found in current log.%NC%
    )
) else (
    echo %YELLOW%No current log file found.%NC%
)
echo.
pause
goto MENU

:SEARCH_CUSTOM
echo.
set /p SEARCH_PATTERN=Enter search pattern: 
if "%SEARCH_PATTERN%"=="" (
    echo %RED%No search pattern provided.%NC%
    pause
    goto MENU
)
echo.
echo %GREEN%======== Searching for "%SEARCH_PATTERN%" in log ========%NC%
if exist "logs\odoo.log" (
    findstr /i /n "%SEARCH_PATTERN%" "logs\odoo.log"
    if %errorlevel% neq 0 (
        echo %YELLOW%No matches found for "%SEARCH_PATTERN%".%NC%
    )
) else (
    echo %YELLOW%No current log file found.%NC%
)
echo.
pause
goto MENU

:VIEW_ARCHIVED
echo.
echo %GREEN%======== Archived Log Files ========%NC%
if exist "logs\archived\*.log.*" (
    echo %BLUE%Available archived log files:%NC%
    set ARCHIVE_INDEX=0
    
    for %%f in ("logs\archived\*.log.*") do (
        set /a ARCHIVE_INDEX+=1
        echo %BLUE%!ARCHIVE_INDEX!. %%~nxf%NC%
        set ARCHIVE_FILE_!ARCHIVE_INDEX!=%%f
    )
    
    echo.
    set /p ARCHIVE_CHOICE=Enter file number to view (or 0 to return): 
    
    if "%ARCHIVE_CHOICE%"=="0" goto MENU
    
    REM Validate choice
    if !ARCHIVE_CHOICE! gtr !ARCHIVE_INDEX! (
        echo %RED%Invalid file number.%NC%
        pause
        goto VIEW_ARCHIVED
    )
    
    if !ARCHIVE_CHOICE! lss 1 (
        echo %RED%Invalid file number.%NC%
        pause
        goto VIEW_ARCHIVED
    )
    
    REM Get selected file
    call set SELECTED_FILE=%%ARCHIVE_FILE_!ARCHIVE_CHOICE!%%
    
    echo.
    echo %GREEN%======== Content of !SELECTED_FILE! ========%NC%
    
    REM Check file size before displaying
    for %%I in ("!SELECTED_FILE!") do set ARCHIVE_SIZE=%%~zI
    if !ARCHIVE_SIZE! gtr 1048576 (
        echo %YELLOW%Warning: Archive file is large (!ARCHIVE_SIZE! bytes).%NC%
        set /p CONTINUE=Continue? (Y/N): 
        if /i not "!CONTINUE!"=="Y" goto VIEW_ARCHIVED
    )
    
    type "!SELECTED_FILE!"
    
) else (
    echo %YELLOW%No archived log files found.%NC%
)
echo.
pause
goto MENU

:CLEAR_LOG
echo.
echo %YELLOW%======== Clear Current Log File ========%NC%
if exist "logs\odoo.log" (
    echo %YELLOW%This will clear the current log file (logs\odoo.log).%NC%
    echo %YELLOW%Current log size: !LOG_SIZE! bytes, !LOG_LINES! lines%NC%
    echo.
    set /p CONFIRM=Are you sure? This cannot be undone (Y/N): 
    
    if /i "!CONFIRM!"=="Y" (
        REM Backup current log before clearing
        set timestamp=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%
        set timestamp=!timestamp: =0!
        
        if not exist "logs\archived" mkdir "logs\archived"
        copy "logs\odoo.log" "logs\archived\odoo.log.cleared.!timestamp!" >nul 2>&1
        
        REM Clear the log file
        echo. > "logs\odoo.log"
        
        echo %GREEN%✓ Log file cleared and backed up as:%NC%
        echo %BLUE%  logs\archived\odoo.log.cleared.!timestamp!%NC%
    ) else (
        echo %BLUE%Log clearing cancelled.%NC%
    )
) else (
    echo %YELLOW%No current log file to clear.%NC%
)
echo.
pause
goto MENU

:EXIT
echo.
echo %BLUE%======================================================%NC%
echo %BLUE%Log File Summary:%NC%
echo %BLUE%======================================================%NC%

if exist "logs\odoo.log" (
    echo %GREEN%✓ Current log: logs\odoo.log (!LOG_SIZE! bytes, !LOG_LINES! lines)%NC%
) else (
    echo %YELLOW%✗ No current log file%NC%
)

if !ARCHIVED_COUNT! gtr 0 (
    echo %GREEN%✓ Archived logs: !ARCHIVED_COUNT! files in logs\archived\%NC%
) else (
    echo %YELLOW%✗ No archived logs%NC%
)

echo.
echo %BLUE%Useful Commands:%NC%
echo %BLUE%- View errors only: findstr /i "error" logs\odoo.log%NC%
echo %BLUE%- View warnings only: findstr /i "warning" logs\odoo.log%NC%
echo %BLUE%- Live monitoring: logs-odoo-windows.bat (option 4)%NC%
echo.
echo %BLUE%======================================================%NC%
echo %GREEN%Log viewer session ended.%NC%

echo Press any key to close this window...
pause >nul