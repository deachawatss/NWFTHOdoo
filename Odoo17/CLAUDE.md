# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Odoo 17.0.0 ERP/CRM system with extensive customizations for manufacturing, HR, and business process management. The system includes 300+ standard addons plus custom business modules for specialized workflows.

## Development Environment Setup

**Prerequisites:**
- Python 3.10+ (currently using Python 3.11.9)
- PostgreSQL database
- Windows environment (primary development platform)

**Virtual Environment:**
```bash
# Activate virtual environment
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt
```

**Database Setup:**
```bash
# Create new database with demo data
python odoo-bin -d your_db_name -i base --addons-path=addons,custom_addons

# Update existing database
python odoo-bin -d your_db_name -u module_name --addons-path=addons,custom_addons
```

## Common Development Commands

**Start Odoo Server:**
```bash
# Development mode with auto-reload
python odoo-bin --dev=reload,qweb,werkzeug,xml -d your_db_name --addons-path=addons,custom_addons

# Windows startup script
startodoo17.bat

# Production mode
python odoo-bin -c odoo.conf
```

**Module Development:**
```bash
# Install new module
python odoo-bin -d db_name -i module_name

# Update module after changes
python odoo-bin -d db_name -u module_name

# Update all modules
python odoo-bin -d db_name -u all
```

**Testing:**
```bash
# Run tests for specific module
python odoo-bin -d test_db --test-enable --stop-after-init -i module_name

# Run tests without installing
python odoo-bin -d test_db --test-enable --stop-after-init --test-tags module_name

# Run tests with coverage
python -m coverage run odoo-bin -d test_db --test-enable --stop-after-init -i module_name
```

**Database Management:**
```bash
# Drop database
dropdb db_name

# Create database backup
pg_dump db_name > backup.sql

# Restore database
createdb new_db_name
psql new_db_name < backup.sql
```

## Architecture Overview

**Directory Structure:**
- `/odoo/` - Core Odoo framework (ORM, web server, modules, tools)
- `/addons/` - Standard Odoo addons (300+ modules)
- `/custom_addons/` - Custom business modules
- `/venv/` - Python virtual environment
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

**Database Migration:**
- Use migration scripts for data updates
- Test migrations on copy of production database
- Follow Odoo upgrade guidelines for version changes

**Security Model:**
- Define access rights in `security/ir.model.access.csv`
- Use record rules for row-level security
- Groups defined in `security/security.xml`

## Configuration

**Main Config File:** `odoo.conf`
Key settings:
- `addons_path` - Module search paths
- `db_host`, `db_port`, `db_user`, `db_password` - Database connection
- `xmlrpc_port` - Web server port (default 8069)
- `workers` - Multi-processing configuration

**Development Settings:**
```ini
[options]
addons_path = addons,custom_addons
admin_passwd = admin
db_host = localhost
db_port = 5432
xmlrpc_port = 8069
dev_mode = reload,qweb,werkzeug,xml
```

## Testing Guidelines

**Test Structure:**
- Use `TransactionCase` for database-dependent tests
- Use `HttpCase` for web interface tests
- Mock external services in tests
- Test both positive and negative scenarios

**Test Execution:**
- Tests run in isolated transactions
- Use `--test-tags` for selective testing
- CI/CD should run full test suite

## Code Quality

**Python Standards:**
- Follow PEP 8 coding standards
- Use Odoo coding guidelines
- Lint with pylint using Odoo configuration

**JavaScript/CSS:**
- Use ESLint for JavaScript validation
- Follow Odoo web framework patterns
- Minimize custom CSS, use Bootstrap classes

## Production Deployment

**Docker Production Setup:**
This project includes a complete Docker-based production environment optimized for Windows Server 192.168.0.21.

**Production Scripts:**
```bash
# Start production environment
start-production.bat

# Stop production environment
stop-production.bat
```

**Production Architecture:**
- **Odoo Application Container**: Main ERP application on port 8069
- **PostgreSQL Database**: Production database with automatic health checks
- **Redis Cache**: Session storage and caching on port 6379
- **Automatic Backup Service**: Daily backups with 7-day retention
- **Nginx Reverse Proxy**: Load balancing and SSL termination (optional)

**Docker Commands:**
```bash
# View service status
docker-compose ps

# View logs
docker-compose logs -f

# Restart specific service
docker-compose restart odoo

# Scale services
docker-compose up -d --scale odoo=2

# Execute commands in container
docker-compose exec odoo python odoo-bin shell -c odoo.conf

# Database operations
docker-compose exec db pg_dump -U odoo_prod odoo_prod > backup.sql
```

**Production Configuration:**
- Database: `odoo_prod` on dedicated PostgreSQL container
- Data persistence: Docker volumes for database and filestore
- Backup: Automated daily backups to `/backup` directory
- Monitoring: Health checks and container restart policies
- Security: Isolated network and environment variables

**Environment Variables:**
```bash
# Database Configuration
POSTGRES_DB=odoo_prod
POSTGRES_USER=odoo_prod
POSTGRES_PASSWORD=OdooSecure2024!

# Backup Configuration
BACKUP_RETENTION_DAYS=7
BACKUP_INTERVAL=86400  # 24 hours
```

## Troubleshooting

**Development Issues:**
- Module not found: Check `addons_path` configuration
- Database access errors: Verify PostgreSQL connection settings
- Import errors: Check module dependencies in `__manifest__.py`
- Translation issues: Update .po files and restart server

**Production Issues:**
- **Container startup failures**: Check Docker logs with `docker-compose logs`
- **Database connection errors**: Verify database health with `docker-compose exec db pg_isready`
- **Port conflicts**: Ensure ports 8069, 8072, 5432 are available
- **Memory issues**: Monitor container resources with `docker stats`
- **Backup failures**: Check backup service logs and disk space

**Docker Troubleshooting:**
```bash
# Check container health
docker-compose ps
docker-compose logs [service_name]

# Restart failed services
docker-compose restart [service_name]

# Rebuild containers
docker-compose build --no-cache

# Clean up Docker resources
docker system prune -a
docker volume prune

# Check disk usage
docker system df
```

**Performance Monitoring:**
```bash
# Monitor container resources
docker stats

# Check database performance
docker-compose exec db psql -U odoo_prod -c "SELECT * FROM pg_stat_activity;"

# Monitor Odoo logs
docker-compose logs -f odoo | grep -E "(ERROR|WARNING)"
```

**Database Maintenance:**
```bash
# Create database backup
docker-compose exec db pg_dump -U odoo_prod odoo_prod > backup_$(date +%Y%m%d).sql

# Restore database
docker-compose exec -T db psql -U odoo_prod -d odoo_prod < backup.sql

# Check database size
docker-compose exec db psql -U odoo_prod -c "SELECT pg_size_pretty(pg_database_size('odoo_prod'));"
```

**Debugging:**
- Use `--dev=reload` for auto-restart on code changes
- Enable developer mode in Odoo interface
- Use Python debugger (`pdb`) in model methods
- Check server logs for detailed error information
- Monitor Docker container logs for system-level issues

**Performance:**
- Monitor database query performance
- Use `--dev=qweb` for template debugging
- Profile slow operations with Odoo profiler
- Consider database indexing for custom fields
- Monitor container resource usage
- Implement Redis caching for session management

**Security Best Practices:**
- Use environment variables for sensitive data
- Implement SSL/TLS with nginx reverse proxy
- Regular security updates for base images
- Monitor access logs and failed authentication attempts
- Implement database backup encryption
- Use Docker secrets for production passwords