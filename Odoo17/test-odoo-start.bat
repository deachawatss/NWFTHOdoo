@echo off
echo ====================================================================
echo                     ODOO STARTUP TEST SCRIPT
echo ====================================================================
echo.

REM Navigate to script directory
cd /d "%~dp0"
echo Current directory: %CD%
echo.

REM Test 1: Check virtual environment exists
echo [TEST 1] Checking virtual environment...
if not exist "odoo_env\Scripts\activate.bat" (
    echo FAILED: Virtual environment not found!
    echo Please run setup-environment.bat first
    pause
    exit /b 1
)
echo PASSED: Virtual environment found
echo.

REM Test 2: Activate virtual environment
echo [TEST 2] Activating virtual environment...
call odoo_env\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo FAILED: Could not activate virtual environment
    pause
    exit /b 1
)
echo PASSED: Virtual environment activated
echo.

REM Test 3: Check Python is accessible
echo [TEST 3] Testing Python access...
python --version
if %errorlevel% neq 0 (
    echo FAILED: Python not accessible in virtual environment
    pause
    exit /b 1
)
echo PASSED: Python is accessible
echo.

REM Test 4: Check Odoo import
echo [TEST 4] Testing Odoo import...
python -c "import odoo; print('Odoo version:', odoo.release.version_info)"
if %errorlevel% neq 0 (
    echo FAILED: Could not import Odoo
    echo This usually means dependencies are not properly installed
    pause
    exit /b 1
)
echo PASSED: Odoo can be imported
echo.

REM Test 5: Check database connectivity
echo [TEST 5] Testing database import...
python -c "import psycopg2; print('psycopg2 version:', psycopg2.__version__)"
if %errorlevel% neq 0 (
    echo FAILED: Could not import psycopg2
    echo Database connectivity will not work
    pause
    exit /b 1
)
echo PASSED: Database adapter available
echo.

REM Test 6: Check configuration file
echo [TEST 6] Checking configuration file...
if not exist "odoo-prod.conf" (
    echo FAILED: Configuration file odoo-prod.conf not found
    pause
    exit /b 1
)
echo PASSED: Configuration file found
echo.

REM Test 7: Basic Odoo startup test (dry run)
echo [TEST 7] Testing Odoo startup (dry run)...
echo Running: python odoo-bin --help
python odoo-bin --help >nul 2>&1
if %errorlevel% neq 0 (
    echo FAILED: odoo-bin cannot execute
    echo Check if odoo-bin file exists and is accessible
    pause
    exit /b 1
)
echo PASSED: odoo-bin is executable
echo.

echo ====================================================================
echo                    ALL TESTS PASSED!
echo ====================================================================
echo.
echo Your Odoo environment is properly configured.
echo You should be able to start the production server with:
echo start-production.bat
echo.
echo If start-production.bat still closes immediately after this test passes,
echo the issue is likely in the startup sequence, not the environment setup.
echo.
pause