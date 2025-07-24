@echo off
REM ====================================================================
REM Odoo 17 Startup Diagnostic Script
REM Helps identify and fix common startup issues
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
REM DIAGNOSTIC HEADER
REM ====================================
cls
echo %BLUE%
echo ====================================================================
echo                  ODOO 17 STARTUP DIAGNOSTICS
echo                     Problem Analysis Tool
echo ====================================================================
echo %NC%

REM Navigate to script directory
cd /d "%~dp0"

echo %CYAN%Running comprehensive startup diagnostics...%NC%
echo.

REM ====================================
REM CHECK 1: VERIFY DIRECTORY STRUCTURE
REM ====================================
echo %CYAN%1. Checking directory structure:%NC%

if exist "odoo-bin" (
    echo %GREEN%  ✓ odoo-bin found%NC%
) else (
    echo %RED%  ✗ odoo-bin missing - This is the Odoo executable%NC%
    set "CRITICAL_ERROR=1"
)

if exist "odoo-prod.conf" (
    echo %GREEN%  ✓ odoo-prod.conf found%NC%
) else (
    echo %RED%  ✗ odoo-prod.conf missing - Production configuration file%NC%
    set "CRITICAL_ERROR=1"
)

if exist "odoo_env" (
    echo %GREEN%  ✓ odoo_env directory found%NC%
) else (
    echo %RED%  ✗ odoo_env missing - Python virtual environment%NC%
    echo %YELLOW%    Create with: python -m venv odoo_env%NC%
    set "CRITICAL_ERROR=1"
)

if exist "odoo_env\Scripts\activate.bat" (
    echo %GREEN%  ✓ Virtual environment activation script found%NC%
) else (
    echo %RED%  ✗ Virtual environment activation script missing%NC%
    set "CRITICAL_ERROR=1"
)

if exist "addons" (
    echo %GREEN%  ✓ addons directory found%NC%
) else (
    echo %RED%  ✗ addons directory missing - Core Odoo modules%NC%
    set "CRITICAL_ERROR=1"
)

echo.

REM ====================================
REM CHECK 2: PYTHON ENVIRONMENT
REM ====================================
echo %CYAN%2. Checking Python environment:%NC%

REM Test Python availability
python --version >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=2" %%a in ('python --version 2^>^&1') do echo %GREEN%  ✓ Python version: %%a%NC%
) else (
    echo %RED%  ✗ Python not found or not in PATH%NC%
    set "CRITICAL_ERROR=1"
)

REM Test virtual environment activation
call odoo_env\Scripts\activate.bat >nul 2>&1
if !errorlevel! equ 0 (
    echo %GREEN%  ✓ Virtual environment can be activated%NC%
    
    REM Test Odoo package
    python -c "import odoo" >nul 2>&1
    if !errorlevel! equ 0 (
        echo %GREEN%  ✓ Odoo package installed in virtual environment%NC%
    ) else (
        echo %RED%  ✗ Odoo package not found in virtual environment%NC%
        echo %YELLOW%    Install with: pip install -r requirements.txt%NC%
        set "MISSING_DEPS=1"
    )
    
    REM Test PostgreSQL adapter
    python -c "import psycopg2" >nul 2>&1
    if !errorlevel! equ 0 (
        echo %GREEN%  ✓ PostgreSQL adapter (psycopg2) installed%NC%
    ) else (
        echo %RED%  ✗ PostgreSQL adapter (psycopg2) missing%NC%
        echo %YELLOW%    Install with: pip install psycopg2%NC%
        set "MISSING_DEPS=1"
    )
) else (
    echo %RED%  ✗ Cannot activate virtual environment%NC%
    set "CRITICAL_ERROR=1"
)

echo.

REM ====================================
REM CHECK 3: POSTGRESQL CONNECTIVITY
REM ====================================
echo %CYAN%3. Checking PostgreSQL connectivity:%NC%

REM Test if PostgreSQL service is running
sc query postgresql-x64-17 | findstr "RUNNING" >nul 2>&1
if !errorlevel! equ 0 (
    echo %GREEN%  ✓ PostgreSQL 17 service is running%NC%
) else (
    echo %RED%  ✗ PostgreSQL 17 service not running%NC%
    echo %YELLOW%    Start with: net start postgresql-x64-17%NC%
    set "DB_ERROR=1"
)

REM Test database connection
powershell -Command "try { $conn = New-Object System.Data.Odbc.OdbcConnection('Driver={PostgreSQL Unicode};Server=localhost;Port=5432;Database=postgres;Uid=admin;Pwd=1234;'); $conn.Open(); $conn.Close(); Write-Host 'SUCCESS' } catch { Write-Host 'FAILED' }" > temp_db_diag.txt
set /p DB_CONN_RESULT=<temp_db_diag.txt
del temp_db_diag.txt

if "%DB_CONN_RESULT%"=="SUCCESS" (
    echo %GREEN%  ✓ Database connection successful (admin/1234)%NC%
) else (
    echo %RED%  ✗ Database connection failed%NC%
    echo %YELLOW%    Check PostgreSQL service and credentials%NC%
    set "DB_ERROR=1"
)

echo.

REM ====================================
REM CHECK 4: CONFIGURATION VALIDATION
REM ====================================
echo %CYAN%4. Checking configuration files:%NC%

if exist "odoo-prod.conf" (
    REM Test configuration syntax
    python -c "
import configparser
import sys
try:
    config = configparser.ConfigParser()
    config.read('odoo-prod.conf')
    print('VALID')
except Exception as e:
    print(f'INVALID: {e}')
    sys.exit(1)
" > temp_config_test.txt 2>&1
    
    set /p CONFIG_RESULT=<temp_config_test.txt
    del temp_config_test.txt
    
    if "!CONFIG_RESULT!"=="VALID" (
        echo %GREEN%  ✓ Configuration file syntax is valid%NC%
    ) else (
        echo %RED%  ✗ Configuration file has syntax errors%NC%
        echo %YELLOW%    !CONFIG_RESULT!%NC%
        set "CONFIG_ERROR=1"
    )
) else (
    echo %RED%  ✗ Configuration file missing%NC%
    set "CRITICAL_ERROR=1"
)

echo.

REM ====================================
REM CHECK 5: NETWORK PORTS
REM ====================================
echo %CYAN%5. Checking network ports:%NC%

netstat -an | findstr ":8069" >nul
if !errorlevel! equ 0 (
    echo %YELLOW%  ⚠ Port 8069 already in use (previous Odoo instance?)%NC%
    set "PORT_CONFLICT=1"
) else (
    echo %GREEN%  ✓ Port 8069 available%NC%
)

netstat -an | findstr ":8072" >nul
if !errorlevel! equ 0 (
    echo %YELLOW%  ⚠ Port 8072 already in use%NC%
) else (
    echo %GREEN%  ✓ Port 8072 available%NC%
)

echo.

REM ====================================
REM CHECK 6: SYSTEM RESOURCES
REM ====================================
echo %CYAN%6. Checking system resources:%NC%

REM Check available memory
for /f "tokens=2 delims==" %%a in ('powershell -Command "(Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory/1GB"') do set "TOTAL_RAM=%%a"
echo %CYAN%  System Memory: %TOTAL_RAM% GB%NC%

if %TOTAL_RAM% lss 8 (
    echo %RED%  ✗ Insufficient memory for production (minimum 8GB)%NC%
    set "RESOURCE_WARNING=1"
) else if %TOTAL_RAM% lss 32 (
    echo %YELLOW%  ⚠ Low memory for 50 users (recommended 32GB+)%NC%
    set "RESOURCE_WARNING=1"
) else (
    echo %GREEN%  ✓ Sufficient memory for 50 users%NC%
)

echo.

REM ====================================
REM DIAGNOSTIC SUMMARY
REM ====================================
echo %CYAN%====================================================================
echo                        DIAGNOSTIC SUMMARY
echo ====================================================================

if defined CRITICAL_ERROR (
    echo %RED%CRITICAL ERRORS FOUND - Cannot start Odoo%NC%
    echo %RED%Please fix the critical errors above before starting Odoo%NC%
    echo.
    echo %YELLOW%Common fixes:%NC%
    echo %YELLOW%1. Ensure you're in the correct Odoo directory%NC%
    echo %YELLOW%2. Create virtual environment: python -m venv odoo_env%NC%
    echo %YELLOW%3. Install dependencies: pip install -r requirements.txt%NC%
    echo.
) else (
    echo %GREEN%No critical errors found%NC%
    
    if defined MISSING_DEPS (
        echo %YELLOW%Missing Python dependencies detected%NC%
        echo %YELLOW%Run: pip install -r requirements.txt%NC%
        echo.
    )
    
    if defined DB_ERROR (
        echo %YELLOW%Database connectivity issues detected%NC%
        echo %YELLOW%1. Start PostgreSQL: net start postgresql-x64-17%NC%
        echo %YELLOW%2. Run database setup: scripts\configure-postgresql.bat%NC%
        echo.
    )
    
    if defined CONFIG_ERROR (
        echo %YELLOW%Configuration file issues detected%NC%
        echo %YELLOW%Check odoo-prod.conf syntax%NC%
        echo.
    )
    
    if defined PORT_CONFLICT (
        echo %YELLOW%Port conflicts detected%NC%
        echo %YELLOW%Stop existing Odoo processes before starting%NC%
        echo.
    )
    
    if defined RESOURCE_WARNING (
        echo %YELLOW%System resource warnings%NC%
        echo %YELLOW%Consider upgrading memory for optimal performance%NC%
        echo.
    )
    
    if not defined MISSING_DEPS if not defined DB_ERROR if not defined CONFIG_ERROR if not defined PORT_CONFLICT (
        echo %GREEN%System appears ready for Odoo startup!%NC%
        echo %GREEN%Try running: start-production.bat%NC%
        echo.
    )
)

echo ====================================================================
echo Next steps:
echo 1. Fix any critical errors shown above
echo 2. Run: scripts\configure-postgresql.bat (if not done)
echo 3. Run: start-production.bat
echo 4. Access: http://localhost:8069
echo ====================================================================
echo %NC%

echo.
echo %GREEN%Press any key to close this diagnostic window...%NC%
pause >nul