@echo off
echo ====================================================================
echo              FIX LDAP MODULE ERROR ON WINDOWS SERVER
echo        Solves: ModuleNotFoundError: No module named 'ldap'
echo ====================================================================
echo.

cd /d "%~dp0"

REM Activate virtual environment
echo Activating virtual environment...
call odoo_env\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ERROR: Virtual environment not found!
    echo Please run: install-odoo-deps.bat first
    pause
    exit /b 1
)

REM Install LDAP dependencies
echo Installing Windows LDAP support...
pip install ldap3
if %errorlevel% neq 0 (
    echo ERROR: Failed to install ldap3
    pause
    exit /b 1
)

REM Test LDAP compatibility
echo Testing LDAP compatibility layer...
python ldap_compat.py
if %errorlevel% neq 0 (
    echo ERROR: LDAP compatibility test failed
    pause
    exit /b 1
)

REM Test Odoo import with LDAP
echo Testing Odoo with LDAP support...
python -c "import ldap_compat; import odoo; print('✓ Odoo with LDAP: SUCCESS')"
if %errorlevel% neq 0 (
    echo ERROR: Odoo LDAP integration test failed
    pause
    exit /b 1
)

echo.
echo ====================================================================
echo                    LDAP FIX COMPLETED!
echo ====================================================================
echo.
echo ✅ LDAP compatibility layer installed
echo ✅ ldap3 module installed  
echo ✅ Odoo LDAP integration tested
echo.
echo Your Odoo server should now start without LDAP errors!
echo.
echo Next step: start-production.bat
echo ====================================================================
echo.
pause