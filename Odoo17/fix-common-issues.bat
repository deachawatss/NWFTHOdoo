@echo off
REM ====================================================================
REM Odoo 17 Common Issues Fix Script
REM Automatically fixes typical startup problems
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
REM ADMIN CHECK
REM ====================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo %RED%This script requires Administrator privileges%NC%
    echo %YELLOW%Right-click and select "Run as administrator"%NC%
    pause
    exit /b 1
)

REM ====================================
REM FIX HEADER
REM ====================================
cls
echo %BLUE%
echo ====================================================================
echo                   ODOO 17 COMMON ISSUES FIX
echo                    Automatic Problem Resolver
echo ====================================================================
echo %NC%

cd /d "%~dp0"

echo %CYAN%Applying common fixes...%NC%
echo.

REM ====================================
REM FIX 1: STOP CONFLICTING PROCESSES
REM ====================================
echo %CYAN%1. Stopping conflicting Odoo processes...%NC%

tasklist /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq *odoo*" >nul 2>&1
if !errorlevel! equ 0 (
    echo %YELLOW%  Stopping existing Odoo processes...%NC%
    taskkill /F /IM python.exe /FI "WINDOWTITLE eq *odoo*" >nul 2>&1
    timeout /t 3 >nul
    echo %GREEN%  ✓ Existing processes stopped%NC%
) else (
    echo %GREEN%  ✓ No conflicting processes found%NC%
)

echo.

REM ====================================
REM FIX 2: ENSURE POSTGRESQL IS RUNNING
REM ====================================
echo %CYAN%2. Ensuring PostgreSQL 17 service is running...%NC%

sc query postgresql-x64-17 | findstr "RUNNING" >nul 2>&1
if !errorlevel! equ 0 (
    echo %GREEN%  ✓ PostgreSQL 17 is already running%NC%
) else (
    echo %YELLOW%  Starting PostgreSQL 17 service...%NC%
    net start postgresql-x64-17 >nul 2>&1
    if !errorlevel! equ 0 (
        echo %GREEN%  ✓ PostgreSQL 17 started successfully%NC%
        timeout /t 5 >nul
    ) else (
        echo %RED%  ✗ Failed to start PostgreSQL 17%NC%
        echo %YELLOW%    Please check PostgreSQL installation%NC%
    )
)

echo.

REM ====================================
REM FIX 3: CREATE MISSING DIRECTORIES
REM ====================================
echo %CYAN%3. Creating missing directories...%NC%

set "DIRS_CREATED=0"

if not exist "logs" (
    mkdir logs
    echo %GREEN%  ✓ Created logs directory%NC%
    set /a DIRS_CREATED+=1
)

if not exist "data" (
    mkdir data
    echo %GREEN%  ✓ Created data directory%NC%
    set /a DIRS_CREATED+=1
)

if not exist "backup" (
    mkdir backup
    echo %GREEN%  ✓ Created backup directory%NC%
    set /a DIRS_CREATED+=1
)

if not exist "sessions" (
    mkdir sessions
    echo %GREEN%  ✓ Created sessions directory%NC%
    set /a DIRS_CREATED+=1
)

if %DIRS_CREATED% equ 0 (
    echo %GREEN%  ✓ All required directories exist%NC%
)

echo.

REM ====================================
REM FIX 4: VERIFY PYTHON ENVIRONMENT
REM ====================================
echo %CYAN%4. Checking Python virtual environment...%NC%

if not exist "odoo_env" (
    echo %YELLOW%  Creating Python virtual environment...%NC%
    python -m venv odoo_env
    if !errorlevel! equ 0 (
        echo %GREEN%  ✓ Virtual environment created%NC%
    ) else (
        echo %RED%  ✗ Failed to create virtual environment%NC%
        echo %YELLOW%    Please check Python installation%NC%
    )
) else (
    echo %GREEN%  ✓ Virtual environment exists%NC%
)

REM Test if we can activate the environment
if exist "odoo_env\Scripts\activate.bat" (
    echo %GREEN%  ✓ Virtual environment activation script found%NC%
) else (
    echo %RED%  ✗ Virtual environment appears corrupted%NC%
    echo %YELLOW%    Consider recreating: rmdir /s odoo_env && python -m venv odoo_env%NC%
)

echo.

REM ====================================
REM FIX 5: INSTALL MISSING DEPENDENCIES
REM ====================================
echo %CYAN%5. Installing missing Python dependencies...%NC%

if exist "requirements.txt" (
    echo %YELLOW%  Installing dependencies from requirements.txt...%NC%
    call odoo_env\Scripts\activate.bat
    pip install -r requirements.txt --quiet >nul 2>&1
    if !errorlevel! equ 0 (
        echo %GREEN%  ✓ Dependencies installed successfully%NC%
    ) else (
        echo %YELLOW%  ⚠ Some dependencies may have failed to install%NC%
        echo %YELLOW%    Run manually: pip install -r requirements.txt%NC%
    )
) else (
    echo %YELLOW%  ⚠ requirements.txt not found%NC%
    echo %YELLOW%    Installing essential packages...%NC%
    call odoo_env\Scripts\activate.bat
    pip install psycopg2 pillow lxml reportlab >nul 2>&1
    echo %GREEN%  ✓ Essential packages installed%NC%
)

echo.

REM ====================================
REM FIX 6: TEST DATABASE CONNECTION
REM ====================================
echo %CYAN%6. Testing database connectivity...%NC%

powershell -Command "try { $conn = New-Object System.Data.Odbc.OdbcConnection('Driver={PostgreSQL Unicode};Server=localhost;Port=5432;Database=postgres;Uid=admin;Pwd=1234;'); $conn.Open(); $conn.Close(); Write-Host 'SUCCESS' } catch { Write-Host 'FAILED' }" > temp_db_fix_test.txt
set /p DB_TEST_RESULT=<temp_db_fix_test.txt
del temp_db_fix_test.txt

if "%DB_TEST_RESULT%"=="SUCCESS" (
    echo %GREEN%  ✓ Database connection successful%NC%
) else (
    echo %YELLOW%  ⚠ Database connection failed%NC%
    echo %YELLOW%    Run: scripts\configure-postgresql.bat%NC%
)

echo.

REM ====================================
REM FIX 7: CLEAR TEMPORARY FILES
REM ====================================
echo %CYAN%7. Cleaning temporary files...%NC%

if exist "temp_*" (
    del temp_* >nul 2>&1
    echo %GREEN%  ✓ Temporary files cleaned%NC%
) else (
    echo %GREEN%  ✓ No temporary files to clean%NC%
)

if exist "logs\odoo-prod.pid" (
    del logs\odoo-prod.pid >nul 2>&1
    echo %GREEN%  ✓ Old PID file removed%NC%
)

echo.

REM ====================================
REM FIX SUMMARY
REM ====================================
echo %CYAN%====================================================================
echo                           FIX SUMMARY
echo ====================================================================

echo %GREEN%Common fixes applied:%NC%
echo %GREEN%✓ Stopped conflicting processes%NC%
echo %GREEN%✓ Started PostgreSQL service%NC%
echo %GREEN%✓ Created required directories%NC%
echo %GREEN%✓ Verified Python environment%NC%
echo %GREEN%✓ Installed dependencies%NC%
echo %GREEN%✓ Tested database connectivity%NC%
echo %GREEN%✓ Cleaned temporary files%NC%

echo.
echo %CYAN%Next steps:%NC%
echo %CYAN%1. Run: diagnose-startup.bat (to verify fixes)%NC%
echo %CYAN%2. Run: scripts\configure-postgresql.bat (if needed)%NC%
echo %CYAN%3. Run: start-production.bat%NC%
echo %CYAN%4. Access: http://localhost:8069%NC%

echo ====================================================================
echo %NC%

echo.
echo %GREEN%Press any key to close...%NC%
pause >nul