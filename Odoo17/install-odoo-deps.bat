@echo off
echo Installing Odoo dependencies for Windows...

REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

echo Current directory: %CD%

REM Check if we have the virtual environment
if not exist "odoo_env\Scripts\activate.bat" (
    echo ERROR: Virtual environment not found at odoo_env\Scripts\activate.bat
    echo Please make sure you're running this from the Odoo17 directory
    pause
    exit /b 1
)

REM Activate virtual environment
echo Activating virtual environment...
call odoo_env\Scripts\activate.bat

REM Verify we're in the virtual environment
python -c "import sys; print('Python path:', sys.executable)"

REM Upgrade pip and wheel in the virtual environment
echo Upgrading pip and wheel...
python -m pip install --upgrade pip wheel

REM Install lxml with correct version and binary-only
echo Installing lxml 5.3.0 (binary wheel only)...
pip install --only-binary=:all: lxml==5.3.0

REM Install psycopg2-binary first with correct version for Python 3.13
echo Installing psycopg2-binary for Python 3.13...
pip install --only-binary=:all: "psycopg2-binary>=2.9.10"

REM Force upgrade Babel for Python 3.13 compatibility
echo Checking Python version for Babel compatibility...
python -c "import sys; exit(0 if sys.version_info >= (3, 13) else 1)" >nul 2>&1
if %errorlevel% equ 0 (
    echo Python 3.13+ detected - upgrading Babel for compatibility...
    pip install --upgrade --force-reinstall "Babel==2.16.0"
)

REM Install other problematic packages
echo Installing other binary packages...
pip install --only-binary=:all: Pillow cryptography

REM Install remaining requirements
echo Installing remaining requirements...
if exist "requirements.txt" (
    pip install -r requirements.txt
) else (
    echo ERROR: requirements.txt not found in current directory
    pause
    exit /b 1
)

echo.
echo Installation completed successfully!
echo You can now start Odoo with: python odoo-bin -c odoo-dev.conf
pause