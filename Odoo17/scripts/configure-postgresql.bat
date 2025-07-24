@echo off
REM ====================================================================
REM PostgreSQL 17 Windows Production Configuration Script
REM Optimizes PostgreSQL for Odoo 17 with 50 concurrent users
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
    echo This script must be run as Administrator to configure PostgreSQL.
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
set "NC=[0m"

REM ====================================
REM CONFIGURATION HEADER
REM ====================================
cls
echo %BLUE%
echo ====================================================================
echo           POSTGRESQL 17 WINDOWS PRODUCTION CONFIGURATOR
echo                  Optimized for Odoo 17 - 50 Users
echo ====================================================================
echo Target: 50 concurrent users
echo Database: PostgreSQL 17
echo Platform: Windows Server
echo Optimization: Production grade
echo ====================================================================
echo %NC%

REM Navigate to parent directory (from scripts to main)
cd /d "%~dp0\.."

REM ====================================
REM LOGGING FUNCTIONS
REM ====================================
:log_info
echo %GREEN%[%date% %time%] INFO: %~1%NC%
echo [%date% %time%] INFO: %~1 >> logs\postgresql-config.log
exit /b

:log_error
echo %RED%[%date% %time%] ERROR: %~1%NC%
echo [%date% %time%] ERROR: %~1 >> logs\postgresql-config.log
exit /b

:log_warning
echo %YELLOW%[%date% %time%] WARNING: %~1%NC%
echo [%date% %time%] WARNING: %~1 >> logs\postgresql-config.log
exit /b

:log_success
echo %CYAN%[%date% %time%] SUCCESS: %~1%NC%
echo [%date% %time%] SUCCESS: %~1 >> logs\postgresql-config.log
exit /b

REM Ensure logs directory exists
if not exist "logs" mkdir logs

call :log_info "Starting PostgreSQL 17 production configuration..."

REM ====================================
REM POSTGRESQL DISCOVERY
REM ====================================
call :log_info "Discovering PostgreSQL 17 installation..."

REM Common PostgreSQL installation paths
set "PG_PATHS[0]=C:\Program Files\PostgreSQL\17"
set "PG_PATHS[1]=C:\Program Files\PostgreSQL\16"
set "PG_PATHS[2]=C:\Program Files (x86)\PostgreSQL\17"
set "PG_PATHS[3]=C:\PostgreSQL\17"
set "PG_PATHS[4]=D:\Program Files\PostgreSQL\17"

set "PG_FOUND=FALSE"
set "PG_DATA_DIR="
set "PG_CONFIG_FILE="
set "PG_HBA_FILE="

for /l %%i in (0,1,4) do (
    if exist "!PG_PATHS[%%i]!\bin\pg_ctl.exe" (
        set "PG_HOME=!PG_PATHS[%%i]!"
        set "PG_FOUND=TRUE"
        call :log_success "PostgreSQL found at: !PG_HOME!"
        goto :pg_found
    )
)

:pg_found
if "%PG_FOUND%"=="FALSE" (
    call :log_error "PostgreSQL 17 installation not found!"
    echo %RED%PostgreSQL 17 not found in standard locations.%NC%
    echo %YELLOW%Please ensure PostgreSQL 17 is installed and try again.%NC%
    echo.
    echo %CYAN%Standard installation paths checked:%NC%
    for /l %%i in (0,1,4) do echo   - !PG_PATHS[%%i]!
    pause
    exit /b 1
)

REM ====================================
REM POSTGRESQL DATA DIRECTORY DISCOVERY
REM ====================================
call :log_info "Locating PostgreSQL data directory..."

REM Try to get data directory from Windows service
for /f "tokens=3" %%a in ('sc qc postgresql-x64-17 ^| findstr "BINARY_PATH_NAME"') do set "SERVICE_PATH=%%a"

if not "%SERVICE_PATH%"=="" (
    REM Extract data directory from service path
    for /f "tokens=2 delims=-D" %%a in ("%SERVICE_PATH%") do set "PG_DATA_DIR=%%a"
    set "PG_DATA_DIR=!PG_DATA_DIR: =!"
    set "PG_DATA_DIR=!PG_DATA_DIR:"=!"
)

REM Fallback to default data directory
if "%PG_DATA_DIR%"=="" (
    set "PG_DATA_DIR=%PG_HOME%\data"
)

if not exist "%PG_DATA_DIR%" (
    call :log_error "PostgreSQL data directory not found: %PG_DATA_DIR%"
    echo %RED%Data directory not found. Please verify PostgreSQL installation.%NC%
    pause
    exit /b 1
)

set "PG_CONFIG_FILE=%PG_DATA_DIR%\postgresql.conf"
set "PG_HBA_FILE=%PG_DATA_DIR%\pg_hba.conf"

call :log_success "Data directory found: %PG_DATA_DIR%"
call :log_info "Configuration file: %PG_CONFIG_FILE%"
call :log_info "HBA file: %PG_HBA_FILE%"

REM ====================================
REM BACKUP EXISTING CONFIGURATION
REM ====================================
call :log_info "Creating backup of existing configuration..."

set "BACKUP_TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "BACKUP_DIR=backup\postgresql-backup-%BACKUP_TIMESTAMP%"

if not exist "backup" mkdir backup
mkdir "%BACKUP_DIR%"

if exist "%PG_CONFIG_FILE%" (
    copy "%PG_CONFIG_FILE%" "%BACKUP_DIR%\postgresql.conf.bak" >nul
    call :log_success "Backed up postgresql.conf"
)

if exist "%PG_HBA_FILE%" (
    copy "%PG_HBA_FILE%" "%BACKUP_DIR%\pg_hba.conf.bak" >nul
    call :log_success "Backed up pg_hba.conf"
)

call :log_info "Backup created at: %BACKUP_DIR%"

REM ====================================
REM SYSTEM RESOURCE VALIDATION
REM ====================================
call :log_info "Validating system resources..."

REM Check available memory
for /f "tokens=2 delims==" %%a in ('powershell -Command "(Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory/1GB"') do set "TOTAL_RAM=%%a"
call :log_info "Total system memory: %TOTAL_RAM% GB"

if %TOTAL_RAM% lss 32 (
    call :log_warning "Insufficient memory for 50 users. Recommended: 64GB+"
    echo %YELLOW%Warning: %TOTAL_RAM% GB RAM detected. Recommended: 64GB+ for 50 users%NC%
    echo %YELLOW%Configuration will be adjusted for available memory.%NC%
) else (
    call :log_success "Memory sufficient for 50 users: %TOTAL_RAM% GB"
)

REM ====================================
REM APPLY PRODUCTION CONFIGURATION
REM ====================================
call :log_info "Applying Windows production configuration..."

REM Stop PostgreSQL service for configuration changes
call :log_info "Stopping PostgreSQL service..."
net stop postgresql-x64-17 >nul 2>&1
if !errorlevel! equ 0 (
    call :log_success "PostgreSQL service stopped"
) else (
    call :log_warning "PostgreSQL service stop failed or not running"
)

REM Copy optimized configuration
if exist "pg_config\postgresql-windows-prod.conf" (
    copy "pg_config\postgresql-windows-prod.conf" "%PG_CONFIG_FILE%" >nul
    call :log_success "Applied production postgresql.conf"
) else (
    call :log_error "Production configuration file not found!"
    echo %RED%pg_config\postgresql-windows-prod.conf not found%NC%
    pause
    exit /b 1
)

REM Copy authentication configuration
if exist "pg_config\pg_hba-windows-prod.conf" (
    copy "pg_config\pg_hba-windows-prod.conf" "%PG_HBA_FILE%" >nul
    call :log_success "Applied production pg_hba.conf"
) else (
    call :log_warning "Production HBA configuration not found, using existing"
)

REM ====================================
REM MEMORY-BASED CONFIGURATION TUNING
REM ====================================
call :log_info "Adjusting configuration based on available memory..."

if %TOTAL_RAM% lss 64 (
    REM Adjust for systems with less than 64GB RAM
    set /a SHARED_BUFFERS=%TOTAL_RAM% * 1024 / 8
    set /a EFFECTIVE_CACHE=%TOTAL_RAM% * 1024 * 3 / 4
    
    powershell -Command "(Get-Content '%PG_CONFIG_FILE%') -replace 'shared_buffers = 4GB', 'shared_buffers = !SHARED_BUFFERS!MB' | Set-Content '%PG_CONFIG_FILE%'"
    powershell -Command "(Get-Content '%PG_CONFIG_FILE%') -replace 'effective_cache_size = 12GB', 'effective_cache_size = !EFFECTIVE_CACHE!MB' | Set-Content '%PG_CONFIG_FILE%'"
    
    call :log_info "Adjusted memory settings for %TOTAL_RAM% GB system"
)

REM ====================================
REM START POSTGRESQL SERVICE
REM ====================================
call :log_info "Starting PostgreSQL service..."

net start postgresql-x64-17 >nul 2>&1
if !errorlevel! equ 0 (
    call :log_success "PostgreSQL service started successfully"
) else (
    call :log_error "Failed to start PostgreSQL service"
    echo %RED%PostgreSQL failed to start. Check configuration syntax.%NC%
    
    REM Restore backup on failure
    echo %YELLOW%Restoring backup configuration...%NC%
    if exist "%BACKUP_DIR%\postgresql.conf.bak" (
        copy "%BACKUP_DIR%\postgresql.conf.bak" "%PG_CONFIG_FILE%" >nul
        call :log_info "Restored postgresql.conf from backup"
    )
    
    net start postgresql-x64-17 >nul 2>&1
    if !errorlevel! equ 0 (
        call :log_warning "Service started with backup configuration"
        echo %YELLOW%Service started with original configuration%NC%
    ) else (
        call :log_error "Service failed to start even with backup configuration"
        echo %RED%Critical error: PostgreSQL will not start%NC%
    )
    
    pause
    exit /b 1
)

REM Wait for PostgreSQL to fully initialize
timeout /t 5 >nul

REM ====================================
REM CONFIGURATION VERIFICATION
REM ====================================
call :log_info "Verifying PostgreSQL configuration..."

REM Test database connection
powershell -Command "try { $conn = New-Object System.Data.Odbc.OdbcConnection('Driver={PostgreSQL Unicode};Server=localhost;Port=5432;Database=postgres;Uid=admin;Pwd=1234;'); $conn.Open(); $conn.Close(); Write-Host 'SUCCESS' } catch { Write-Host 'FAILED' }" > temp_pg_test.txt
set /p PG_TEST_RESULT=<temp_pg_test.txt
del temp_pg_test.txt

if "%PG_TEST_RESULT%"=="SUCCESS" (
    call :log_success "PostgreSQL connection test successful"
) else (
    call :log_error "PostgreSQL connection test failed"
    echo %RED%Database connection failed with new configuration%NC%
)

REM ====================================
REM POSTGRESQL EXTENSIONS SETUP
REM ====================================
call :log_info "Installing required PostgreSQL extensions..."

echo %CYAN%Installing Odoo-required extensions...%NC%

REM Create extension installation script
echo CREATE EXTENSION IF NOT EXISTS "unaccent"; > temp_extensions.sql
echo CREATE EXTENSION IF NOT EXISTS "pg_trgm"; >> temp_extensions.sql
echo CREATE EXTENSION IF NOT EXISTS "btree_gin"; >> temp_extensions.sql
echo CREATE EXTENSION IF NOT EXISTS "btree_gist"; >> temp_extensions.sql
echo CREATE EXTENSION IF NOT EXISTS "pg_stat_statements"; >> temp_extensions.sql

REM Execute extension installation
set "PGPASSWORD=1234"
"%PG_HOME%\bin\psql" -h localhost -p 5432 -U admin -d postgres -f temp_extensions.sql >nul 2>&1
if !errorlevel! equ 0 (
    call :log_success "Extensions installed successfully"
    echo %GREEN%  ✓ Extensions installed%NC%
) else (
    call :log_warning "Some extensions may have failed to install"
    echo %YELLOW%  ⚠ Extension installation had warnings%NC%
)

del temp_extensions.sql
set "PGPASSWORD="

REM ====================================
REM PERFORMANCE TESTING
REM ====================================
call :log_info "Running performance test..."

echo %CYAN%Testing database performance...%NC%

REM Simple performance test
set "PGPASSWORD=1234"
powershell -Command "$start = Get-Date; try { $conn = New-Object System.Data.Odbc.OdbcConnection('Driver={PostgreSQL Unicode};Server=localhost;Port=5432;Database=postgres;Uid=admin;Pwd=1234;'); $conn.Open(); $cmd = $conn.CreateCommand(); $cmd.CommandText = 'SELECT COUNT(*) FROM information_schema.tables'; $result = $cmd.ExecuteScalar(); $conn.Close(); $end = Get-Date; [math]::Round(($end - $start).TotalMilliseconds, 0) } catch { Write-Host '9999' }" > temp_perf_test.txt
set /p PERF_TIME=<temp_perf_test.txt
del temp_perf_test.txt
set "PGPASSWORD="

if %PERF_TIME% lss 100 (
    echo %GREEN%  ✓ Performance test: %PERF_TIME%ms (Excellent)%NC%
    call :log_success "Performance test excellent: %PERF_TIME%ms"
) else if %PERF_TIME% lss 500 (
    echo %GREEN%  ✓ Performance test: %PERF_TIME%ms (Good)%NC%
    call :log_success "Performance test good: %PERF_TIME%ms"
) else (
    echo %YELLOW%  ⚠ Performance test: %PERF_TIME%ms (Needs optimization)%NC%
    call :log_warning "Performance test slow: %PERF_TIME%ms"
)

REM ====================================
REM CONFIGURATION SUMMARY
REM ====================================
echo.
echo %CYAN%====================================================================
echo                    POSTGRESQL CONFIGURATION COMPLETE
echo ====================================================================
echo PostgreSQL Version: 17
echo Installation Path: %PG_HOME%
echo Data Directory: %PG_DATA_DIR%
echo Configuration: Windows Production (50 users)
echo Memory Optimization: %TOTAL_RAM% GB system
echo ====================================================================
echo Configuration Files:
echo - postgresql.conf: %PG_CONFIG_FILE%
echo - pg_hba.conf: %PG_HBA_FILE%
echo - Backup: %BACKUP_DIR%
echo ====================================================================
echo Connection Details:
echo - Host: localhost
echo - Port: 5432
echo - Admin User: admin
echo - Password: 1234
echo - Max Connections: 100
echo ====================================================================
echo Performance Settings:
echo - Shared Buffers: Optimized for %TOTAL_RAM% GB
echo - Work Memory: 32MB per operation
echo - Maintenance Memory: 512MB
echo - Effective Cache: Auto-calculated
echo ====================================================================
echo %NC%

if "%PG_TEST_RESULT%"=="SUCCESS" (
    echo %GREEN%✓ Configuration applied successfully!%NC%
    echo %GREEN%✓ PostgreSQL ready for 50 concurrent Odoo users%NC%
    call :log_success "PostgreSQL configuration completed successfully"
) else (
    echo %YELLOW%⚠ Configuration applied but connection test failed%NC%
    echo %YELLOW%  Please verify database credentials and connectivity%NC%
    call :log_warning "Configuration completed but connection test failed"
)

echo.
echo %CYAN%Next Steps:
echo 1. Start Odoo production server: start-production.bat
echo 2. Monitor performance: scripts\monitor.bat
echo 3. Regular backups: scripts\backup.bat
echo 4. Health checks: scripts\health-check.bat%NC%
echo.

pause