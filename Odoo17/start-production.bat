@echo off
REM ====================================================================
REM Odoo 17 Windows Production Startup Script
REM Optimized for 50 concurrent users with multi-worker support
REM Requires: PostgreSQL 17, Python 3.10+, Virtual Environment
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
REM PRODUCTION CONFIGURATION
REM ====================================
set "ODOO_CONFIG=odoo-prod.conf"
set "ODOO_USER=admin"
set "ODOO_DB_PASSWORD=1234"
set "ODOO_LOG_LEVEL=info"
set "PYTHON_ENV=odoo_env"
set "HEALTH_CHECK_URL=http://localhost:8069/web/health"
set "STARTUP_TIMEOUT=180"
set "WORKER_COUNT=10"

REM ====================================
REM LOGGING FUNCTIONS
REM ====================================
:log_info
echo %GREEN%[%date% %time%] INFO: %~1%NC%
echo [%date% %time%] INFO: %~1 >> logs\startup.log
exit /b

:log_error
echo %RED%[%date% %time%] ERROR: %~1%NC%
echo [%date% %time%] ERROR: %~1 >> logs\startup.log
exit /b

:log_warning
echo %YELLOW%[%date% %time%] WARNING: %~1%NC%
echo [%date% %time%] WARNING: %~1 >> logs\startup.log
exit /b

:log_success
echo %CYAN%[%date% %time%] SUCCESS: %~1%NC%
echo [%date% %time%] SUCCESS: %~1 >> logs\startup.log
exit /b

REM ====================================
REM SYSTEM HEADER
REM ====================================
cls
echo %BLUE%
echo ====================================================================
echo                  ODOO 17 PRODUCTION SERVER
echo                    Windows Enterprise Edition
echo              Optimized for 50 Concurrent Users
echo ====================================================================
echo Configuration: %ODOO_CONFIG%
echo Workers: %WORKER_COUNT%
echo Environment: Production
echo Target Users: 50 concurrent
echo ====================================================================
echo %NC%

REM ====================================
REM NAVIGATE TO SCRIPT DIRECTORY
REM ====================================
cd /d "%~dp0"
call :log_info "Navigating to Odoo directory: %CD%"

REM ====================================
REM ENVIRONMENT VALIDATION
REM ====================================
call :log_info "Starting production environment validation..."

REM Check if required files exist
if not exist "odoo-bin" (
    call :log_error "odoo-bin not found! Please ensure you're in the correct directory."
    pause
    exit /b 1
)

if not exist "%ODOO_CONFIG%" (
    call :log_error "Production configuration file '%ODOO_CONFIG%' not found!"
    pause
    exit /b 1
)

if not exist "%PYTHON_ENV%" (
    call :log_error "Python virtual environment '%PYTHON_ENV%' not found!"
    call :log_info "Please create virtual environment: python -m venv %PYTHON_ENV%"
    pause
    exit /b 1
)

REM ====================================
REM CREATE REQUIRED DIRECTORIES
REM ====================================
call :log_info "Creating required directories..."
if not exist "logs" mkdir logs
if not exist "data" mkdir data
if not exist "backup" mkdir backup
if not exist "sessions" mkdir sessions

REM ====================================
REM SYSTEM RESOURCE CHECK
REM ====================================
call :log_info "Checking system resources..."

REM Check available memory (requires PowerShell)
for /f "tokens=2 delims==" %%a in ('powershell -Command "(Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory/1GB"') do set "TOTAL_RAM=%%a"
call :log_info "Total System Memory: %TOTAL_RAM% GB"

REM Memory requirement check (minimum 32GB for 10 workers)
powershell -Command "if([math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory/1GB) -lt 32) { exit 1 } else { exit 0 }"
if !errorlevel! neq 0 (
    call :log_warning "Insufficient memory detected. Recommended: 32GB+ for 50 users"
    call :log_warning "Current: %TOTAL_RAM% GB. Performance may be impacted."
)

REM ====================================
REM STOP EXISTING PROCESSES
REM ====================================
call :log_info "Checking for existing Odoo processes..."
tasklist /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq *odoo*" >nul 2>&1
if !errorlevel! equ 0 (
    call :log_warning "Existing Odoo processes found. Stopping them..."
    taskkill /F /IM python.exe /FI "WINDOWTITLE eq *odoo*" >nul 2>&1
    timeout /t 5 >nul
    call :log_info "Existing processes terminated."
)

REM ====================================
REM DATABASE CONNECTIVITY TEST
REM ====================================
call :log_info "Testing PostgreSQL 17 connectivity..."

REM Test PostgreSQL connection
powershell -Command "try { $conn = New-Object System.Data.Odbc.OdbcConnection('Driver={PostgreSQL Unicode};Server=localhost;Port=5432;Database=postgres;Uid=admin;Pwd=1234;'); $conn.Open(); $conn.Close(); Write-Host 'SUCCESS' } catch { Write-Host 'FAILED' }" > temp_db_test.txt
set /p DB_TEST_RESULT=<temp_db_test.txt
del temp_db_test.txt

if "%DB_TEST_RESULT%"=="FAILED" (
    call :log_error "PostgreSQL connection failed!"
    call :log_error "Please check PostgreSQL 17 service is running"
    call :log_error "Verify credentials: admin/1234"
    pause
    exit /b 1
)
call :log_success "PostgreSQL 17 connection verified"

REM ====================================
REM PYTHON ENVIRONMENT ACTIVATION
REM ====================================
call :log_info "Activating Python virtual environment..."
call %PYTHON_ENV%\Scripts\activate.bat

REM Validate Python environment
call :log_info "Validating Python dependencies..."
python -c "import odoo" >nul 2>&1
if !errorlevel! neq 0 (
    call :log_error "Odoo Python package not found!"
    call :log_error "Please install requirements: pip install -r requirements.txt"
    pause
    exit /b 1
)

python -c "import psycopg2" >nul 2>&1
if !errorlevel! neq 0 (
    call :log_error "PostgreSQL adapter (psycopg2) not found!"
    pause
    exit /b 1
)

call :log_success "Python environment validated"

REM ====================================
REM CONFIGURATION VALIDATION
REM ====================================
call :log_info "Validating production configuration..."

REM Check configuration syntax
python -c "
import configparser
try:
    config = configparser.ConfigParser()
    config.read('%ODOO_CONFIG%')
    print('Configuration syntax: OK')
except Exception as e:
    print(f'Configuration error: {e}')
    exit(1)
" || (
    call :log_error "Configuration file syntax error!"
    pause
    exit /b 1
)

call :log_success "Configuration validated"

REM ====================================
REM FIREWALL & NETWORK CHECK
REM ====================================
call :log_info "Checking network ports availability..."

REM Check if ports 8069 and 8072 are available
netstat -an | findstr ":8069" >nul
if !errorlevel! equ 0 (
    call :log_warning "Port 8069 already in use. Previous Odoo instance may be running."
)

netstat -an | findstr ":8072" >nul
if !errorlevel! equ 0 (
    call :log_warning "Port 8072 already in use. Live chat may not work properly."
)

REM ====================================
REM STARTUP INFORMATION DISPLAY
REM ====================================
echo.
echo %CYAN%====================================================================
echo                      PRODUCTION STARTUP SUMMARY
echo ====================================================================
echo Server IP: %COMPUTERNAME%
echo Main URL: http://localhost:8069
echo Live Chat: http://localhost:8072
echo Database: PostgreSQL 17 (localhost:5432)
echo Workers: %WORKER_COUNT% processes
echo Memory per Worker: ~3GB (Total: ~30GB)
echo Session Storage: Filesystem
echo Expected Capacity: 50+ concurrent users
echo Configuration: %ODOO_CONFIG%
echo ====================================================================
echo %NC%

call :log_info "Production environment ready. Starting Odoo server..."

REM ====================================
REM ODOO SERVER STARTUP
REM ====================================
echo.
echo %GREEN%Starting Odoo 17 Production Server...%NC%
echo %YELLOW%Press Ctrl+C to stop the server%NC%
echo.

REM Start with production configuration
python odoo-bin -c %ODOO_CONFIG% --logfile=logs/odoo-prod.log

REM ====================================
REM SHUTDOWN HANDLING
REM ====================================
echo.
call :log_info "Odoo Production Server stopped."

REM Cleanup
call :log_info "Performing cleanup..."
if exist logs\odoo-prod.pid del logs\odoo-prod.pid

echo.
echo %CYAN%====================================================================
echo                      SERVER STOPPED GRACEFULLY
echo ====================================================================
echo Logs available at: logs\odoo-prod.log
echo Startup log: logs\startup.log
echo Session data preserved: sessions\
echo ====================================================================
echo %NC%

pause