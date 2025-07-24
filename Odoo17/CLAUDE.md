# CLAUDE.md

This file provides comprehensive guidance for working with the Odoo 17.0.0 ERP/CRM system.

## Project Overview

This is an Odoo 17.0.0 ERP/CRM system with extensive customizations for manufacturing, HR, and business process management. The system includes 300+ standard addons plus custom business modules for specialized workflows, optimized for production deployment on server IP 192.168.0.21.

## Current Configuration Status

**✅ IMPORTANT: Admin Credentials**
- **Master Password**: `1234` (for database management operations)
- **PostgreSQL Admin**: Username `admin`, Password `1234`
- **Database Management**: Full access to create, restore, backup all databases
- **Odoo Admin Interface**: Access with master password `1234`

**Production Environment:**
- **Server IP**: 192.168.0.21
- **Ports**: 8069 (web), 8072 (long polling), 5432 (database)
- **Database**: PostgreSQL with admin/1234 credentials
- **Session Storage**: Redis for production, filesystem for development

## Development Environment Setup

**Prerequisites:**
- Python 3.10+ (currently using Python 3.11.9)
- PostgreSQL database
- Docker & Docker Compose (for production)

**Virtual Environment (Development):**
```bash
# Linux/WSL
source odoo_env/bin/activate
./start-dev.sh

# Install dependencies if needed
pip install -r requirements.txt
```

**Development Configuration:**
- **Config File**: `odoo-dev.conf`
- **Database**: No specific database restriction (can manage all)
- **Admin Password**: `1234` (master password)
- **Database Connection**: `admin`/`1234`
- **URL**: http://localhost:8069

## Docker Production Environment

**Current Production Setup:**
- **PostgreSQL**: Username `admin`, Password `1234`, Database `odoo_admin`
- **Odoo Master Password**: `1234`
- **Network Binding**: 192.168.0.21:8069 and 192.168.0.21:8072
- **Redis**: Session storage and caching
- **Backup Service**: Automated with retention policies

**Docker Commands:**
```bash
# Start production environment
docker-compose up -d

# View service status
docker-compose ps

# View logs
docker-compose logs -f

# Restart specific service
docker-compose restart odoo

# Database operations
docker-compose exec db pg_dump -U admin odoo_admin > backup.sql

# Execute commands in container
docker-compose exec odoo python odoo-bin shell -c /opt/odoo/odoo.conf
```

**Production Configuration Files:**
- `docker-compose.yml` - Container orchestration
- `odoo.conf` - Production Odoo configuration
- `.env.prod` - Environment variables
- `Dockerfile` - Application container build
- `docker-entrypoint.sh` - Container startup script

## Database Management

**Master Password Usage:**
1. **Database Manager**: Go to `http://192.168.0.21:8069/web/database/manager`
2. **Enter Master Password**: `1234`
3. **Available Operations**: Create, backup, restore, duplicate, drop databases

**PostgreSQL Direct Access:**
```bash
# Development environment
PGPASSWORD=1234 psql -h localhost -p 5432 -U admin -d postgres

# Production environment (Docker)
docker-compose exec db psql -U admin -d postgres
```

**Database Restoration:**
- Use master password `1234` in Odoo database manager
- Admin user can manage ALL databases
- No restrictions on database selection or operations

## Architecture Overview

**Directory Structure:**
- `/odoo/` - Core Odoo framework (ORM, web server, modules, tools)
- `/addons/` - Standard Odoo addons (300+ modules)
- `/custom_addons/` - Custom business modules
- `/odoo_env/` - Python virtual environment (development)
- `/data/` - Data directory (development)
- `/logs/` - Log files
- `odoo-bin` - Main application entry point

**Core Components:**
- **Models** (`models/`): Business logic and database structure using Odoo ORM
- **Views** (`views/`): XML definitions for forms, lists, kanban, etc.
- **Controllers** (`controllers/`): HTTP endpoints and web routing
- **Static** (`static/`): CSS, JavaScript, images
- **i18n** (`i18n/`): Translation files (.po/.pot)
- **Tests** (`tests/`): Unit and integration tests
- **Data** (`data/`): CSV/XML data files
- **Security** (`security/`): Access control lists and rules

**Module Structure:**
Each addon follows this pattern:
```
module_name/
├── __init__.py
├── __manifest__.py          # Module metadata and dependencies
├── models/                  # Python model definitions
├── views/                   # XML view definitions
├── controllers/             # Web controllers
├── static/                  # Frontend assets
├── security/                # Access rights
├── data/                    # Default data
├── i18n/                    # Translations
└── tests/                   # Test files
```

## Key Custom Modules

**Manufacturing & Quality:**
- `mfg_labels` - Manufacturing label printing and tracking
- `quality_control_ish` - Quality control processes
- `stock_*` modules - Inventory and warehouse management

**HR & Employee Management:**
- `hr_employee_*` modules - Extended employee functionality
- `hr_contract_*` - Contract management
- `hr_holidays_*` - Leave management

**System Integration:**
- `queue_job` - Background job processing
- `connector` - External system integrations
- `tfc_*` modules - TFC system synchronization

**Web & UI:**
- `web_theme_*` - Custom theme and UI modifications
- `web_widget_*` - Custom form widgets

## Development Workflow

**Development Commands:**
```bash
# Start development server
./start-dev.sh

# Install new module
python odoo-bin -d db_name -i module_name

# Update module after changes
python odoo-bin -d db_name -u module_name

# Update all modules
python odoo-bin -d db_name -u all
```

**Adding New Features:**
1. Create or modify module in `/custom_addons/`
2. Update `__manifest__.py` with dependencies
3. Define models in `models/` directory
4. Create views in `views/` directory
5. Add security rules in `security/`
6. Write tests in `tests/`
7. Update module: `python odoo-bin -d db_name -u module_name`

**Module Dependencies:**
Always declare dependencies in `__manifest__.py`:
```python
'depends': ['base', 'sale', 'stock', ...]
```

## Configuration Files

**Development Configuration (`odoo-dev.conf`):**
```ini
[options]
admin_passwd = 1234
db_host = localhost
db_port = 5432
db_user = admin
db_password = 1234
# db_name commented out to allow database selection
addons_path = addons,custom_addons
dev_mode = reload,qweb,werkzeug,xml
list_db = True
```

**Production Configuration (`odoo.conf`):**
```ini
[options]
admin_passwd = 1234
db_host = db
db_port = 5432
db_user = admin
db_password = 1234
workers = 6
session_store = redis
redis_host = redis
redis_port = 6379
list_db = True  # Allows database management
```

**Environment Configuration (`.env.prod`):**
- Database credentials: admin/1234
- Server IP: 192.168.0.21
- Production optimizations
- Security settings

## Production Deployment

**Docker Production Architecture:**
- **Odoo Application**: Main ERP application on 192.168.0.21:8069
- **PostgreSQL Database**: Production database with admin/1234 credentials
- **Redis Cache**: Session storage and caching on port 6379
- **Backup Service**: Automated backups with retention policies
- **Health Checks**: Automatic service monitoring and restart

**Production Scripts:**
```bash
# Start production environment
docker-compose up -d

# Stop production environment
docker-compose down

# View service status
docker-compose ps

# Scale services if needed
docker-compose up -d --scale odoo=2
```

**Network Configuration:**
- **Main Interface**: 192.168.0.21:8069
- **Long Polling**: 192.168.0.21:8072
- **Database**: Internal Docker network (db:5432)
- **Redis**: Internal Docker network (redis:6379)

## Admin Password Configuration

**Current Admin Setup:**
- **Master Password**: `1234` (set in admin_passwd)
- **Purpose**: Database management operations
- **Access**: Create, backup, restore, duplicate, drop databases
- **Interface**: Available at `/web/database/manager`

**Database User Setup:**
- **Username**: `admin`
- **Password**: `1234`
- **Privileges**: Superuser, Create DB
- **Purpose**: PostgreSQL connection authentication

**Usage Examples:**
1. **Database Management**: Enter `1234` as master password
2. **Database Creation**: Use master password `1234`
3. **Backup/Restore**: Master password `1234` required
4. **Multiple Databases**: Can manage all databases with admin/1234

## Security Configuration

**Production Security:**
- Environment variables for sensitive data
- Docker network isolation
- Proper file permissions in containers
- SSL/TLS ready configuration
- Firewall rules for port access

**Development Security:**
- Local database access restricted to admin user
- Development-friendly settings
- Debug mode enabled for development
- File-based sessions for simplicity

## Testing Guidelines

**Test Structure:**
- Use `TransactionCase` for database-dependent tests
- Use `HttpCase` for web interface tests
- Mock external services in tests
- Test both positive and negative scenarios

**Test Execution:**
```bash
# Run tests for specific module
python odoo-bin -d test_db --test-enable --stop-after-init -i module_name

# Run tests without installing
python odoo-bin -d test_db --test-enable --stop-after-init --test-tags module_name

# Run tests with coverage
python -m coverage run odoo-bin -d test_db --test-enable --stop-after-init -i module_name
```

## Performance Optimization

**Production Performance:**
- Multi-worker configuration (6 workers)
- Redis session storage
- Database connection pooling
- Memory limits configured
- Log rotation enabled

**Development Performance:**
- Single worker for debugging
- File-based sessions
- Auto-reload enabled
- Comprehensive logging

**Database Optimization:**
```bash
# Regular maintenance
PGPASSWORD=1234 psql -h localhost -p 5432 -U admin -d postgres -c "VACUUM ANALYZE;"

# Database statistics
PGPASSWORD=1234 psql -h localhost -p 5432 -U admin -d postgres -c "SELECT pg_size_pretty(pg_database_size('database_name'));"
```

## Troubleshooting

**Development Issues:**
- Module not found: Check `addons_path` configuration
- Database access errors: Verify admin/1234 credentials
- Import errors: Check module dependencies in `__manifest__.py`
- Master password issues: Ensure `admin_passwd = 1234` in config

**Production Issues:**
- **Container startup failures**: Check Docker logs with `docker-compose logs`
- **Database connection errors**: Verify admin/1234 credentials in docker-compose.yml
- **Port conflicts**: Ensure ports 8069, 8072 are available on 192.168.0.21
- **Memory issues**: Monitor container resources with `docker stats`

**Database Issues:**
- **Connection refused**: Check PostgreSQL service status
- **Authentication failed**: Verify admin/1234 credentials
- **Database doesn't exist**: Use master password to create new database
- **Permission denied**: Ensure admin user has superuser privileges

**Quick Fixes:**
```bash
# Development: Restart with correct config
./start-dev.sh

# Production: Restart containers
docker-compose restart

# Database: Reset admin user password
PGPASSWORD=1234 psql -h localhost -U admin -d postgres -c "ALTER USER admin PASSWORD '1234';"

# Clean start: Remove containers and restart
docker-compose down --volumes
docker-compose up -d
```

## Backup and Recovery

**Automated Backups (Production):**
- Daily automated backups via Docker service
- 7-day retention policy
- Database and filestore backup
- Stored in `/backup` directory

**Manual Backup:**
```bash
# Development
PGPASSWORD=1234 pg_dump -h localhost -p 5432 -U admin database_name > backup.sql

# Production
docker-compose exec db pg_dump -U admin database_name > backup.sql
```

**Recovery Process:**
1. Stop Odoo service
2. Create new database (if needed)
3. Restore from backup
4. Restart Odoo service
5. Verify functionality

## Migration Notes

**From Windows Native to Docker:**
- All .bat files removed (Windows-specific)
- Configuration migrated to Docker environment
- Same admin/1234 credentials maintained
- Database structure preserved
- Module compatibility maintained

**Environment Parity:**
- Development and production use same admin/1234 credentials
- Database management capabilities identical
- Module paths and configurations aligned
- Performance settings optimized per environment

## Quick Reference

**Essential Commands:**
```bash
# Linux Development
./start-dev.sh                    # Start development server
PGPASSWORD=1234 psql -h localhost -U admin -d postgres  # Database access

# Windows Production - FIRST TIME SETUP
setup-environment.bat             # Create virtual environment and install dependencies

# Windows Production - REGULAR USE
start-production.bat              # Start production server
stop-production.bat               # Stop production server
restart-production.bat            # Restart production server

# Windows Production - UPDATE DEPENDENCIES
install-odoo-deps.bat             # Update dependencies only
```

**Git Workflow (NEW - Environment Isolation):**
```bash
# Clone fresh repository
git clone <your-repo>
cd Odoo17

# First time setup (creates virtual environment)
setup-environment.bat             # Windows
./setup-environment.sh            # Linux (if needed)

# Regular updates
git pull
# No need to reinstall environment - .gitignore protects it!
```

**Key URLs:**
- **Development**: http://localhost:8069
- **Production**: http://localhost:8069
- **Database Manager**: /web/database/manager (master password: 1234)

**Credentials Summary:**
- **Master Password**: 1234
- **PostgreSQL**: admin/1234
- **Database Management**: Full access with admin/1234
- **Multi-database**: Supported, no restrictions

**Important Files:**
- `odoo-dev.conf` - Development configuration
- `odoo-prod.conf` - Production configuration for Windows
- `odoo.conf` - General configuration
- `start-dev.sh` - Linux development startup script
- `install-odoo-deps.bat` - Windows dependency installer

This comprehensive setup provides a stable, scalable Odoo 17 environment with consistent admin/1234 credentials across development and production deployments.

---

# Windows Deployment & Troubleshooting Guide

## Why Batch Files Close Automatically & How to Fix It

### The Issue
When you double-click any `.bat` file, it executes and immediately closes when finished. This is normal Windows behavior - you can't see the output because the window closes too fast.

### Solutions

#### Solution 1: Run from Command Prompt (RECOMMENDED)
1. **Open Command Prompt as Administrator**
   - Press `Windows Key + R`
   - Type `cmd` and press `Ctrl + Shift + Enter`
   - Click "Yes" when prompted

2. **Navigate to your Odoo directory**
   ```cmd
   cd /d "C:\path\to\your\Odoo17"
   ```

3. **Run the scripts**
   ```cmd
   # Install dependencies
   install-odoo-deps.bat
   
   # Start production server
   start-production.bat
   
   # Stop production server
   stop-production.bat
   
   # Restart production server
   restart-production.bat
   ```

#### Solution 2: Right-Click Method
1. **Right-click** on any `.bat` file
2. Select **"Edit"** to see the script content
3. OR select **"Run as administrator"** and the window will stay open longer

### Quick Start Guide

#### Step 1: Install Dependencies
```cmd
# Run as Administrator
install-odoo-deps.bat
```
This will:
- ✅ Activate virtual environment
- ✅ Install all Python dependencies
- ✅ Handle compilation issues automatically
- ✅ Wait for your input before closing

#### Step 2: Start Production Server
```cmd
start-production.bat
```
This will:
- ✅ Start optimized worker processes
- ✅ Validate system resources
- ✅ Show startup progress
- ✅ Keep running until you press Ctrl+C

#### Step 3: Access Your Server
Once started, access your server at:
- **Main Interface**: http://localhost:8069
- **Database Manager**: http://localhost:8069/web/database/manager
- **Master Password**: 1234

## Windows Production Deployment Guide
### Native Windows Deployment for 50 Concurrent Users

#### 📋 Prerequisites

##### System Requirements
- **OS**: Windows Server 2019/2022 or Windows 10/11 Pro
- **RAM**: 64GB recommended (minimum 32GB)
- **CPU**: 8+ cores (Intel Xeon or AMD EPYC recommended)
- **Storage**: 1TB+ SSD (NVMe preferred)
- **Network**: Gigabit Ethernet

##### Software Requirements
- **PostgreSQL 17**: Database server
- **Python 3.10+**: Runtime environment
- **Administrator privileges**: Required for service installation

#### 🛠 Configuration Files

##### Core Configuration

| File | Purpose | Optimized For |
|------|---------|---------------|
| `odoo-prod.conf` | Main Odoo config | 50 concurrent users |
| `odoo-dev.conf` | Development config | Single user development |

##### Key Settings for 50 Users

**Odoo Production Configuration:**
```ini
workers = 10                    # Optimal for 50 users
limit_memory_soft = 2GB         # Per worker
limit_memory_hard = 3GB         # Per worker  
max_cron_threads = 2            # Background jobs
session_store = filesystem      # Windows optimized
admin_passwd = 1234            # Master password
```

#### 🔧 Management Commands

##### Server Control
```cmd
start-production.bat        # Start production server
stop-production.bat         # Graceful shutdown
restart-production.bat      # Zero-downtime restart
```

##### Development
```cmd
# For Linux development
./start-dev.sh             # Linux development server

# For Windows development
# Use start-production.bat with odoo-dev.conf
```

#### 📈 Performance Optimization

##### For 50+ Users

1. **Memory Allocation**
   - 10 workers × 3GB = 30GB for Odoo
   - 16GB for PostgreSQL
   - 8GB for Windows OS
   - **Total: 54GB minimum**

2. **CPU Optimization**
   - Enable all CPU cores
   - Set high priority for PostgreSQL service
   - Use performance power plan

3. **Storage Optimization**
   - Use SSD for data directory
   - Separate drives for logs
   - Regular disk cleanup

#### 🚨 Common Issues & Solutions

##### "Script closes immediately"
- **Cause**: Normal Windows behavior
- **Solution**: Run from Command Prompt (see Solution 1 above)

##### "Access Denied" or "Permission Error"
- **Cause**: Insufficient privileges
- **Solution**: Run Command Prompt as Administrator

##### "PostgreSQL not found"
- **Cause**: PostgreSQL 17 not installed or not in standard location
- **Solution**: Install PostgreSQL 17 with credentials admin/1234

##### "Python environment not found"
- **Cause**: Virtual environment not created
- **Solution**: Create it with `python -m venv odoo_env`

##### "Dependencies won't install"
- **Cause**: Compilation issues with binary packages
- **Solution**: Use `install-odoo-deps.bat` which handles binary wheels

#### 🎯 Success Criteria

Your deployment is successful when:

✅ **Performance**
- Response time < 2 seconds
- 99.9% uptime
- < 1% error rate

✅ **Scalability**
- Handles 50 concurrent users
- Peak load capacity: 75 users
- Growth ready architecture

✅ **Reliability**
- Master password 1234 works
- Database admin/1234 credentials work
- Service starts without errors

---

# Performance Optimization Guide

## Performance Comparison

### Local Development (start-dev.sh on Linux)
- **Workers**: 0 (single process)
- **Memory**: 1GB soft / 2GB hard limits
- **Sessions**: Filesystem storage
- **Dev Mode**: Full reload capabilities
- **Database**: Direct localhost connection
- **Startup Time**: ~15-30 seconds
- **Response Time**: 50-200ms

### Windows Production (Windows batch files)
- **Workers**: 10 (multi-process)
- **Memory**: 2GB soft / 3GB hard limits
- **Sessions**: Filesystem storage
- **Dev Mode**: Disabled
- **Database**: Direct localhost connection
- **Startup Time**: ~30-60 seconds
- **Response Time**: 100-300ms

## Usage Instructions

### For Active Development (Linux)
Use local development setup:
```bash
source odoo_env/bin/activate
./start-dev.sh
```
- **Best for**: Active coding, debugging, module development
- **Access**: http://localhost:8069

### For Production Deployment (Windows)
Use Windows production setup:
```cmd
start-production.bat
```
- **Best for**: Production deployment, load testing
- **Access**: http://localhost:8069

## Performance Optimizations Implemented

### 1. Windows Production Configuration

**Key Changes in odoo-prod.conf:**
- Multi-worker configuration (workers = 10)
- Filesystem sessions (no external dependencies)
- Production-grade memory limits
- Optimized for Windows environment
- Master password security

**Performance Impact**: Optimized for 50+ concurrent users

### 2. Development Configuration

**Key Changes in odoo-dev.conf:**
```ini
workers = 0                    # Single process (no multi-worker overhead)
session_store = filesystem     # No Redis network calls
dev_mode = reload,qweb,werkzeug,xml  # Development optimizations
limit_memory_soft = 1GB        # Relaxed memory limits
list_db = True                 # Database management enabled
```

**Performance Impact**: 25-35% faster startup and response times

## Best Practices

### Development Workflow
1. **Linux Development**: Use `./start-dev.sh` for active development
2. **Windows Production**: Use batch files for production deployment
3. **Database Management**: Use master password 1234 for database operations
4. **Credentials**: Consistent admin/1234 across all environments

### Configuration Management
- Keep separate configs for development and production
- Use master password 1234 for database management
- Monitor resource usage and adjust limits accordingly
- Regular performance testing and benchmarking

### Database Management
- Use admin/1234 credentials for PostgreSQL
- Master password 1234 for Odoo database management
- Regular VACUUM and ANALYZE in development
- Monitor query performance
- No database restrictions - can manage all databases

## Environment Comparison Matrix

| Feature | Linux Dev | Windows Prod |
|---------|-----------|--------------|
| Startup Speed | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Response Time | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Resource Usage | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Debugging | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Production Ready | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| Multi-user Support | ⭐⭐ | ⭐⭐⭐⭐⭐ |

## Quick Commands Reference

```bash
# Linux development
source odoo_env/bin/activate && ./start-dev.sh

# Windows production
start-production.bat
stop-production.bat
restart-production.bat

# Windows dependency installation
install-odoo-deps.bat

# Database access (all environments)
# Master password: 1234
# PostgreSQL: admin/1234
```

## Expected Performance

With these optimizations, you should see:
- **Windows Production**: Handles 50+ concurrent users efficiently
- **Database Operations**: Consistent performance with admin/1234 credentials
- **Memory Efficiency**: Optimized memory usage per worker
- **Development Experience**: Fast iteration on Linux, stable production on Windows
- **Database Management**: Full access with master password 1234

---

# Essential Files Maintained

## Kept Files
- **install-odoo-deps.bat**: Windows dependency installation with binary wheel handling
- **start-production.bat**: Windows production server startup
- **stop-production.bat**: Windows production server shutdown  
- **restart-production.bat**: Windows production server restart
- **start-dev.sh**: Linux development server startup
- **odoo-prod.conf**: Windows production configuration
- **odoo-dev.conf**: Development configuration
- **requirements.txt**: Python dependencies (optimized for Windows)

## Removed Files
- All Docker-related files (Dockerfile, docker-compose.yml, etc.)
- Unnecessary batch files (diagnose-startup.bat, fix-common-issues.bat, etc.)
- Separate markdown files (consolidated into this CLAUDE.md)
- nginx configuration (not needed for native Windows deployment)

This streamlined setup focuses on essential native Windows production deployment and Linux development workflows.