# Odoo 18 Development Environment Setup

This document provides instructions for setting up and running the Odoo 18 development environment.

## Prerequisites

### System Requirements
- Ubuntu/Debian Linux or WSL2
- Python 3.10 or higher
- PostgreSQL 12 or higher
- Git
- Node.js and npm (for frontend assets)

### PostgreSQL Setup
1. Install PostgreSQL:
   ```bash
   sudo apt update
   sudo apt install postgresql postgresql-contrib
   ```

2. Start PostgreSQL service:
   ```bash
   sudo systemctl start postgresql
   sudo systemctl enable postgresql
   ```

3. Create database user with credentials matching odoo-dev.conf:
   ```bash
   sudo -u postgres psql
   CREATE USER admin WITH CREATEDB PASSWORD '1234';
   ALTER USER admin WITH SUPERUSER;
   \q
   ```

### System Dependencies
Install required system packages:
```bash
sudo apt update
sudo apt install python3-dev python3-pip python3-venv python3-wheel \
    libxml2-dev libxslt1-dev libevent-dev libsasl2-dev libldap2-dev \
    libpq-dev libjpeg-dev libpng-dev libfreetype6-dev liblcms2-dev \
    libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev \
    pkg-config build-essential postgresql-server-dev-all \
    libffi-dev libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libxml2-dev libxmlsec1-dev
```

**Alternative Installation (if compilation fails):**
```bash
# Use binary packages instead of compiling from source
source venv/bin/activate
pip install psycopg2-binary lxml-html-clean
pip install -r requirements.txt
```

## Quick Start

### 1. Start Development Server
Simply run the start script:
```bash
./start-dev.sh
```

The script will automatically:
- Check PostgreSQL service status
- Create and activate Python virtual environment
- Install Python dependencies from requirements.txt
- Create necessary directories (logs, data)
- Start Odoo with development configuration

### 2. Access the Application
- **Web Interface**: http://localhost:8069
- **Database Manager**: http://localhost:8069/web/database/manager

### 3. Database Management
The development setup allows you to:
- Create new databases through the web interface
- Select existing databases from the login screen
- Use the database manager for administrative tasks

## Configuration Details

### Files Overview
- `start-dev.sh` - Main development server startup script
- `odoo-dev.conf` - Odoo configuration optimized for development
- `custom_addons/` - Directory for your custom addon modules
- `logs/` - Development server logs (auto-created)
- `venv/` - Python virtual environment (auto-created)

### Database Configuration
```
Host: localhost
Port: 5432
User: admin
Password: 1234
```

### Server Configuration
```
HTTP Port: 8069
Interface: 0.0.0.0 (accessible from network)
Workers: 0 (single-threaded for debugging)
Max Cron Threads: 1 (minimal for development)
```

### Development Features Enabled
- Auto-reload on file changes (`--dev=all`)
- Debug mode available
- All development logging
- Database creation through web interface
- Custom addons auto-discovery

## Custom Addons

### Adding Custom Addons
1. Place your addon directories in `custom_addons/`
2. Restart the development server
3. Update the app list in Odoo settings
4. Install your custom addons

### Existing Custom Addons
- `hr_employee_id` - HR employee ID management
- `hr_leave_description_label` - HR leave description labels
- `odoo_website_helpdesk` - Website helpdesk system
- `odoo_website_helpdesk_dashboard` - Helpdesk dashboard

## Development Workflow

### Starting Development
```bash
# Start the development server
./start-dev.sh

# With additional options
./start-dev.sh --log-level=debug
```

### Stopping the Server
- Press `Ctrl+C` in the terminal
- The script will handle graceful shutdown

### Viewing Logs
```bash
# Real-time log viewing
tail -f logs/odoo-YYYYMMDD-HHMMSS.log

# View all logs
ls -la logs/
```

### Development Best Practices
1. **Use Virtual Environment**: Always activated automatically by start-dev.sh
2. **Database Isolation**: Create separate databases for different features
3. **Log Monitoring**: Keep an eye on logs for errors and warnings
4. **Regular Backups**: Backup databases before major changes
5. **Addon Testing**: Test custom addons in isolated databases

## Troubleshooting

### Common Issues

#### PostgreSQL Connection Failed
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Restart PostgreSQL
sudo systemctl restart postgresql

# Verify user credentials
sudo -u postgres psql -c "SELECT usename, usesuper FROM pg_user WHERE usename='admin';"
```

#### Python Dependencies Issues
```bash
# Force reinstall dependencies
rm -rf venv/
./start-dev.sh
```

#### Port Already in Use
```bash
# Check what's using port 8069
sudo lsof -i :8069

# Kill the process if needed
sudo kill -9 <PID>
```

#### Permission Errors
```bash
# Fix file permissions
chmod +x start-dev.sh
chmod -R 755 custom_addons/
```

### Performance Optimization
- Use SSD storage for better I/O performance
- Allocate sufficient RAM (minimum 4GB recommended)
- Close unnecessary applications during development
- Use database indexing for large datasets

## Advanced Configuration

### Custom Configuration
Edit `odoo-dev.conf` to modify:
- Database settings
- Logging levels
- Server ports
- Memory limits
- Addon paths

### Environment Variables
You can set these environment variables before running:
```bash
export ODOO_HTTP_PORT=8070
export ODOO_DB_HOST=localhost
export ODOO_DB_USER=admin
export ODOO_DB_PASSWORD=1234
```

### Development Tools Integration
- **VS Code**: Install Python and Odoo extensions
- **PyCharm**: Configure Python interpreter to use venv/bin/python
- **Debugging**: Use `--dev=all` flag for enhanced debugging

## Security Notes

⚠️ **This configuration is for development only!**

- Uses simple database credentials (admin/1234)
- Allows external connections (interface=0.0.0.0)
- Debug mode and development features enabled
- No master password protection

Never use this configuration in production environments.

## Getting Help

1. Check the logs in `logs/` directory
2. Verify PostgreSQL is running and accessible
3. Ensure all Python dependencies are installed
4. Review the Odoo official documentation
5. Check custom addon compatibility

For Odoo-specific issues, refer to:
- [Odoo Developer Documentation](https://www.odoo.com/documentation/18.0/developer.html)
- [Odoo Community Forums](https://www.odoo.com/forum)
- [GitHub Issues](https://github.com/odoo/odoo/issues)