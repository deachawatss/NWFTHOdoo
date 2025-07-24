@echo off
echo ====================================================================
echo                 ODOO 17 WINDOWS ENVIRONMENT SETUP
echo                  Production Server Configuration
echo ====================================================================
echo.

REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

echo Current directory: %CD%
echo.

REM Check if Python is available
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python not found! Please install Python 3.10+ first.
    echo Download from: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Show Python version
echo Python version:
python --version

echo Step 1: Setting up Python virtual environment...
echo.

REM Always recreate virtual environment to ensure it's clean and Windows-compatible
if exist "odoo_env" (
    echo Removing existing virtual environment...
    echo (This ensures compatibility and prevents WSL2/Linux conflicts)
    
    REM Force remove with multiple attempts to handle file locks
    rmdir /s /q odoo_env 2>nul
    timeout /t 2 /nobreak >nul
    
    REM Verify removal and force if needed
    if exist "odoo_env" (
        echo Forcing removal of stubborn files...
        attrib -r -h -s odoo_env\*.* /s /d >nul 2>&1
        del /f /s /q odoo_env\*.* >nul 2>&1
        rmdir /s /q odoo_env >nul 2>&1
    )
    
    REM Final check
    if exist "odoo_env" (
        echo WARNING: Could not completely remove old environment
        echo Attempting to work around the issue...
    ) else (
        echo Removed successfully!
    )
)

echo Creating new Windows virtual environment...
python -m venv odoo_env
if %errorlevel% neq 0 (
    echo ERROR: Failed to create virtual environment!
    echo Make sure Python 3.10+ is properly installed.
    pause
    exit /b 1
)
echo Virtual environment created successfully!
echo.

echo Step 2: Testing virtual environment...
call odoo_env\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ERROR: Failed to activate virtual environment!
    pause
    exit /b 1
)

python -c "import sys; print('Python version:', sys.version_info[:2]); print('Virtual environment test: SUCCESS')"
if %errorlevel% neq 0 (
    echo ERROR: Virtual environment test failed!
    pause
    exit /b 1
)
echo Virtual environment is working correctly!
echo.

REM Activate virtual environment
echo Activating virtual environment...
call odoo_env\Scripts\activate.bat

REM Verify we're in virtual environment
python -c "import sys; print('Virtual environment active:', sys.prefix)"

REM Upgrade pip and wheel
echo Upgrading pip and wheel...
python -m pip install --upgrade pip wheel

echo.
echo Step 3: Installing Odoo dependencies...
echo.

REM Run the dependency installer
call install-odoo-deps.bat

echo.
echo ====================================================================
echo                    SETUP COMPLETED SUCCESSFULLY!
echo ====================================================================
echo.
echo Next steps:
echo 1. Ensure PostgreSQL 17 is running with admin/1234 credentials
echo 2. Run: start-production.bat
echo 3. Access your server at: http://192.168.0.21:8069
echo.
echo Database Manager: http://192.168.0.21:8069/web/database/manager
echo Master Password: 1234
echo ====================================================================
pause