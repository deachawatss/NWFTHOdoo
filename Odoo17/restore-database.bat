@echo off
echo ====================================================================
echo                    ODOO DATABASE RESTORE
echo ====================================================================
echo.

cd /d "%~dp0"

REM Set PostgreSQL path
set "PG_BIN=C:\Program Files\PostgreSQL\17\bin"

if not exist "%PG_BIN%\pg_restore.exe" (
    echo ERROR: PostgreSQL 17 not found at: %PG_BIN%
    echo Please verify PostgreSQL 17 is installed
    pause
    exit /b 1
)

echo Using PostgreSQL 17: %PG_BIN%
echo.

REM Get backup file
if "%1"=="" (
    set /p BACKUP_FILE="Enter full path to backup file: "
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
echo Backup file: %BACKUP_FILE%
echo Database: %DB_NAME%
echo PostgreSQL: %PG_BIN%
echo.

set /p CONFIRM="Continue restore? (y/N): "
if /i not "%CONFIRM%"=="y" (
    echo Cancelled
    pause
    exit /b 0
)

REM Set password for PostgreSQL
set PGPASSWORD=1234

echo.
echo Creating database...
"%PG_BIN%\createdb.exe" -h localhost -p 5432 -U admin "%DB_NAME%"

echo.
echo Restoring from backup...
echo %BACKUP_FILE% | findstr /i "\.sql$" >nul
if %errorlevel% equ 0 (
    echo Using SQL format...
    "%PG_BIN%\psql.exe" -h localhost -p 5432 -U admin -d "%DB_NAME%" -f "%BACKUP_FILE%"
) else (
    echo Using custom format...
    "%PG_BIN%\pg_restore.exe" -h localhost -p 5432 -U admin -d "%DB_NAME%" -v "%BACKUP_FILE%"
)

if %errorlevel% equ 0 (
    echo.
    echo SUCCESS: Database "%DB_NAME%" restored!
    echo Access at: http://localhost:8069
) else (
    echo.
    echo ERROR: Restore failed
)

pause