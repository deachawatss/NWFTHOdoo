@echo off
echo ====================================================================
echo                    ENVIRONMENT DIAGNOSTICS
echo ====================================================================
echo.

cd /d "%~dp0"
echo Current working directory: %CD%
echo.

echo =========================
echo SYSTEM PYTHON CHECK
echo =========================
echo System Python version:
python --version
echo.
echo System Python executable:
python -c "import sys; print(sys.executable)"
echo.

echo =========================
echo VIRTUAL ENVIRONMENT CHECK
echo =========================
if exist "odoo_env" (
    echo Virtual environment folder exists: YES
    echo.
    
    if exist "odoo_env\Scripts\activate.bat" (
        echo Activate script exists: YES
        echo.
        echo Contents of activate.bat (first 10 lines):
        type odoo_env\Scripts\activate.bat | findstr /n ".*" | findstr "^[1-9]:"
        echo.
    ) else (
        echo Activate script exists: NO
        echo ERROR: activate.bat is missing!
    )
    
    if exist "odoo_env\Scripts\python.exe" (
        echo Python executable exists: YES
        echo Python executable location: odoo_env\Scripts\python.exe
    ) else (
        echo Python executable exists: NO
        echo ERROR: python.exe is missing from virtual environment!
    )
    
    echo.
    echo Virtual environment directory contents:
    dir odoo_env\Scripts\ /b
    echo.
    
) else (
    echo Virtual environment folder exists: NO
    echo ERROR: No virtual environment found!
)

echo =========================
echo ACTIVATION TEST
echo =========================
if exist "odoo_env\Scripts\activate.bat" (
    echo Attempting to activate virtual environment...
    call odoo_env\Scripts\activate.bat
    
    echo Testing Python after activation...
    python --version 2>&1
    echo.
    
    echo Testing Python executable path after activation...
    python -c "import sys; print('Executable:', sys.executable)" 2>&1
    echo.
) else (
    echo Cannot test activation - activate.bat missing
)

echo =========================
echo PATH ANALYSIS
echo =========================
echo Current PATH:
echo %PATH%
echo.

echo =========================
echo RECOMMENDATIONS
echo =========================
if exist "odoo_env" (
    echo 1. Virtual environment exists but may be corrupted
    echo 2. Run: fix-environment-complete.bat
    echo 3. If that fails, manually delete odoo_env folder
) else (
    echo 1. No virtual environment found
    echo 2. Run: fix-environment-complete.bat to create one
)
echo.

pause