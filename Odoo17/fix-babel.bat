@echo off
echo Fixing Babel for Python 3.13 compatibility...

REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

echo Current directory: %CD%

REM Activate virtual environment
if not exist "odoo_env\Scripts\activate.bat" (
    echo ERROR: Virtual environment not found!
    pause
    exit /b 1
)

echo Activating virtual environment...
call odoo_env\Scripts\activate.bat

REM Force uninstall old Babel
echo Uninstalling old Babel version...
pip uninstall -y Babel

REM Install Python 3.13 compatible Babel
echo Installing Babel 2.14.0+ for Python 3.13...
pip install "Babel>=2.14.0"

REM Test Odoo import
echo Testing Odoo import...
python -c "import odoo; print('Odoo import OK - Babel fixed!')"

if %errorlevel% neq 0 (
    echo ERROR: Odoo import still failed!
    pause
    exit /b 1
)

echo.
echo SUCCESS: Babel has been upgraded and Odoo import works!
echo You can now run: start-production.bat
pause