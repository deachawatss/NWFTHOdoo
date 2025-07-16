@echo off
cd /d C:\MyProjects\Odoo17
echo [INFO] Restarting Odoo Server...

:: ตรวจสอบว่ามี process Odoo รันอยู่ก่อนจะปิด
tasklist | findstr "python.exe" > nul
if %errorlevel%==0 (
    echo [INFO] Stopping existing Odoo process...
    taskkill /F /IM python.exe /T
    timeout /t 3 /nobreak >nul
) else (
    echo [INFO] No running Odoo process found.
)

:: เช็คว่า log file มีอยู่ก่อนลบ
if exist odoo.log (
    del /F /Q odoo.log
    echo [INFO] Old log file deleted.
) else (
    echo [INFO] No existing log file found.
)

:: เปิดใช้งาน virtual environment
call venv\Scripts\activate

:: รัน Odoo ในโหมด development และโชว์ log พร้อมบันทึกลงไฟล์
powershell -Command "python odoo-bin --dev=reload,qweb,werkzeug,xml -d odoo_dev --addons-path=addons,custom_addons --xmlrpc-port=8069 --log-level=info | Tee-Object -FilePath odoo.log"

pause
