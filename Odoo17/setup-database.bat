@echo off
REM ====================================================
REM   Odoo 17 Database Setup Helper
REM   Sets up PostgreSQL database and user for Odoo
REM ====================================================

setlocal enabledelayedexpansion

REM Set colors for output
set GREEN=[92m
set RED=[91m
set YELLOW=[93m
set BLUE=[94m
set NC=[0m

echo %BLUE%======================================================%NC%
echo %BLUE%       Odoo 17 Database Setup Helper%NC%
echo %BLUE%       This will create PostgreSQL database and user%NC%
echo %BLUE%       Time: %date% %time%%NC%
echo %BLUE%======================================================%NC%
echo.

REM Navigate to the script directory
cd /d "%~dp0"

REM Step 1: Check PostgreSQL installation
echo %GREEN%[%time%] Step 1: Checking PostgreSQL installation...%NC%

psql --version >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%ERROR: PostgreSQL client (psql) not found!%NC%
    echo.
    echo Please install PostgreSQL from:
    echo https://www.postgresql.org/download/windows/
    echo.
    echo Make sure to:
    echo - Install PostgreSQL server
    echo - Add PostgreSQL bin directory to PATH
    echo - Remember the postgres user password
    echo.
    pause
    exit /b 1
)

for /f "tokens=3" %%i in ('psql --version 2^>^&1') do set PG_VERSION=%%i
echo %GREEN%[%time%] PostgreSQL %PG_VERSION% found.%NC%

REM Step 2: Test connection to PostgreSQL
echo %GREEN%[%time%] Step 2: Testing PostgreSQL connection...%NC%

echo %YELLOW%Please enter the PostgreSQL 'postgres' user password:%NC%
set /p POSTGRES_PASSWORD=Password: 

REM Test connection
echo select version(); | psql -h localhost -U postgres -d postgres >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%ERROR: Cannot connect to PostgreSQL!%NC%
    echo Please check:
    echo - PostgreSQL service is running
    echo - Password is correct
    echo - PostgreSQL is accepting connections on localhost:5432
    echo.
    pause
    exit /b 1
)

echo %GREEN%[%time%] PostgreSQL connection successful.%NC%

REM Step 3: Check if odoo_prod user exists
echo %GREEN%[%time%] Step 3: Checking if odoo_prod user exists...%NC%

echo SELECT 1 FROM pg_roles WHERE rolname='odoo_prod'; | psql -h localhost -U postgres -d postgres -t -A | findstr "1" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[%time%] User 'odoo_prod' already exists.%NC%
    set USER_EXISTS=true
) else (
    echo %GREEN%[%time%] User 'odoo_prod' does not exist. Will create.%NC%
    set USER_EXISTS=false
)

REM Step 4: Create odoo_prod user if it doesn't exist
if "!USER_EXISTS!"=="false" (
    echo %GREEN%[%time%] Step 4: Creating odoo_prod user...%NC%
    
    echo CREATE USER odoo_prod WITH PASSWORD 'OdooSecure2024!' CREATEDB; | psql -h localhost -U postgres -d postgres >nul 2>&1
    if %errorlevel% neq 0 (
        echo %RED%ERROR: Failed to create odoo_prod user!%NC%
        pause
        exit /b 1
    )
    
    echo %GREEN%[%time%] User 'odoo_prod' created successfully.%NC%
) else (
    echo %GREEN%[%time%] Step 4: Updating odoo_prod user password...%NC%
    
    echo ALTER USER odoo_prod WITH PASSWORD 'OdooSecure2024!' CREATEDB; | psql -h localhost -U postgres -d postgres >nul 2>&1
    if %errorlevel% neq 0 (
        echo %YELLOW%WARNING: Failed to update user password. User may already have correct settings.%NC%
    ) else (
        echo %GREEN%[%time%] User 'odoo_prod' password updated.%NC%
    )
)

REM Step 5: Check if odoo_prod database exists
echo %GREEN%[%time%] Step 5: Checking if odoo_prod database exists...%NC%

echo SELECT 1 FROM pg_database WHERE datname='odoo_prod'; | psql -h localhost -U postgres -d postgres -t -A | findstr "1" >nul 2>&1
if %errorlevel% equ 0 (
    echo %GREEN%[%time%] Database 'odoo_prod' already exists.%NC%
    set DB_EXISTS=true
) else (
    echo %GREEN%[%time%] Database 'odoo_prod' does not exist. Will create.%NC%
    set DB_EXISTS=false
)

REM Step 6: Create odoo_prod database if it doesn't exist
if "!DB_EXISTS!"=="false" (
    echo %GREEN%[%time%] Step 6: Creating odoo_prod database...%NC%
    
    echo CREATE DATABASE odoo_prod OWNER odoo_prod ENCODING 'UTF8'; | psql -h localhost -U postgres -d postgres >nul 2>&1
    if %errorlevel% neq 0 (
        echo %RED%ERROR: Failed to create odoo_prod database!%NC%
        pause
        exit /b 1
    )
    
    echo %GREEN%[%time%] Database 'odoo_prod' created successfully.%NC%
) else (
    echo %GREEN%[%time%] Step 6: Database already exists, skipping creation.%NC%
)

REM Step 7: Test connection with odoo_prod user
echo %GREEN%[%time%] Step 7: Testing connection with odoo_prod user...%NC%

echo select current_database(), current_user; | psql -h localhost -U odoo_prod -d odoo_prod >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%ERROR: Cannot connect with odoo_prod user!%NC%
    echo Please check the user creation was successful.
    pause
    exit /b 1
)

echo %GREEN%[%time%] Connection test with odoo_prod user successful.%NC%

REM Step 8: Create necessary extensions (if needed)
echo %GREEN%[%time%] Step 8: Creating necessary database extensions...%NC%

REM Try to create common extensions that Odoo might need
echo CREATE EXTENSION IF NOT EXISTS unaccent; | psql -h localhost -U postgres -d odoo_prod >nul 2>&1
echo CREATE EXTENSION IF NOT EXISTS pg_trgm; | psql -h localhost -U postgres -d odoo_prod >nul 2>&1

echo %GREEN%[%time%] Database extensions created (if available).%NC%

REM Step 9: Validate configuration
echo %GREEN%[%time%] Step 9: Validating database configuration...%NC%

REM Check if we can create tables (basic permission test)
echo CREATE TABLE IF NOT EXISTS test_table (id SERIAL PRIMARY KEY); DROP TABLE IF EXISTS test_table; | psql -h localhost -U odoo_prod -d odoo_prod >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%ERROR: User odoo_prod cannot create tables in database!%NC%
    pause
    exit /b 1
)

echo %GREEN%[%time%] Database permissions validated.%NC%

REM Step 10: Success message and next steps
echo.
echo %BLUE%======================================================%NC%
echo %BLUE%       Database Setup Complete!%NC%
echo %BLUE%======================================================%NC%
echo %GREEN%✓ PostgreSQL connection validated%NC%
echo %GREEN%✓ User 'odoo_prod' created/updated%NC%
echo %GREEN%✓ Database 'odoo_prod' created/validated%NC%
echo %GREEN%✓ Database permissions validated%NC%
echo %GREEN%✓ Extensions created%NC%
echo.
echo %BLUE%Database Configuration:%NC%
echo %BLUE%- Host: localhost%NC%
echo %BLUE%- Port: 5432%NC%
echo %BLUE%- Database: odoo_prod%NC%
echo %BLUE%- User: odoo_prod%NC%
echo %BLUE%- Password: OdooSecure2024!%NC%
echo.
echo %BLUE%Next Steps:%NC%
echo %BLUE%1. Database is ready for Odoo%NC%
echo %BLUE%2. Run 'start-odoo-windows.bat' to start Odoo%NC%
echo %BLUE%3. Open browser to http://192.168.0.21:8069%NC%
echo %BLUE%4. Follow Odoo initial setup wizard%NC%
echo.
echo %BLUE%Troubleshooting:%NC%
echo %BLUE%- If connection fails, check PostgreSQL service is running%NC%
echo %BLUE%- Check Windows Firewall allows PostgreSQL (port 5432)%NC%
echo %BLUE%- Ensure pg_hba.conf allows local connections%NC%
echo.
echo %BLUE%======================================================%NC%

echo Press any key to continue...
pause >nul