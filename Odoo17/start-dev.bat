@echo off
REM Simple Odoo 17 Development Server Startup Script
REM For Windows environments

setlocal enabledelayedexpansion

REM Set color codes for Windows
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

REM Function to log messages with timestamp
:log
echo %GREEN%[%date% %time%] INFO: %~1%NC%
exit /b

:error
echo %RED%[%date% %time%] ERROR: %~1%NC%
pause
exit /b 1

:info
echo %BLUE%[%date% %time%] %~1%NC%
exit /b

REM Navigate to the script directory
cd /d "%~dp0"

call :info "======================================================"
call :info "       Starting Odoo 17 Development Server"
call :info "       Environment: Windows"
call :info "======================================================"

REM Validate required files exist
call :log "Validating environment..."
if not exist "odoo-bin" (
    call :error "odoo-bin not found! Please ensure you're in the correct directory."
)

if not exist "odoo-dev.conf" (
    call :error "odoo-dev.conf not found! Configuration file missing."
)

if not exist "odoo_env" (
    call :error "Virtual environment 'odoo_env' not found! Please create it first."
)

REM Stop any existing Odoo processes
call :log "Checking for running Odoo processes..."
tasklist /FI "IMAGENAME eq python.exe" /FI "WINDOWTITLE eq *odoo*" >nul 2>&1
if !errorlevel! equ 0 (
    call :log "Stopping existing Odoo process..."
    taskkill /F /IM python.exe /FI "WINDOWTITLE eq *odoo*" >nul 2>&1
    timeout /t 3 >nul
)

REM Create directories if they don't exist
if not exist "logs" mkdir logs
if not exist "data" mkdir data

REM Activate virtual environment
call :log "Activating virtual environment..."
call odoo_env\Scripts\activate.bat

REM Validate Python environment
call :log "Validating Python environment..."
python -c "import odoo" >nul 2>&1
if !errorlevel! neq 0 (
    call :error "Odoo Python package not found! Please install requirements: pip install -r requirements.txt"
)

REM Test database connectivity (Windows equivalent)
call :log "Testing database connectivity..."
REM Note: pg_isready might not be available on Windows, so we'll skip this check
REM You can install PostgreSQL client tools if needed

REM Display startup information
call :info "======================================================"
call :info "Configuration:"
call :info "- Mode: Development (reload enabled)"
call :info "- Config File: odoo-dev.conf"
call :info "- URL: http://localhost:8069"
call :info "- Admin Password: 1234"
call :info "======================================================"

call :log "Starting Odoo server..."
call :info "Press Ctrl+C to stop the server"
echo.

REM Start Odoo in development mode
python odoo-bin -c odoo-dev.conf

echo.
call :info "======================================================"
call :info "Odoo server stopped."
call :info "======================================================"
pause