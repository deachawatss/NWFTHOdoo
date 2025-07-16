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

## Troubleshooting

**Common Issues:**
- Module not found: Check `addons_path` configuration
- Database access errors: Verify PostgreSQL connection settings
- Import errors: Check module dependencies in `__manifest__.py`
- Translation issues: Update .po files and restart server

**Debugging:**
- Use `--dev=reload` for auto-restart on code changes
- Enable developer mode in Odoo interface
- Use Python debugger (`pdb`) in model methods
- Check server logs for detailed error information

**Performance:**
- Monitor database query performance
- Use `--dev=qweb` for template debugging
- Profile slow operations with Odoo profiler
- Consider database indexing for custom fields