# Installation Guide

## Prerequisites

1. Odoo 18 instance with the following base modules installed:
   - `hr` (Human Resources)
   - `hr_holidays` (Time Off)

## Installation Steps

### 1. Module Deployment
```bash
# Copy the module to your custom addons directory
cp -r hr_department_leave_approval /path/to/odoo/custom_addons/

# Or use git if managing through version control
cd /path/to/odoo/custom_addons/
git clone <repository_url>/hr_department_leave_approval.git
```

### 2. Update Addons Path
Ensure your Odoo configuration includes the custom addons path:
```ini
# In odoo.conf
addons_path = /path/to/odoo/addons,/path/to/odoo/custom_addons
```

### 3. Install via CLI
```bash
# Update module list and install
./odoo-bin -u hr_department_leave_approval -d your_database

# Or install from scratch
./odoo-bin -i hr_department_leave_approval -d your_database
```

### 4. Install via Web Interface
1. Navigate to Apps menu
2. Update Apps List (remove "Apps" filter)
3. Search for "HR Department Leave Approval"
4. Click Install

## Post-Installation Configuration

### 1. Assign Department Managers
1. Go to **Human Resources > Configuration > Departments**
2. For each department:
   - Set a **Manager** (must be an employee with user account)
   - Ensure the manager has proper security groups

### 2. Verify User Groups
Ensure users have the correct groups:
- **Department Managers**: 
  - HR User
  - Time Off User
  - Department Manager (auto-assigned)
- **Regular Employees**:
  - Employee (base.group_user)
  - Time Off User (for leave requests)

### 3. Test Access Control
1. Login as a department manager
2. Verify you can only see:
   - Your own employee record
   - Employees in your managed department
   - Leave requests from your department

## Validation Checklist

- [ ] Module installs without errors
- [ ] Department managers can see only their department employees
- [ ] Department managers can see only their department's leave requests
- [ ] Regular employees can only see their own data
- [ ] Leave approval/rejection works for department managers
- [ ] Access denied for unauthorized operations
- [ ] All database constraints are enforced

## Troubleshooting

### Installation Issues
```bash
# Check for missing dependencies
./odoo-bin --addons-path=/path/to/addons -d database --stop-after-init

# Check logs for errors
tail -f /var/log/odoo/odoo-server.log
```

### Access Issues
1. Verify employee has department assigned
2. Check department has manager assigned  
3. Verify manager has user account
4. Check user group assignments

### Performance Considerations
- Record rules are evaluated at database level (efficient)
- No significant performance impact expected
- Monitor query performance for large datasets

## Uninstallation

```bash
# Uninstall via CLI
./odoo-bin -u hr_department_leave_approval -d your_database --uninstall

# Or use web interface:
# Apps > Installed > HR Department Leave Approval > Uninstall
```

Note: Uninstalling will remove all record rules and security configurations added by this module.