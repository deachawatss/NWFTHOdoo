@echo off
echo Setting up Odoo 17 environment from scratch...

REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

echo Current directory: %CD%

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

REM Check if virtual environment activation script exists
if not exist "odoo_env\Scripts\activate.bat" (
    echo Virtual environment missing or corrupted. Recreating...
    if exist "odoo_env" (
        echo Removing corrupted virtual environment...
        rmdir /s /q odoo_env
    )
    echo Creating new virtual environment...
    python -m venv odoo_env
    if %errorlevel% neq 0 (
        echo ERROR: Failed to create virtual environment!
        pause
        exit /b 1
    )
    echo Virtual environment created successfully!
) else (
    echo Virtual environment exists and looks good.
)

REM Activate virtual environment
echo Activating virtual environment...
call odoo_env\Scripts\activate.bat

REM Verify we're in virtual environment
python -c "import sys; print('Virtual environment active:', sys.prefix)"

REM Upgrade pip and wheel
echo Upgrading pip and wheel...
python -m pip install --upgrade pip wheel

echo.
echo Environment setup complete!
echo Now running dependency installation...
echo.

REM Run the dependency installer
call install-odoo-deps.bat

echo.
echo Setup complete! You can now run:
echo   start-production.bat
pause