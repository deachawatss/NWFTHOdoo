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
goto :eof

:log_error
echo %RED%[%date% %time%] ERROR: %~1%NC%
echo [%date% %time%] ERROR: %~1 >> logs\startup.log
goto :eof

:log_warning
echo %YELLOW%[%date% %time%] WARNING: %~1%NC%
echo [%date% %time%] WARNING: %~1 >> logs\startup.log
goto :eof

:log_success
echo %CYAN%[%date% %time%] SUCCESS: %~1%NC%
echo [%date% %time%] SUCCESS: %~1 >> logs\startup.log
goto :eof

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
    call :log_info "Please run setup-environment.bat first!"
    pause
    exit /b 1
)

call :log_success "All required files found"

REM ====================================
REM CREATE REQUIRED DIRECTORIES
REM ====================================
call :log_info "Creating required directories..."
if not exist "logs" mkdir logs
if not exist "data" mkdir data
if not exist "backup" mkdir backup
if not exist "sessions" mkdir sessions

REM ====================================
REM STOP EXISTING PROCESSES (SIMPLIFIED)
REM ====================================
call :log_info "Checking for existing Odoo processes..."
tasklist /FI "IMAGENAME eq python.exe" | findstr "python.exe" >nul
if !errorlevel! equ 0 (
    call :log_warning "Python processes found. You may want to stop them manually if needed."
)

REM ====================================
REM PYTHON ENVIRONMENT ACTIVATION
REM ====================================
call :log_info "Activating Python virtual environment..."
call %PYTHON_ENV%\Scripts\activate.bat
if !errorlevel! neq 0 (
    call :log_error "Failed to activate virtual environment!"
    pause
    exit /b 1
)

REM Validate Python environment (simplified)
call :log_info "Validating Python dependencies..."
python -c "import odoo" >nul 2>&1
if !errorlevel! neq 0 (
    call :log_error "Odoo Python package not found!"
    call :log_error "Please run install-odoo-deps.bat first!"
    pause
    exit /b 1
)

python -c "import psycopg2" >nul 2>&1
if !errorlevel! neq 0 (
    call :log_error "PostgreSQL adapter (psycopg2) not found!"
    call :log_error "Please run install-odoo-deps.bat first!"
    pause
    exit /b 1
)

call :log_success "Python environment validated"

REM ====================================
REM CONFIGURATION VALIDATION (SIMPLIFIED)
REM ====================================
call :log_info "Validating production configuration..."

REM Simple configuration test
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
REM STARTUP INFORMATION DISPLAY
REM ====================================
echo.
echo %CYAN%====================================================================
echo                      PRODUCTION STARTUP SUMMARY
echo ====================================================================
echo Server: %COMPUTERNAME%
echo Main URL: http://localhost:8069
echo Live Chat: http://localhost:8072
echo Database: PostgreSQL 17 (localhost:5432)
echo Workers: %WORKER_COUNT% processes
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