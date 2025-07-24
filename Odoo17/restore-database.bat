@echo off
echo ====================================================================
echo                 ODOO DATABASE RESTORE (ZIP FORMAT)
echo ====================================================================
echo.

cd /d "%~dp0"

REM Set PostgreSQL path
set "PG_BIN=C:\Program Files\PostgreSQL\17\bin"

if not exist "%PG_BIN%\pg_restore.exe" (
    echo ERROR: PostgreSQL 17 not found at: %PG_BIN%
    pause
    exit /b 1
)

echo Using PostgreSQL 17: %PG_BIN%
echo.

REM Show available backup files
echo Available Odoo backup files in backup folder:
if exist "backup\*.zip" (
    dir backup\*.zip /b
    echo.
) else (
    echo No ZIP backup files found in backup folder
    echo Please place your Odoo backup ZIP files in: backup\
    pause
    exit /b 1
)

REM Get backup file
if "%1"=="" (
    echo Enter ZIP backup filename (just filename if in backup folder):
    set /p BACKUP_FILE="Backup file: "
    
    REM Check if it's just a filename
    echo %BACKUP_FILE% | findstr /c:"\" >nul
    if %errorlevel% neq 0 (
        set "BACKUP_FILE=backup\%BACKUP_FILE%"
    )
) else (
    set "BACKUP_FILE=%~1"
)

if not exist "%BACKUP_FILE%" (
    echo ERROR: Backup file not found: %BACKUP_FILE%
    pause
    exit /b 1
)

REM Get database name
set /p DB_NAME="Enter new database name: "
if "%DB_NAME%"=="" (
    echo ERROR: Database name required
    pause
    exit /b 1
)

echo.
echo ====================================================================
echo Backup ZIP: %BACKUP_FILE%
echo New Database: %DB_NAME%
echo PostgreSQL: %PG_BIN%
echo ====================================================================
echo.

set /p CONFIRM="Continue with Odoo ZIP restore? (y/N): "
if /i not "%CONFIRM%"=="y" (
    echo Cancelled
    pause
    exit /b 0
)

REM Create temporary extraction folder
set "TEMP_DIR=temp_restore_%RANDOM%"
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"

echo.
echo Extracting Odoo backup ZIP...
powershell -Command "Expand-Archive -Path '%BACKUP_FILE%' -DestinationPath '%TEMP_DIR%'"
if %errorlevel% neq 0 (
    echo ERROR: Failed to extract ZIP file
    rmdir /s /q "%TEMP_DIR%"
    pause
    exit /b 1
)

REM Find dump file in extracted content
set "DUMP_FILE="
for %%f in ("%TEMP_DIR%\dump.sql") do if exist "%%f" set "DUMP_FILE=%%f"
for %%f in ("%TEMP_DIR%\*.dump") do if exist "%%f" set "DUMP_FILE=%%f"
for %%f in ("%TEMP_DIR%\*.sql") do if exist "%%f" set "DUMP_FILE=%%f"

if "%DUMP_FILE%"=="" (
    echo ERROR: No database dump found in ZIP file
    rmdir /s /q "%TEMP_DIR%"
    pause
    exit /b 1
)

echo Found database dump: %DUMP_FILE%

REM Set password for PostgreSQL
set PGPASSWORD=1234

echo.
echo Creating database "%DB_NAME%"...
"%PG_BIN%\createdb.exe" -h localhost -p 5432 -U admin "%DB_NAME%"
if %errorlevel% neq 0 (
    echo WARNING: Database creation failed (may already exist)
)

echo.
echo Restoring database from dump...
echo %DUMP_FILE% | findstr /i "\.sql$" >nul
if %errorlevel% equ 0 (
    echo Using SQL format...
    "%PG_BIN%\psql.exe" -h localhost -p 5432 -U admin -d "%DB_NAME%" -f "%DUMP_FILE%"
) else (
    echo Using custom format...
    "%PG_BIN%\pg_restore.exe" -h localhost -p 5432 -U admin -d "%DB_NAME%" -v "%DUMP_FILE%"
)

if %errorlevel% neq 0 (
    echo ERROR: Database restore failed
    rmdir /s /q "%TEMP_DIR%"
    pause
    exit /b 1
)

echo.
echo Restoring filestore (attachments, images)...
if exist "%TEMP_DIR%\filestore" (
    if not exist "data\filestore" mkdir "data\filestore"
    if exist "data\filestore\%DB_NAME%" rmdir /s /q "data\filestore\%DB_NAME%"
    xcopy /E /I /Y "%TEMP_DIR%\filestore" "data\filestore\%DB_NAME%"
    echo Filestore restored to: data\filestore\%DB_NAME%
) else (
    echo No filestore found in backup (this is normal for some backups)
)

REM Cleanup
echo.
echo Cleaning up temporary files...
rmdir /s /q "%TEMP_DIR%"

echo.
echo ====================================================================
echo                    RESTORE COMPLETED SUCCESSFULLY!
echo ====================================================================
echo.
echo Database "%DB_NAME%" has been restored from Odoo backup.
echo.
echo Access your restored database at:
echo http://localhost:8069
echo.
echo Use the database selector to choose "%DB_NAME%"
echo Master password: 1234
echo ====================================================================

pause