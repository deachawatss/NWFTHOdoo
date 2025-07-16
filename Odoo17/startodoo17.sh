#!/bin/bash

# Navigate to the Odoo17 directory
cd "$(dirname "$0")"

echo "[INFO] Restarting Odoo Server..."

# Check if there are any running Odoo processes before stopping them
if pgrep -f "python.*odoo-bin" > /dev/null; then
    echo "[INFO] Stopping existing Odoo process..."
    pkill -f "python.*odoo-bin"
    sleep 3
else
    echo "[INFO] No running Odoo process found."
fi

# Check if log file exists before deleting
if [ -f "odoo.log" ]; then
    rm -f odoo.log
    echo "[INFO] Old log file deleted."
else
    echo "[INFO] No existing log file found."
fi

# Activate virtual environment
source odoo_env/bin/activate

# Run Odoo in development mode and show log while saving to file
python odoo-bin -c odoo.conf --dev=reload,qweb,werkzeug,xml --log-level=info 2>&1 | tee odoo.log

# Wait for user input before closing (equivalent to Windows pause)
read -p "Press Enter to continue..."