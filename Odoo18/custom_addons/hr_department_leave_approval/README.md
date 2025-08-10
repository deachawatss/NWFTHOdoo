# HR Department Leave Approval

## Overview

This module implements department-based leave approval system for Odoo 18, providing strict access control where managers can only see and manage employees and leave requests within their assigned departments.

## Features

### Core Functionality
- **Department-Based Access Control**: Managers can only see employees in departments they manage
- **Leave Request Visibility**: Managers see only leave requests from their department employees
- **Secure Record Rules**: Implemented at database level using Odoo record rules
- **Manager Assignment**: Proper department and manager relationships

### Security Features
- **Record-Level Security**: Access control implemented through record rules
- **Domain Filtering**: Automatic filtering based on department manager relationships
- **Access Validation**: Business logic validation for create/modify operations
- **Group-Based Permissions**: Proper security group configuration

### Technical Implementation
- **Model Extensions**: Extends `hr.employee` and `hr.leave` models
- **Record Rules**: Comprehensive security rules for all relevant models
- **Access Rights**: Proper CSV access control configuration
- **Validation**: Constraint validation and access checking methods

## Installation

1. Copy the module to your custom addons directory
2. Update the addons list: `./odoo-bin -u hr_department_leave_approval -d your_database`
3. Install the module from Apps menu or CLI

## Configuration

### Setting up Department Managers

1. Go to **Human Resources > Configuration > Departments**
2. For each department, assign a **Manager** who should be an employee with a user account
3. Ensure the manager has the appropriate security groups:
   - HR User (`hr.group_hr_user`)
   - Time Off User (`hr_holidays.group_hr_holidays_user`)

### User Groups

The module creates and uses these security groups:
- **Department Manager**: Can manage their department's employees and leave requests
- **HR User**: Basic HR access with department restrictions
- **Time Off User**: Basic leave access with department restrictions

## Usage

### For Department Managers

**Employee Management:**
- View all employees in your managed department(s)
- Access employee details and HR information
- Cannot see employees from other departments

**Leave Management:**
- View leave requests from your department employees
- Approve or refuse leave requests from your team
- Cannot access leave requests from other departments
- Can view your own leave requests

**Dashboard Functions:**
- Get department statistics via `get_department_statistics()` method
- View leave statistics via `get_department_leave_statistics()` method
- Access pending approvals via `get_pending_approvals()` method

### For Regular Employees

**Employee Access:**
- View your own employee record
- View colleagues in the same department
- Cannot access employees from other departments

**Leave Access:**
- Create and manage your own leave requests
- View only your own leave requests and allocations
- Cannot access other employees' leave data

## Technical Details

### Record Rules

**HR Employee Rules:**
```python
# Department Manager Access
[
    '|',
    ('id', '=', user.employee_id.id),
    ('department_id.manager_id.user_id', '=', user.id)
]

# Regular User Access
[
    '|',
    ('id', '=', user.employee_id.id),
    '&',
        ('department_id', '=', user.employee_id.department_id.id),
        ('department_id', '!=', False)
]
```

**HR Leave Rules:**
```python
# Department Manager Access
[
    '|',
    ('employee_id.id', '=', user.employee_id.id),
    ('employee_id.department_id.manager_id.user_id', '=', user.id)
]

# Regular User Access
[('employee_id.id', '=', user.employee_id.id)]
```

### Model Methods

**HR Employee Extensions:**
- `_get_department_manager_domain()`: Get visibility domain for managers
- `_check_department_manager_access()`: Validate access permissions
- `get_manager_employees()`: Get all managed employees
- `get_department_statistics()`: Get department statistics

**HR Leave Extensions:**
- `_get_department_leave_domain()`: Get leave visibility domain
- `_check_department_manager_leave_access()`: Validate leave access
- `action_approve()`: Override with access control
- `action_refuse()`: Override with access control
- `get_department_leave_statistics()`: Get leave statistics
- `get_my_team_leaves()`: Get team leave requests
- `get_pending_approvals()`: Get pending approval requests

### Validation and Constraints

- **Department Manager Constraint**: Ensures department managers have user accounts
- **Employee Access Validation**: Validates access when creating/modifying employees
- **Leave Access Validation**: Validates access when creating/modifying leave requests
- **Approval Access Control**: Ensures only authorized managers can approve/refuse

## Compatibility

- **Odoo Version**: 18.0
- **Dependencies**: `hr`, `hr_holidays`
- **License**: LGPL-3
- **Upgrade Safe**: Yes, no core module modifications

## Security Considerations

- All access control is implemented at the database level through record rules
- Business logic validation provides additional security layers
- No bypass mechanisms for unauthorized access
- Proper group-based permission structure
- Audit trail maintained for all operations

## Troubleshooting

### Common Issues

**Manager Cannot See Department Employees:**
- Ensure the manager is assigned to the department
- Verify the manager has a user account
- Check that the manager has the correct security groups

**Leave Requests Not Visible:**
- Verify employee is in the manager's department
- Check department manager assignment
- Ensure proper user group assignments

**Access Denied Errors:**
- Verify user has required security groups
- Check employee record has proper department assignment
- Ensure department has a manager assigned

### Debugging

Enable developer mode and check:
1. User's employee record and department
2. Department manager assignment
3. Security group membership
4. Record rule evaluation logs

## Support

For technical support and customizations, please contact the development team.

## Changelog

### Version 18.0.1.0.0
- Initial release
- Department-based access control implementation
- Record rules for hr.employee and hr.leave models
- Security group configuration
- Business logic validation
- Dashboard and reporting methods