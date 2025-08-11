# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Odoo 18 ERP/CRM system with extensive customizations including helpdesk management, HR extensions, and modern web themes. The system includes 300+ standard addons plus 14 custom addons focused on website helpdesk, HR management, and modern UI components.

## Agent Routing Rules

### Primary Directive
Always pick the correct Odoo subagent, then enforce MCP routing:
- **Development work** → use **context7 MCP** for documentation and patterns
- **UI Configuration/Testing** → use **Playwright MCP** for browser automation (ALWAYS in headless mode)
- **Testing (unit/integration/UI/E2E)** → use **Playwright MCP** for browser automation

### Playwright MCP Configuration
**IMPORTANT**: Always use Playwright MCP in headless mode for all browser automation tasks including:
- Website configuration through web interface
- UI testing and validation  
- Form submissions and navigation
- Settings configuration via web UI

### Request Classification
1. **Development Phase**: "implement", "create", "build", "fix", "refactor", "migrate", "customize"
   - Route to specialized Odoo subagent (backend/frontend/integration/migration/devops/performance/security/functional/reviewer)
   - Use **context7 MCP** for Odoo patterns, documentation, best practices
   - Use **Playwright MCP** for any UI configuration or web interface tasks

2. **UI Configuration Phase**: "config", "configure", "setup website", "enable", "disable", "set permissions"
   - Use **Playwright MCP** in headless mode for all web interface configuration
   - Navigate and configure through Odoo web interface
   - Do NOT modify core modules directly

3. **Testing Phase**: "test", "e2e", "ui", "smoke", "acceptance", "regression"
   - Unit/integration tests → **odoo-test-engineer** subagent
   - UI/E2E/browser tests → use **Playwright MCP** in headless mode
   - Do NOT call context7 MCP unless seeding/resetting state

4. **If Ambiguous**: Ask ONE clarifying question; default to **Development**

## Development Environment

### Quick Start Commands
```bash
# Start development server
./start-dev.sh

# Access applications
# Web Interface: http://localhost:8069  
# Database Manager: http://localhost:8069/web/database/manager
```

### Database Configuration
- **Host**: localhost:5432
- **User**: admin
- **Password**: 1234
- **Default Database**: NWFTH-Odoo18-V2
- **Multi-database**: Supported, database selection in web interface
- **Database URL**: http://localhost:8069/web?db=NWFTH-Odoo18-V2

### Core Architecture
- `/odoo/` - Core Odoo 18 framework (ORM, web server, routing)
- `/addons/` - Standard Odoo addons (300+ modules)  
- `/custom_addons/` - Custom business modules (14 addons)
- `/venv/` - Python virtual environment (auto-created)
- `/logs/` - Development logs (auto-created)
- `odoo-bin` - Main application entry point

## Module Development Workflow

### Standard Module Structure
```
addon_name/
├── __init__.py
├── __manifest__.py          # Module metadata
├── models/                  # Business logic & database
├── views/                   # XML view definitions  
├── controllers/             # HTTP endpoints
├── static/                  # CSS, JavaScript, images
├── security/                # Access control
├── data/                    # CSV/XML data files
├── tests/                   # Unit & integration tests
└── i18n/                    # Translation files
```

### Development Commands
```bash
# Install/update module
python odoo-bin -d db_name -i module_name
python odoo-bin -d db_name -u module_name

# Run with development features
./start-dev.sh  # Includes --dev=all, auto-reload

# Test specific module
python odoo-bin -d test_db --test-enable -i module_name --stop-after-init
```

## Key Custom Modules

### Website & Portal
- `odoo_website_helpdesk` (v18.0.1.0.2) - Complete helpdesk system with web interface
- `odoo_website_helpdesk_dashboard` (v18.0.1.0.0) - Dashboard and analytics

### HR Extensions  
- `hr_employee_id` (v18.0.1.0.0) - Employee ID management
- `hr_leave_description_label` (v18.0.1.0) - Leave description customization

### MuK Web Framework (Modern UI)
- `muk_web_theme` - Base theme with modern design
- `muk_web_enterprise_theme` - Enterprise styling 
- `muk_web_appsbar` - Enhanced application navigation
- `muk_web_chatter` - Improved chatter interface
- `muk_web_colors` - Color customization system
- `muk_web_dialog` - Enhanced dialog components
- `muk_web_utils` - Utility components

### Business Modules
- `muk_contacts` - Enhanced contact management with sequences
- `muk_mail_route` - Advanced mail routing system with container support
- `muk_product` - Product management with search enhancements

## Testing Framework

### Odoo 18 Testing Patterns
```python
# Unit tests
from odoo.tests import TransactionCase

class TestModel(TransactionCase):
    def test_functionality(self):
        # Test business logic
        pass

# HTTP/Integration tests  
from odoo.tests import HttpCase

class TestController(HttpCase):
    def test_route(self):
        # Test web endpoints
        pass
```

### Test Execution
```bash
# Run tests for specific module
python odoo-bin -d test_db --test-enable -i module_name --stop-after-init

# Run tests by tag
python odoo-bin -d test_db --test-enable --test-tags module_name

# Run with coverage (if available)
python odoo-bin -d test_db --test-enable --test-tags module_name --coverage
```

## Security & Best Practices

### Odoo 18 Security Patterns
- **Record Rules**: Domain-based access control in `security/` directory
- **Access Control Lists**: Model-level permissions in `ir.model.access.csv`
- **Groups**: User group definitions in `security/groups.xml`
- **Multi-company**: Respect `company_id` field and multi-company rules

### Development Guidelines
- Use `_inherit` for extending models, never monkey-patch core
- Implement proper `@api.depends()` for computed fields
- Add appropriate indexes for custom fields with `index=True`
- Follow Odoo 18 version format: "18.0.x.y.z" in manifests
- Use modern ORM patterns: `create()`, `write()`, `search()`

### Migration Safety
- All custom modules use proper Odoo 18 version format
- Extensions use inheritance patterns for upgrade safety
- Database changes through proper migration scripts
- No direct core framework modifications

## Configuration Files

### Development Configuration (`odoo-dev.conf`)
- Development mode enabled (`dev = all`)
- Auto-reload active for code changes
- Single worker mode for debugging
- Debug logging enabled
- Multi-database support enabled

### Key Settings
```ini
dev = all                    # Full development features
workers = 0                  # Single-threaded for debugging  
max_cron_threads = 1         # Minimal cron processing
log_level = info            # Appropriate logging
list_db = True              # Database selection enabled
```

## Performance Considerations

- Use appropriate database indexes for custom fields
- Implement proper prefetching with `prefetch_fields`
- Batch operations when processing multiple records
- Use `@api.model` for utility methods not tied to recordsets
- Leverage Odoo's built-in caching mechanisms

## Integration Points

### External System Integration
- `muk_mail_route` provides advanced email routing capabilities
- Custom controllers in `odoo_website_helpdesk` for web form handling
- Portal integration for customer-facing interfaces

### Frontend Integration
- Modern JavaScript components in `static/src/` directories
- SCSS/CSS customization through MuK theme modules
- QWeb template inheritance for view modifications

## Deployment Considerations

- Virtual environment with Python dependencies in `requirements.txt`
- PostgreSQL 12+ required with admin/1234 credentials
- Node.js needed for frontend asset compilation
- System dependencies documented in `DEV_SETUP.md`

## Git Commit Guidelines

### Commit Message Style
- Use **professional, natural commit messages** that appear human-written
- **NEVER** include AI-generated signatures, bot mentions, or references to Claude Code
- Follow conventional commit format when appropriate
- Focus on the business value and technical changes made
- Examples of preferred style:
  ```
  Add helpdesk management module for customer support
  
  Integrate OCA helpdesk_mgmt v18.0.1.7.0 with complete ticket management,
  team organization, and portal support for enhanced customer service.
  ```

### What to Avoid
- ❌ "🤖 Generated with [Claude Code]"
- ❌ "Co-Authored-By: Claude"
- ❌ Any reference to AI assistance
- ❌ Robot emojis or automation indicators

### Preferred Approach
- ✅ Professional, descriptive commit messages
- ✅ Focus on business impact and technical details
- ✅ Use active voice and clear language
- ✅ Include version numbers and source attribution when relevant

This Odoo 18 environment is optimized for development with proper agent routing, comprehensive custom modules, and modern development practices.