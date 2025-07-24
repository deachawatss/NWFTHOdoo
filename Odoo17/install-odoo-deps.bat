@echo off
echo ====================================================================
echo                  ODOO 17 DEPENDENCY INSTALLER
echo              Complete Setup: Environment + Dependencies
echo ====================================================================
echo.

cd /d "%~dp0"
echo Current directory: %CD%
echo.

REM Check Python installation
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python not found! Please install Python 3.10+ first.
    pause
    exit /b 1
)

echo Python version:
python --version
echo.

REM Remove old virtual environment if exists
if exist "odoo_env" (
    echo Removing old virtual environment...
    rmdir /s /q odoo_env >nul 2>&1
    timeout /t 2 /nobreak >nul
    if exist "odoo_env" (
        echo Force removing...
        attrib -r -h -s odoo_env\*.* /s /d >nul 2>&1
        del /f /s /q odoo_env\*.* >nul 2>&1
        rmdir /s /q odoo_env >nul 2>&1
    )
    echo Old environment removed.
)

REM Create fresh virtual environment
echo Creating new virtual environment...
python -m venv odoo_env --clear
if %errorlevel% neq 0 (
    echo ERROR: Failed to create virtual environment!
    pause
    exit /b 1
)

REM Activate virtual environment
echo Activating virtual environment...
call odoo_env\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ERROR: Failed to activate virtual environment!
    pause
    exit /b 1
)

REM Verify environment
echo Virtual environment activated:
python -c "import sys; print('Python executable:', sys.executable)"
echo.

REM Upgrade pip and wheel
echo Upgrading pip and wheel...
python -m pip install --upgrade pip wheel
echo.

REM Install critical Windows packages first
echo Installing Windows-specific packages...
pip install --only-binary=:all: psycopg2-binary lxml Pillow cryptography
echo.

REM Install all requirements (includes Windows LDAP support)
echo Installing Odoo dependencies with Windows LDAP support...
if exist "requirements.txt" (
    pip install -r requirements.txt
    if %errorlevel% neq 0 (
        echo WARNING: Some packages may have failed to install
        echo Continuing with available packages...
    )
) else (
    echo ERROR: requirements.txt not found!
    pause
    exit /b 1
)

REM Test critical imports
echo Testing critical imports...
python -c "import odoo; print('✓ Odoo import: OK')" 2>nul || echo "✗ Odoo import: FAILED"
python -c "import psycopg2; print('✓ PostgreSQL adapter: OK')" 2>nul || echo "✗ PostgreSQL adapter: FAILED"
python -c "import ldap3; print('✓ LDAP3 module: OK (Windows LDAP support)')" 2>nul || echo "✗ LDAP3 module: FAILED"
python -c "import ldap_compat; import ldap; print('✓ LDAP compatibility: OK (database restore ready)')" 2>nul || echo "✗ LDAP compatibility: FAILED"

echo.
echo ====================================================================
echo                    INSTALLATION COMPLETED!
echo ====================================================================
echo.
echo Your Odoo environment is ready!
echo.
echo Next steps:
echo 1. Start production server: start-production.bat
echo 2. Access at: http://localhost:8069
echo.
echo Simple workflow:
echo 1. git pull
echo 2. install-odoo-deps.bat (this script)
echo 3. start-production.bat
echo ====================================================================
echo.
pause