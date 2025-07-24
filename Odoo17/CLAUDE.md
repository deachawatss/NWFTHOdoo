# CLAUDE.md

This file provides comprehensive guidance for working with the Odoo 17.0.0 ERP/CRM system.

## Project Overview

This is an Odoo 17.0.0 ERP/CRM system with extensive customizations for manufacturing, HR, and business process management. The system includes 300+ standard addons plus custom business modules for specialized workflows.

## Current Configuration Status

**✅ IMPORTANT: Admin Credentials**
- **Master Password**: `1234` (for database management operations)
- **PostgreSQL Admin**: Username `admin`, Password `1234`
- **Database Management**: Full access to create, restore, backup all databases
- **Odoo Admin Interface**: Access with master password `1234`

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
db_host = localhost
db_port = 5432
db_user = admin
db_password = 1234
workers = 4
session_store = filesystem
list_db = True
```

## Production Deployment

You have several deployment options:

### Option 1: Docker Compose (Recommended)
**Perfect for production and development consistency**

```bash
# Start Docker environment
./start-docker.sh

# Stop Docker environment  
./stop-docker.sh

# View logs
./docker-logs.sh [odoo|db|pgadmin|all]
```

**Docker Services:**
- **Odoo**: Official Odoo 17 image with your custom addons
- **PostgreSQL**: Database with admin/1234 credentials
- **PgAdmin**: Web-based database management (optional)

**Access URLs:**
- **Odoo**: http://localhost:8069
- **PgAdmin**: http://localhost:8080 (admin@localhost / 1234)
- **Database**: localhost:5432 (admin/1234)

### Option 2: Direct Python Execution
**For development with virtual environment**

```bash
# Start development server
./start-dev.sh
```

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
```

## Quick Reference

**Essential Commands:**
```bash
# Docker Development (Recommended)
./start-docker.sh                 # Start Docker environment
./stop-docker.sh                  # Stop Docker environment
./docker-logs.sh                  # View logs

# Linux Development (Virtual Environment)
./start-dev.sh                    # Start development server

# Database Access
PGPASSWORD=1234 psql -h localhost -U admin -d postgres  # Direct access
```

**Key URLs:**
- **Development**: http://localhost:8069
- **Database Manager**: /web/database/manager (master password: 1234)

**Credentials Summary:**
- **Master Password**: 1234
- **PostgreSQL**: admin/1234
- **Database Management**: Full access with admin/1234
- **Multi-database**: Supported, no restrictions

**Important Files:**
- `odoo-dev.conf` - Development configuration
- `odoo.conf` - Production configuration
- `start-dev.sh` - Linux development startup script

This setup provides a stable, scalable Odoo 17 environment with consistent admin/1234 credentials for development and production deployments.