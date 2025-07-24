@echo off
REM ====================================================================
REM Odoo 17 Production Backup Script
REM Automated database and filestore backup for Windows
REM ====================================================================

setlocal enabledelayedexpansion

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
REM BACKUP CONFIGURATION
REM ====================================
set "DB_HOST=localhost"
set "DB_PORT=5432"
set "DB_USER=admin"
set "DB_PASSWORD=1234"
set "BACKUP_DIR=..\backup"
set "RETENTION_DAYS=30"
set "COMPRESSION=TRUE"
set "LOG_FILE=..\logs\backup.log"

REM Generate timestamp for backup files
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "BACKUP_TIMESTAMP=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%-%dt:~10,2%-%dt:~12,2%"

REM ====================================
REM LOGGING FUNCTIONS
REM ====================================
:log_info
echo %GREEN%[%date% %time%] INFO: %~1%NC%
echo [%date% %time%] INFO: %~1 >> "%LOG_FILE%"
exit /b

:log_error
echo %RED%[%date% %time%] ERROR: %~1%NC%
echo [%date% %time%] ERROR: %~1 >> "%LOG_FILE%"
exit /b

:log_warning
echo %YELLOW%[%date% %time%] WARNING: %~1%NC%
echo [%date% %time%] WARNING: %~1 >> "%LOG_FILE%"
exit /b

:log_success
echo %CYAN%[%date% %time%] SUCCESS: %~1%NC%
echo [%date% %time%] SUCCESS: %~1 >> "%LOG_FILE%"
exit /b

REM ====================================
REM BACKUP HEADER
REM ====================================
cls
echo %BLUE%
echo ====================================================================
echo                   ODOO 17 PRODUCTION BACKUP
echo                     Automated Backup System
echo ====================================================================
echo Timestamp: %BACKUP_TIMESTAMP%
echo Backup Directory: %BACKUP_DIR%
echo Retention Period: %RETENTION_DAYS% days
echo Database: PostgreSQL 17 (%DB_HOST%:%DB_PORT%)
echo ====================================================================
echo %NC%

REM Navigate to parent directory (from scripts to main)
cd /d "%~dp0\.."

REM Ensure required directories exist
if not exist "logs" mkdir logs
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

call :log_info "Starting automated backup process..."

REM ====================================
REM PRE-BACKUP VALIDATION
REM ====================================
call :log_info "Performing pre-backup validation..."

REM Check PostgreSQL connectivity
call :log_info "Testing PostgreSQL connectivity..."
powershell -Command "try { $conn = New-Object System.Data.Odbc.OdbcConnection('Driver={PostgreSQL Unicode};Server=%DB_HOST%;Port=%DB_PORT%;Database=postgres;Uid=%DB_USER%;Pwd=%DB_PASSWORD%;'); $conn.Open(); $conn.Close(); Write-Host 'SUCCESS' } catch { Write-Host 'FAILED' }" > temp_db_test.txt
set /p DB_TEST_RESULT=<temp_db_test.txt
del temp_db_test.txt

if "%DB_TEST_RESULT%"=="FAILED" (
    call :log_error "PostgreSQL connection failed! Cannot proceed with backup."
    echo %RED%Database connection failed. Please check PostgreSQL service.%NC%
    pause
    exit /b 1
)
call :log_success "PostgreSQL connection verified"

REM Check available disk space (minimum 5GB)
for /f "tokens=3" %%a in ('dir "%BACKUP_DIR%" /-c ^| find "bytes free"') do set "FREE_SPACE=%%a"
set "FREE_SPACE=%FREE_SPACE:,=%"
set /a FREE_SPACE_GB=!FREE_SPACE! / 1073741824

if %FREE_SPACE_GB% lss 5 (
    call :log_warning "Low disk space: %FREE_SPACE_GB% GB available"
    echo %YELLOW%Warning: Low disk space (%FREE_SPACE_GB% GB). Backup may fail.%NC%
) else (
    call :log_info "Disk space available: %FREE_SPACE_GB% GB"
)

REM ====================================
REM DATABASE DISCOVERY
REM ====================================
call :log_info "Discovering databases to backup..."

REM Get list of databases (excluding system databases)
powershell -Command "
try {
    $conn = New-Object System.Data.Odbc.OdbcConnection('Driver={PostgreSQL Unicode};Server=%DB_HOST%;Port=%DB_PORT%;Database=postgres;Uid=%DB_USER%;Pwd=%DB_PASSWORD%;')
    $conn.Open()
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = \"SELECT datname FROM pg_database WHERE datistemplate = false AND datname NOT IN ('postgres', 'template0', 'template1')\"
    $reader = $cmd.ExecuteReader()
    while ($reader.Read()) {
        Write-Host $reader['datname']
    }
    $reader.Close()
    $conn.Close()
} catch {
    Write-Host 'ERROR: Failed to get database list'
}
" > temp_db_list.txt

set "DATABASE_COUNT=0"
for /f %%i in (temp_db_list.txt) do (
    set /a DATABASE_COUNT+=1
    set "DB_!DATABASE_COUNT!=%%i"
)
del temp_db_list.txt

if %DATABASE_COUNT% equ 0 (
    call :log_warning "No user databases found to backup"
    echo %YELLOW%No user databases found. Only system backup will be performed.%NC%
) else (
    call :log_info "Found %DATABASE_COUNT% databases to backup"
    echo %CYAN%Databases to backup:%NC%
    for /l %%i in (1,1,%DATABASE_COUNT%) do (
        echo   - !DB_%%i!
    )
)

echo.

REM ====================================
REM DATABASE BACKUP
REM ====================================
call :log_info "Starting database backup..."

set "BACKUP_SUCCESS_COUNT=0"
set "BACKUP_TOTAL_SIZE=0"

for /l %%i in (1,1,%DATABASE_COUNT%) do (
    set "CURRENT_DB=!DB_%%i!"
    set "BACKUP_FILE=%BACKUP_DIR%\!CURRENT_DB!_%BACKUP_TIMESTAMP%.sql"
    
    call :log_info "Backing up database: !CURRENT_DB!"
    echo %CYAN%Backing up: !CURRENT_DB!...%NC%
    
    REM Set PostgreSQL password environment variable
    set "PGPASSWORD=%DB_PASSWORD%"
    
    REM Create database backup using pg_dump
    pg_dump -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d "!CURRENT_DB!" -f "!BACKUP_FILE!" --verbose 2>nul
    
    if !errorlevel! equ 0 (
        call :log_success "Database backup completed: !CURRENT_DB!"
        set /a BACKUP_SUCCESS_COUNT+=1
        
        REM Get backup file size
        for %%A in ("!BACKUP_FILE!") do set "FILE_SIZE=%%~zA"
        set /a FILE_SIZE_MB=!FILE_SIZE! / 1048576
        set /a BACKUP_TOTAL_SIZE+=!FILE_SIZE_MB!
        
        echo %GREEN%  ✓ Completed: !FILE_SIZE_MB! MB%NC%
        
        REM Compress backup if enabled
        if "%COMPRESSION%"=="TRUE" (
            call :log_info "Compressing backup: !CURRENT_DB!"
            echo %YELLOW%  Compressing...%NC%
            
            powershell -Command "Compress-Archive -Path '!BACKUP_FILE!' -DestinationPath '!BACKUP_FILE!.zip' -Force" 2>nul
            if !errorlevel! equ 0 (
                del "!BACKUP_FILE!"
                call :log_success "Backup compressed: !CURRENT_DB!"
                echo %GREEN%  ✓ Compressed%NC%
            ) else (
                call :log_warning "Compression failed for: !CURRENT_DB!"
            )
        )
    ) else (
        call :log_error "Database backup failed: !CURRENT_DB!"
        echo %RED%  ✗ Failed%NC%
    )
    
    REM Clear password environment variable
    set "PGPASSWORD="
)

echo.

REM ====================================
REM FILESTORE BACKUP
REM ====================================
call :log_info "Starting filestore backup..."

if exist "data\filestore" (
    set "FILESTORE_BACKUP=%BACKUP_DIR%\filestore_%BACKUP_TIMESTAMP%"
    
    echo %CYAN%Backing up filestore...%NC%
    call :log_info "Creating filestore backup"
    
    REM Create filestore backup using robocopy
    robocopy "data\filestore" "%FILESTORE_BACKUP%" /E /R:3 /W:1 /NP /NFL /NDL >nul 2>&1
    
    if !errorlevel! leq 3 (
        call :log_success "Filestore backup completed"
        
        REM Calculate filestore size
        powershell -Command "(Get-ChildItem -Path '%FILESTORE_BACKUP%' -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB" > temp_filestore_size.txt
        set /p FILESTORE_SIZE=<temp_filestore_size.txt
        del temp_filestore_size.txt
        
        echo %GREEN%  ✓ Filestore: !FILESTORE_SIZE! MB%NC%
        
        REM Compress filestore if enabled
        if "%COMPRESSION%"=="TRUE" (
            echo %YELLOW%  Compressing filestore...%NC%
            call :log_info "Compressing filestore backup"
            
            powershell -Command "Compress-Archive -Path '%FILESTORE_BACKUP%' -DestinationPath '%FILESTORE_BACKUP%.zip' -Force" 2>nul
            if !errorlevel! equ 0 (
                rmdir /s /q "%FILESTORE_BACKUP%" 2>nul
                call :log_success "Filestore compressed"
                echo %GREEN%  ✓ Filestore compressed%NC%
            ) else (
                call :log_warning "Filestore compression failed"
            )
        )
    ) else (
        call :log_error "Filestore backup failed"
        echo %RED%  ✗ Filestore backup failed%NC%
    )
) else (
    call :log_warning "Filestore directory not found"
    echo %YELLOW%  ⚠ Filestore not found%NC%
)

echo.

REM ====================================
REM CONFIGURATION BACKUP
REM ====================================
call :log_info "Backing up configuration files..."

set "CONFIG_BACKUP=%BACKUP_DIR%\config_%BACKUP_TIMESTAMP%"
mkdir "%CONFIG_BACKUP%" 2>nul

echo %CYAN%Backing up configuration...%NC%

REM Backup Odoo configuration files
if exist "odoo-prod.conf" copy "odoo-prod.conf" "%CONFIG_BACKUP%\odoo-prod.conf" >nul
if exist "odoo-dev.conf" copy "odoo-dev.conf" "%CONFIG_BACKUP%\odoo-dev.conf" >nul

REM Backup PostgreSQL configuration if accessible
if exist "pg_config" robocopy "pg_config" "%CONFIG_BACKUP%\pg_config" /E /NP /NFL /NDL >nul

REM Backup custom addons list
if exist "custom_addons" (
    dir "custom_addons" /B > "%CONFIG_BACKUP%\custom_addons_list.txt"
)

REM Backup service scripts
if exist "scripts" robocopy "scripts" "%CONFIG_BACKUP%\scripts" /E /NP /NFL /NDL >nul

call :log_success "Configuration backup completed"
echo %GREEN%  ✓ Configuration files backed up%NC%

REM Compress configuration backup
if "%COMPRESSION%"=="TRUE" (
    powershell -Command "Compress-Archive -Path '%CONFIG_BACKUP%' -DestinationPath '%CONFIG_BACKUP%.zip' -Force" 2>nul
    if !errorlevel! equ 0 (
        rmdir /s /q "%CONFIG_BACKUP%" 2>nul
        call :log_success "Configuration backup compressed"
    )
)

echo.

REM ====================================
REM CLEANUP OLD BACKUPS
REM ====================================
call :log_info "Cleaning up old backups (retention: %RETENTION_DAYS% days)..."

echo %CYAN%Cleaning old backups...%NC%

REM Calculate cutoff date
powershell -Command "$cutoff = (Get-Date).AddDays(-%RETENTION_DAYS%); Get-ChildItem '%BACKUP_DIR%' | Where-Object { $_.CreationTime -lt $cutoff } | ForEach-Object { Remove-Item $_.FullName -Recurse -Force; Write-Host \"Deleted: $($_.Name)\" }" > temp_cleanup.txt

set "DELETED_COUNT=0"
for /f %%i in (temp_cleanup.txt) do set /a DELETED_COUNT+=1
del temp_cleanup.txt

if %DELETED_COUNT% gtr 0 (
    call :log_info "Cleaned up %DELETED_COUNT% old backup files"
    echo %GREEN%  ✓ Cleaned %DELETED_COUNT% old files%NC%
) else (
    call :log_info "No old backup files to clean"
    echo %GREEN%  ✓ No cleanup needed%NC%
)

echo.

REM ====================================
REM BACKUP VERIFICATION
REM ====================================
call :log_info "Verifying backup integrity..."

echo %CYAN%Verifying backups...%NC%

set "VERIFICATION_SUCCESS=0"
set "VERIFICATION_TOTAL=0"

REM Verify database backups
for /l %%i in (1,1,%DATABASE_COUNT%) do (
    set "CURRENT_DB=!DB_%%i!"
    set /a VERIFICATION_TOTAL+=1
    
    if "%COMPRESSION%"=="TRUE" (
        set "BACKUP_FILE=%BACKUP_DIR%\!CURRENT_DB!_%BACKUP_TIMESTAMP%.sql.zip"
    ) else (
        set "BACKUP_FILE=%BACKUP_DIR%\!CURRENT_DB!_%BACKUP_TIMESTAMP%.sql"
    )
    
    if exist "!BACKUP_FILE!" (
        REM Check if file is not empty
        for %%A in ("!BACKUP_FILE!") do set "BACKUP_SIZE=%%~zA"
        if !BACKUP_SIZE! gtr 1024 (
            set /a VERIFICATION_SUCCESS+=1
            echo %GREEN%  ✓ !CURRENT_DB! backup verified%NC%
        ) else (
            echo %RED%  ✗ !CURRENT_DB! backup too small%NC%
            call :log_error "Backup verification failed: !CURRENT_DB! (size: !BACKUP_SIZE! bytes)"
        )
    ) else (
        echo %RED%  ✗ !CURRENT_DB! backup file missing%NC%
        call :log_error "Backup file not found: !CURRENT_DB!"
    )
)

REM Calculate success rate
if %VERIFICATION_TOTAL% gtr 0 (
    set /a SUCCESS_RATE=(!VERIFICATION_SUCCESS! * 100) / %VERIFICATION_TOTAL%
) else (
    set "SUCCESS_RATE=0"
)

echo.

REM ====================================
REM BACKUP SUMMARY
REM ====================================
echo %CYAN%====================================================================
echo                          BACKUP SUMMARY
echo ====================================================================
echo Backup Time: %date% %time%
echo Total Databases: %DATABASE_COUNT%
echo Successful Backups: %BACKUP_SUCCESS_COUNT%/%DATABASE_COUNT%
echo Verification Rate: %VERIFICATION_SUCCESS%/%VERIFICATION_TOTAL% (%SUCCESS_RATE%%%)
echo Total Backup Size: %BACKUP_TOTAL_SIZE% MB
echo Backup Location: %BACKUP_DIR%
echo Compression: %COMPRESSION%
echo Retention Period: %RETENTION_DAYS% days
echo ====================================================================

if %SUCCESS_RATE% geq 100 (
    echo %GREEN%Backup Status: SUCCESS - All backups completed successfully%NC%
    call :log_success "Backup process completed successfully"
    set "EXIT_CODE=0"
) else if %SUCCESS_RATE% geq 80 (
    echo %YELLOW%Backup Status: PARTIAL - Some backups may have issues%NC%
    call :log_warning "Backup process completed with warnings"
    set "EXIT_CODE=1"
) else (
    echo %RED%Backup Status: FAILED - Multiple backup failures detected%NC%
    call :log_error "Backup process failed"
    set "EXIT_CODE=2"
)

echo.
echo Next Actions:
echo - Review backup log: %LOG_FILE%
echo - Test backup restoration periodically
echo - Monitor disk space usage
echo - Verify backup integrity regularly
echo ====================================================================%NC%

call :log_info "Backup process completed with exit code: %EXIT_CODE%"

if "%1"=="--silent" (
    exit /b %EXIT_CODE%
) else (
    echo.
    pause
)