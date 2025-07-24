@echo off
echo ====================================================================
echo           FIXING CORRUPTED VIRTUAL ENVIRONMENT
echo ====================================================================
echo.

REM Navigate to script directory
cd /d "%~dp0"
echo Current directory: %CD%
echo.

echo Step 1: Stopping any Python processes...
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im pythonw.exe >nul 2>&1
echo Done.
echo.

echo Step 2: Force removing corrupted virtual environment...
if exist "odoo_env" (
    echo Removing file attributes...
    attrib -r -h -s odoo_env\*.* /s /d >nul 2>&1
    
    echo Deleting all files...
    del /f /s /q odoo_env\*.* >nul 2>&1
    
    echo Removing directory structure...
    rmdir /s /q odoo_env >nul 2>&1
    timeout /t 3 /nobreak >nul
    
    REM Try again if it still exists
    if exist "odoo_env" (
        echo Trying alternative removal method...
        rd /s /q odoo_env >nul 2>&1
    )
    
    if exist "odoo_env" (
        echo ERROR: Cannot remove virtual environment directory
        echo Please manually delete the odoo_env folder and try again
        pause
        exit /b 1
    )
    
    echo Virtual environment removed successfully!
) else (
    echo No virtual environment found to remove.
)
echo.

echo Step 3: Creating fresh Windows virtual environment...
python -m venv odoo_env --clear
if %errorlevel% neq 0 (
    echo ERROR: Failed to create virtual environment!
    echo Please check that Python 3.10+ is properly installed
    pause
    exit /b 1
)
echo Virtual environment created successfully!
echo.

echo Step 4: Testing new virtual environment...
call odoo_env\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ERROR: Failed to activate virtual environment!
    pause
    exit /b 1
)

python -c "import sys; print('Python executable:', sys.executable); print('SUCCESS: Virtual environment is working!')"
if %errorlevel% neq 0 (
    echo ERROR: Virtual environment test failed!
    pause
    exit /b 1
)
echo.

echo Step 5: Installing basic packages...
python -m pip install --upgrade pip wheel
echo.

echo ====================================================================
echo                   ENVIRONMENT FIXED SUCCESSFULLY!
echo ====================================================================
echo.
echo Next steps:
echo 1. Run: install-odoo-deps.bat (to install Odoo dependencies)
echo 2. Run: test-odoo-start.bat (to verify everything works)
echo 3. Run: start-production.bat (to start your server)
echo.
pause