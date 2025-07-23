@echo off
REM ====================================================
REM   Odoo 17 Windows Environment Setup Script
REM   Run this ONCE before first use
REM ====================================================

setlocal enabledelayedexpansion

REM Set colors for output
set GREEN=[92m
set RED=[91m
set YELLOW=[93m
set BLUE=[94m
set NC=[0m

echo %BLUE%======================================================%NC%
echo %BLUE%       Odoo 17 Windows Environment Setup%NC%
echo %BLUE%       This will prepare your environment for first use%NC%
echo %BLUE%       Time: %date% %time%%NC%
echo %BLUE%======================================================%NC%
echo.

REM Navigate to the script directory
cd /d "%~dp0"

REM Step 1: Validate Python installation
echo %GREEN%[%time%] Step 1: Validating Python installation...%NC%

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%ERROR: Python is not installed or not in PATH!%NC%
    echo Please install Python 3.11+ from https://python.org
    echo Make sure to check "Add Python to PATH" during installation.
    pause
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo %GREEN%[%time%] Python %PYTHON_VERSION% found.%NC%

REM Check Python version (should be 3.11+)
python -c "import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)" >nul 2>&1
if %errorlevel% neq 0 (
    echo %YELLOW%WARNING: Python version may be too old. Odoo 17 requires Python 3.11+%NC%
    echo Current version: %PYTHON_VERSION%
    echo Continue anyway? (Y/N)
    set /p continue=
    if /i not "!continue!"=="Y" exit /b 1
)

REM Step 2: Check pip installation
echo %GREEN%[%time%] Step 2: Checking pip installation...%NC%

python -m pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%ERROR: pip is not available!%NC%
    echo Please reinstall Python with pip included.
    pause
    exit /b 1
)

echo %GREEN%[%time%] pip is available.%NC%

REM Step 3: Create/validate virtual environment
echo %GREEN%[%time%] Step 3: Setting up virtual environment...%NC%

if not exist "odoo_env" (
    echo %GREEN%[%time%] Creating new virtual environment...%NC%
    python -m venv odoo_env
    if %errorlevel% neq 0 (
        echo %RED%ERROR: Failed to create virtual environment!%NC%
        pause
        exit /b 1
    )
    echo %GREEN%[%time%] Virtual environment created successfully.%NC%
) else (
    echo %GREEN%[%time%] Virtual environment already exists.%NC%
)

REM Step 4: Activate virtual environment
echo %GREEN%[%time%] Step 4: Activating virtual environment...%NC%

call odoo_env\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo %RED%ERROR: Failed to activate virtual environment!%NC%
    pause
    exit /b 1
)

echo %GREEN%[%time%] Virtual environment activated.%NC%

REM Step 5: Upgrade pip and install dependencies
echo %GREEN%[%time%] Step 5: Installing/updating dependencies...%NC%

echo %GREEN%[%time%] Upgrading pip...%NC%
python -m pip install --upgrade pip
if %errorlevel% neq 0 (
    echo %YELLOW%WARNING: Failed to upgrade pip, continuing...%NC%
)

echo %GREEN%[%time%] Installing Odoo dependencies from requirements.txt...%NC%
if exist "requirements.txt" (
    pip install -r requirements.txt
    if %errorlevel% neq 0 (
        echo %RED%ERROR: Failed to install requirements!%NC%
        echo Please check your internet connection and try again.
        pause
        exit /b 1
    )
    echo %GREEN%[%time%] Dependencies installed successfully.%NC%
) else (
    echo %YELLOW%WARNING: requirements.txt not found!%NC%
    echo Installing basic Odoo dependencies...
    pip install odoo
    if %errorlevel% neq 0 (
        echo %RED%ERROR: Failed to install Odoo!%NC%
        pause
        exit /b 1
    )
)

REM Step 6: Create necessary directories
echo %GREEN%[%time%] Step 6: Creating necessary directories...%NC%

if not exist "logs" (
    mkdir logs
    echo %GREEN%[%time%] Created logs directory.%NC%
)

if not exist "data" (
    mkdir data
    echo %GREEN%[%time%] Created data directory.%NC%
)

if not exist "data\filestore" (
    mkdir data\filestore
    echo %GREEN%[%time%] Created filestore directory.%NC%
)

if not exist "data\sessions" (
    mkdir data\sessions
    echo %GREEN%[%time%] Created sessions directory.%NC%
)

REM Step 7: Validate Odoo installation
echo %GREEN%[%time%] Step 7: Validating Odoo installation...%NC%

python -c "import odoo; print('Odoo version:', odoo.release.version)" >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%ERROR: Odoo package validation failed!%NC%
    echo Please check the installation and try again.
    pause
    exit /b 1
)

for /f "tokens=3" %%i in ('python -c "import odoo; print('Version:', odoo.release.version)" 2^>^&1') do set ODOO_VERSION=%%i
echo %GREEN%[%time%] Odoo %ODOO_VERSION% validated successfully.%NC%

REM Step 8: Test database connectivity (optional)
echo %GREEN%[%time%] Step 8: Testing database connectivity...%NC%

REM Check if psycopg2 is available (database connector)
python -c "import psycopg2" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[%time%] PostgreSQL connector (psycopg2) is available.%NC%
    
    REM Try to connect to database
    python -c "import psycopg2; psycopg2.connect(host='localhost', port=5432, user='odoo_prod', password='OdooSecure2024!', database='postgres')" >nul 2>&1
    if %errorlevel% equ 0 (
        echo %GREEN%[%time%] Database connection test passed!%NC%
    ) else (
        echo %YELLOW%WARNING: Database connection test failed.%NC%
        echo Please ensure PostgreSQL is running and odoo_prod user exists.
        echo You can run 'setup-database.bat' to set up the database.
    )
) else (
    echo %YELLOW%WARNING: PostgreSQL connector not found.%NC%
    echo Installing psycopg2-binary...
    pip install psycopg2-binary
)

REM Step 9: Final validation
echo %GREEN%[%time%] Step 9: Final environment validation...%NC%

REM Check all required files
set VALIDATION_PASSED=true

if not exist "odoo-bin" (
    echo %RED%ERROR: odoo-bin not found!%NC%
    set VALIDATION_PASSED=false
)

if not exist "odoo-windows.conf" (
    echo %RED%ERROR: odoo-windows.conf not found!%NC%
    set VALIDATION_PASSED=false
)

if not exist "addons" (
    echo %RED%ERROR: addons directory not found!%NC%
    set VALIDATION_PASSED=false
)

if not exist "odoo_env\Scripts\python.exe" (
    echo %RED%ERROR: Virtual environment Python not found!%NC%
    set VALIDATION_PASSED=false
)

if "!VALIDATION_PASSED!"=="false" (
    echo %RED%Environment validation failed! Please fix the errors above.%NC%
    pause
    exit /b 1
)

REM Step 10: Success message
echo.
echo %BLUE%======================================================%NC%
echo %BLUE%       Environment Setup Complete!%NC%
echo %BLUE%======================================================%NC%
echo %GREEN%✓ Python %PYTHON_VERSION% validated%NC%
echo %GREEN%✓ Virtual environment created/validated%NC%
echo %GREEN%✓ Dependencies installed%NC%
echo %GREEN%✓ Directories created%NC%
echo %GREEN%✓ Odoo %ODOO_VERSION% validated%NC%
echo %GREEN%✓ Environment ready for use%NC%
echo.
echo %BLUE%Next Steps:%NC%
echo %BLUE%1. Ensure PostgreSQL is running with odoo_prod database%NC%
echo %BLUE%2. Run 'setup-database.bat' if database setup is needed%NC%
echo %BLUE%3. Double-click 'start-odoo-windows.bat' to start Odoo%NC%
echo %BLUE%4. Open browser to http://192.168.0.21:8069%NC%
echo %BLUE%5. Login with admin/AdminSecure2024!%NC%
echo.
echo %BLUE%======================================================%NC%

echo Press any key to continue...
pause >nul