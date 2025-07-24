@echo off
echo ====================================================================
echo           COMPLETE VIRTUAL ENVIRONMENT REBUILD
echo ====================================================================
echo.

REM Navigate to script directory
cd /d "%~dp0"
echo Current directory: %CD%
echo.

echo Step 1: Killing all Python processes...
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im pythonw.exe >nul 2>&1
timeout /t 2 /nobreak >nul
echo Done.
echo.

echo Step 2: Completely removing virtual environment...
if exist "odoo_env" (
    echo Removing all attributes...
    attrib -r -h -s odoo_env\*.* /s /d >nul 2>&1
    
    echo Deleting all files forcefully...
    del /f /s /q odoo_env\*.* >nul 2>&1
    
    echo Removing directories...
    for /d %%i in (odoo_env\*) do rmdir /s /q "%%i" >nul 2>&1
    rmdir /s /q odoo_env >nul 2>&1
    
    REM Wait and try again
    timeout /t 3 /nobreak >nul
    if exist "odoo_env" (
        echo Forcing removal with takeown...
        takeown /f odoo_env /r /d y >nul 2>&1
        icacls odoo_env /grant %USERNAME%:F /t >nul 2>&1
        rmdir /s /q odoo_env >nul 2>&1
    )
    
    if exist "odoo_env" (
        echo ERROR: Cannot remove virtual environment
        echo Please manually delete the odoo_env folder:
        echo 1. Close all Command Prompt windows
        echo 2. Open File Explorer and navigate to: %CD%
        echo 3. Delete the odoo_env folder manually
        echo 4. Run this script again
        pause
        exit /b 1
    )
    
    echo Virtual environment removed successfully!
) else (
    echo No virtual environment found.
)
echo.

echo Step 3: Verifying Python installation...
python --version
if %errorlevel% neq 0 (
    echo ERROR: Python not found in system PATH
    echo Please install Python 3.10+ and add it to PATH
    pause
    exit /b 1
)
echo Python found and accessible.
echo.

echo Step 4: Creating fresh virtual environment...
echo Running: python -m venv odoo_env --clear --copies
python -m venv odoo_env --clear --copies
if %errorlevel% neq 0 (
    echo ERROR: Failed to create virtual environment
    echo Try running as Administrator
    pause
    exit /b 1
)
echo Virtual environment created successfully!
echo.

echo Step 5: Testing activation manually...
if not exist "odoo_env\Scripts\activate.bat" (
    echo ERROR: activate.bat not created properly
    echo Virtual environment creation failed
    pause
    exit /b 1
)

echo Testing activation script...
call odoo_env\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ERROR: Cannot activate virtual environment
    pause
    exit /b 1
)
echo Activation successful!
echo.

echo Step 6: Verifying Python executable path...
python -c "import sys; print('Python executable:', sys.executable)"
if %errorlevel% neq 0 (
    echo ERROR: Python still not working in virtual environment
    pause
    exit /b 1
)
echo Python executable verified!
echo.

echo Step 7: Installing basic packages...
python -m pip install --upgrade pip
python -m pip install wheel setuptools
echo Basic packages installed.
echo.

echo ====================================================================
echo                 ENVIRONMENT REBUILT SUCCESSFULLY!
echo ====================================================================
echo.
echo Next steps:
echo 1. Run: install-odoo-deps.bat
echo 2. Run: test-odoo-start.bat
echo 3. Run: start-production-simple.bat
echo.
pause