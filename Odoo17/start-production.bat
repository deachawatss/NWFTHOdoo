@echo off
echo ====================================================================
echo                  ODOO 17 PRODUCTION SERVER
echo              Optimized for 50 Concurrent Users
echo ====================================================================
echo.

REM Navigate to script directory
cd /d "%~dp0"

REM Create logs directory if needed
if not exist "logs" mkdir logs

REM Set UTF-8 encoding for Windows
chcp 65001 >nul
set PYTHONIOENCODING=utf-8
set PYTHONLEGACYWINDOWSSTDIO=1

REM Activate virtual environment
echo Activating virtual environment...
call odoo_env\Scripts\activate.bat

REM Show environment info
echo Virtual environment: ACTIVE
python --version
echo.

REM Start Odoo
echo Starting Odoo Production Server...
echo Configuration: odoo.conf
echo Workers: 10 (optimized for 50+ users)
echo URL: http://localhost:8069
echo Database Manager: http://localhost:8069/web/database/manager
echo Master Password: 1234 (admin/admin for database)
echo.
echo Press Ctrl+C to stop the server
echo.

REM Load LDAP compatibility and start Odoo
python odoo_ldap_patch.py && python odoo-bin -c odoo.conf

echo.
echo Odoo server stopped.
pause