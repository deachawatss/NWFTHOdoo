@echo off
echo ====================================================================
echo                  ODOO 17 PRODUCTION SERVER (SIMPLE)
echo ====================================================================
echo.

REM Navigate to script directory
cd /d "%~dp0"
echo Current directory: %CD%
echo.

REM Activate virtual environment
echo Activating virtual environment...
call odoo_env\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ERROR: Failed to activate virtual environment
    pause
    exit /b 1
)
echo Virtual environment activated successfully!
echo.

REM Show environment info
echo Python version:
python --version
echo.

echo Current Python executable:
python -c "import sys; print(sys.executable)"
echo.

echo Starting Odoo Production Server...
echo Configuration: odoo-prod.conf
echo Workers: 10 (optimized for 50+ users)
echo URL: http://localhost:8069
echo.
echo Press Ctrl+C to stop the server
echo.

REM Start Odoo with production configuration
python odoo-bin -c odoo-prod.conf --logfile=logs/odoo-prod.log

echo.
echo Odoo server stopped.
pause