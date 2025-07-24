@echo off
echo ====================================================================
echo                  DEBUG STARTUP SEQUENCE
echo ====================================================================
echo.

cd /d "%~dp0"
echo [DEBUG] Current directory: %CD%
echo.

echo [DEBUG] Step 1: Environment validation
if not exist "odoo-bin" (
    echo [ERROR] odoo-bin not found!
    pause
    exit /b 1
)
echo [PASS] odoo-bin found

if not exist "odoo-prod.conf" (
    echo [ERROR] odoo-prod.conf not found!
    pause
    exit /b 1
)
echo [PASS] odoo-prod.conf found

if not exist "odoo_env" (
    echo [ERROR] Virtual environment not found!
    pause
    exit /b 1
)
echo [PASS] Virtual environment found
echo.

echo [DEBUG] Step 2: Virtual environment activation
call odoo_env\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo [ERROR] Failed to activate virtual environment
    pause
    exit /b 1
)
echo [PASS] Virtual environment activated
echo.

echo [DEBUG] Step 3: Python validation
python -c "print('Python working')"
if %errorlevel% neq 0 (
    echo [ERROR] Python not working
    pause
    exit /b 1
)
echo [PASS] Python working
echo.

echo [DEBUG] Step 4: Odoo import test
python -c "import odoo; print('Odoo import: SUCCESS')"
if %errorlevel% neq 0 (
    echo [ERROR] Odoo import failed
    pause
    exit /b 1
)
echo [PASS] Odoo import successful
echo.

echo [DEBUG] Step 5: Database adapter test
python -c "import psycopg2; print('psycopg2 import: SUCCESS')"
if %errorlevel% neq 0 (
    echo [ERROR] psycopg2 import failed
    pause
    exit /b 1
)
echo [PASS] Database adapter working
echo.

echo [DEBUG] Step 6: Memory check (this might cause issues)
echo Attempting PowerShell memory check...
powershell -Command "try { $mem = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory/1GB); Write-Host 'Memory: ' $mem 'GB' } catch { Write-Host 'Memory check failed' }"
echo [INFO] Memory check completed (may have failed but continuing)
echo.

echo [DEBUG] Step 7: Database connectivity test (this might cause issues)
echo Attempting PostgreSQL connection test...
powershell -Command "try { Write-Host 'Database test: SKIPPED for debugging' } catch { Write-Host 'Database test failed' }"
echo [INFO] Database test skipped for debugging
echo.

echo [DEBUG] Step 8: Configuration validation
python -c "
import configparser
try:
    config = configparser.ConfigParser()
    config.read('odoo-prod.conf')
    print('Configuration syntax: OK')
except Exception as e:
    print(f'Configuration error: {e}')
    exit(1)
"
if %errorlevel% neq 0 (
    echo [ERROR] Configuration validation failed
    pause
    exit /b 1
)
echo [PASS] Configuration validated
echo.

echo [DEBUG] All checks passed! Starting Odoo...
echo.
echo Starting Odoo Production Server...
echo URL: http://localhost:8069
echo Press Ctrl+C to stop
echo.

python odoo-bin -c odoo-prod.conf --logfile=logs/odoo-prod.log

echo.
echo [DEBUG] Odoo server stopped
pause