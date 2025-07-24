@echo off
REM ====================================================================
REM Odoo 17 Windows Service Installation Script
REM Installs Odoo as a Windows service for production deployment
REM Requires: NSSM (Non-Sucking Service Manager)
REM ====================================================================

setlocal enabledelayedexpansion

REM ====================================
REM ADMINISTRATOR PRIVILEGE CHECK
REM ====================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ========================================
    echo        ADMINISTRATOR PRIVILEGES REQUIRED
    echo ========================================
    echo This script must be run as Administrator to install Windows services.
    echo.
    echo Please:
    echo 1. Right-click on this file
    echo 2. Select "Run as administrator"
    echo 3. Click "Yes" when prompted
    echo ========================================
    pause
    exit /b 1
)

REM ====================================
REM COLOR CODES FOR WINDOWS CONSOLE
REM ====================================
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "CYAN=[96m"
set "MAGENTA=[95m"
set "NC=[0m"

REM ====================================
REM SERVICE CONFIGURATION
REM ====================================
set "SERVICE_NAME=Odoo17Production"
set "SERVICE_DISPLAY_NAME=Odoo 17 Production Server"
set "SERVICE_DESCRIPTION=Odoo 17 ERP Production Server for 50 concurrent users"
set "NSSM_URL=https://nssm.cc/download"
set "NSSM_FILENAME=nssm-2.24.zip"

REM ====================================
REM LOGGING FUNCTIONS
REM ====================================
:log_info
echo %GREEN%[%date% %time%] INFO: %~1%NC%
echo [%date% %time%] INFO: %~1 >> logs\service-install.log
exit /b

:log_error
echo %RED%[%date% %time%] ERROR: %~1%NC%
echo [%date% %time%] ERROR: %~1 >> logs\service-install.log
exit /b

:log_warning
echo %YELLOW%[%date% %time%] WARNING: %~1%NC%
echo [%date% %time%] WARNING: %~1 >> logs\service-install.log
exit /b

:log_success
echo %CYAN%[%date% %time%] SUCCESS: %~1%NC%
echo [%date% %time%] SUCCESS: %~1 >> logs\service-install.log
exit /b

REM ====================================
REM SERVICE INSTALLATION HEADER
REM ====================================
cls
echo %BLUE%
echo ====================================================================
echo                 ODOO 17 WINDOWS SERVICE INSTALLER
echo                      Production Service Setup
echo ====================================================================
echo Service Name: %SERVICE_NAME%
echo Display Name: %SERVICE_DISPLAY_NAME%
echo Target Users: 50 concurrent
echo Service Manager: NSSM (Non-Sucking Service Manager)
echo ====================================================================
echo %NC%

REM Navigate to script directory
cd /d "%~dp0"

REM Create logs directory if it doesn't exist
if not exist "logs" mkdir logs

call :log_info "Starting Windows service installation..."

REM ====================================
REM ENVIRONMENT VALIDATION
REM ====================================
call :log_info "Validating environment..."

REM Check if required files exist
if not exist "odoo-bin" (
    call :log_error "odoo-bin not found! Please ensure you're in the correct Odoo directory."
    pause
    exit /b 1
)

if not exist "odoo-prod.conf" (
    call :log_error "Production configuration file 'odoo-prod.conf' not found!"
    pause
    exit /b 1
)

if not exist "odoo_env" (
    call :log_error "Python virtual environment 'odoo_env' not found!"
    pause
    exit /b 1
)

call :log_success "Environment validation completed"

REM ====================================
REM CHECK FOR EXISTING SERVICE
REM ====================================
call :log_info "Checking for existing service..."

sc query "%SERVICE_NAME%" >nul 2>&1
if !errorlevel! equ 0 (
    call :log_warning "Service '%SERVICE_NAME%' already exists!"
    echo.
    echo %YELLOW%The service already exists. What would you like to do?%NC%
    echo 1. Remove existing service and reinstall
    echo 2. Update existing service configuration
    echo 3. Cancel installation
    echo.
    set /p choice="Enter your choice (1-3): "
    
    if "!choice!"=="1" (
        call :log_info "Removing existing service..."
        goto :remove_existing_service
    ) else if "!choice!"=="2" (
        call :log_info "Updating existing service..."
        goto :update_service
    ) else (
        call :log_info "Installation cancelled by user"
        pause
        exit /b 0
    )
)

REM ====================================
REM NSSM INSTALLATION CHECK
REM ====================================
:check_nssm
call :log_info "Checking for NSSM (Non-Sucking Service Manager)..."

where nssm >nul 2>&1
if !errorlevel! neq 0 (
    call :log_warning "NSSM not found in PATH"
    
    REM Check if NSSM exists in current directory
    if exist "nssm.exe" (
        call :log_info "Found NSSM in current directory"
        set "NSSM_PATH=%CD%\nssm.exe"
    ) else (
        call :log_error "NSSM not found!"
        echo.
        echo %YELLOW%NSSM (Non-Sucking Service Manager) is required to install Odoo as a Windows service.%NC%
        echo.
        echo %CYAN%Please:
        echo 1. Download NSSM from: %NSSM_URL%
        echo 2. Extract nssm.exe to this directory, OR
        echo 3. Add NSSM to your system PATH%NC%
        echo.
        echo %GREEN%Would you like to download NSSM automatically? (Y/N)%NC%
        set /p download_choice="Enter choice: "
        
        if /i "!download_choice!"=="Y" (
            goto :download_nssm
        ) else (
            call :log_error "NSSM installation cancelled by user"
            pause
            exit /b 1
        )
    )
) else (
    call :log_success "NSSM found in system PATH"
    set "NSSM_PATH=nssm"
)

goto :install_service

REM ====================================
REM DOWNLOAD NSSM
REM ====================================
:download_nssm
call :log_info "Downloading NSSM..."

REM Use PowerShell to download NSSM
powershell -Command "try { Invoke-WebRequest -Uri 'https://nssm.cc/release/nssm-2.24.zip' -OutFile 'nssm-temp.zip' -UseBasicParsing; Write-Host 'SUCCESS' } catch { Write-Host 'FAILED' }" > temp_download.txt
set /p DOWNLOAD_RESULT=<temp_download.txt
del temp_download.txt

if "%DOWNLOAD_RESULT%"=="FAILED" (
    call :log_error "Failed to download NSSM automatically"
    call :log_error "Please download manually from: %NSSM_URL%"
    pause
    exit /b 1
)

call :log_info "Extracting NSSM..."
powershell -Command "Expand-Archive -Path 'nssm-temp.zip' -DestinationPath 'nssm-temp' -Force"

REM Copy the appropriate NSSM binary
if exist "nssm-temp\nssm-2.24\win64\nssm.exe" (
    copy "nssm-temp\nssm-2.24\win64\nssm.exe" "nssm.exe" >nul
) else if exist "nssm-temp\nssm-2.24\win32\nssm.exe" (
    copy "nssm-temp\nssm-2.24\win32\nssm.exe" "nssm.exe" >nul
) else (
    call :log_error "Failed to extract NSSM binary"
    pause
    exit /b 1
)

REM Cleanup
rmdir /s /q "nssm-temp" >nul 2>&1
del "nssm-temp.zip" >nul 2>&1

set "NSSM_PATH=%CD%\nssm.exe"
call :log_success "NSSM downloaded and extracted successfully"

REM ====================================
REM REMOVE EXISTING SERVICE
REM ====================================
:remove_existing_service
call :log_info "Stopping existing service..."
net stop "%SERVICE_NAME%" >nul 2>&1

call :log_info "Removing existing service..."
"%NSSM_PATH%" remove "%SERVICE_NAME%" confirm >nul 2>&1
if !errorlevel! equ 0 (
    call :log_success "Existing service removed successfully"
) else (
    call :log_warning "Failed to remove existing service or service didn't exist"
)

REM ====================================
REM INSTALL NEW SERVICE
REM ====================================
:install_service
call :log_info "Installing Odoo as Windows service..."

REM Get full paths
set "CURRENT_DIR=%CD%"
set "PYTHON_EXE=%CURRENT_DIR%\odoo_env\Scripts\python.exe"
set "ODOO_BIN=%CURRENT_DIR%\odoo-bin"
set "CONFIG_FILE=%CURRENT_DIR%\odoo-prod.conf"

REM Verify Python executable exists
if not exist "%PYTHON_EXE%" (
    call :log_error "Python executable not found at: %PYTHON_EXE%"
    pause
    exit /b 1
)

REM Install service
call :log_info "Creating service with NSSM..."
"%NSSM_PATH%" install "%SERVICE_NAME%" "%PYTHON_EXE%" "%ODOO_BIN%" -c "%CONFIG_FILE%"

if !errorlevel! neq 0 (
    call :log_error "Failed to install service!"
    pause
    exit /b 1
)

call :log_success "Service installed successfully"

REM ====================================
REM CONFIGURE SERVICE PARAMETERS
REM ====================================
:update_service
call :log_info "Configuring service parameters..."

REM Set service display name and description
"%NSSM_PATH%" set "%SERVICE_NAME%" DisplayName "%SERVICE_DISPLAY_NAME%"
"%NSSM_PATH%" set "%SERVICE_NAME%" Description "%SERVICE_DESCRIPTION%"

REM Set startup directory
"%NSSM_PATH%" set "%SERVICE_NAME%" AppDirectory "%CURRENT_DIR%"

REM Set service to start automatically
"%NSSM_PATH%" set "%SERVICE_NAME%" Start SERVICE_AUTO_START

REM Configure service recovery
"%NSSM_PATH%" set "%SERVICE_NAME%" AppRestartDelay 30000
"%NSSM_PATH%" set "%SERVICE_NAME%" AppStopMethodSkip 0
"%NSSM_PATH%" set "%SERVICE_NAME%" AppStopMethodConsole 30000
"%NSSM_PATH%" set "%SERVICE_NAME%" AppStopMethodWindow 30000
"%NSSM_PATH%" set "%SERVICE_NAME%" AppStopMethodThreads 30000

REM Set log files
"%NSSM_PATH%" set "%SERVICE_NAME%" AppStdout "%CURRENT_DIR%\logs\service-stdout.log"
"%NSSM_PATH%" set "%SERVICE_NAME%" AppStderr "%CURRENT_DIR%\logs\service-stderr.log"

REM Set log rotation
"%NSSM_PATH%" set "%SERVICE_NAME%" AppRotateFiles 1
"%NSSM_PATH%" set "%SERVICE_NAME%" AppRotateOnline 1
"%NSSM_PATH%" set "%SERVICE_NAME%" AppRotateSeconds 86400
"%NSSM_PATH%" set "%SERVICE_NAME%" AppRotateBytes 1048576

call :log_success "Service configuration completed"

REM ====================================
REM START SERVICE
REM ====================================
call :log_info "Starting service..."

net start "%SERVICE_NAME%"
if !errorlevel! equ 0 (
    call :log_success "Service started successfully"
) else (
    call :log_error "Failed to start service. Check logs for details."
    goto :installation_summary
)

REM Wait for service to initialize
call :log_info "Waiting for service initialization..."
timeout /t 15 >nul

REM ====================================
REM SERVICE HEALTH CHECK
REM ====================================
call :log_info "Performing service health check..."

REM Check service status
sc query "%SERVICE_NAME%" | find "STATE" | find "RUNNING" >nul
if !errorlevel! equ 0 (
    call :log_success "Service is running"
) else (
    call :log_warning "Service is not running as expected"
)

REM Check web server response
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://localhost:8069/web/health' -TimeoutSec 10 -UseBasicParsing; if($response.StatusCode -eq 200) { Write-Host 'HEALTHY' } else { Write-Host 'UNHEALTHY' } } catch { Write-Host 'UNREACHABLE' }" > temp_service_health.txt
set /p SERVICE_HEALTH=<temp_service_health.txt
del temp_service_health.txt

call :log_info "Service health status: %SERVICE_HEALTH%"

REM ====================================
REM INSTALLATION SUMMARY
REM ====================================
:installation_summary
echo.
echo %CYAN%====================================================================
echo                     SERVICE INSTALLATION COMPLETE
echo ====================================================================
echo Service Name: %SERVICE_NAME%
echo Display Name: %SERVICE_DISPLAY_NAME%
echo Status: %SERVICE_HEALTH%
echo Configuration: %CONFIG_FILE%
echo ====================================================================
echo Service Management Commands:
echo - Start:   net start "%SERVICE_NAME%"
echo - Stop:    net stop "%SERVICE_NAME%"
echo - Restart: net stop "%SERVICE_NAME%" ^&^& net start "%SERVICE_NAME%"
echo - Remove:  nssm remove "%SERVICE_NAME%" confirm
echo ====================================================================
echo Access Points:
echo - Main Application: http://localhost:8069
echo - Live Chat: http://localhost:8072
echo - Health Check: http://localhost:8069/web/health
echo ====================================================================
echo Log Files:
echo - Service Output: logs\service-stdout.log
echo - Service Errors: logs\service-stderr.log
echo - Application: logs\odoo-prod.log
echo - Installation: logs\service-install.log
echo ====================================================================
echo %NC%

if "%SERVICE_HEALTH%"=="HEALTHY" (
    echo %GREEN%✓ Installation successful! Service is running and healthy.%NC%
    call :log_success "Service installation completed successfully"
) else (
    echo %YELLOW%⚠ Installation completed but service health check failed.%NC%
    echo %YELLOW%  Please check the log files for troubleshooting.%NC%
    call :log_warning "Service installed but health check failed"
)

echo.
echo %CYAN%Additional Notes:
echo - Service will start automatically with Windows
echo - Service will auto-restart on failure
echo - Logs are rotated daily to prevent disk space issues
echo - Use Windows Services Manager for advanced configuration%NC%
echo.

pause