# -*- coding: utf-8 -*-
{
    'name': 'HR Department Leave Approval',
    'version': '18.0.1.0.0',
    'category': 'Human Resources/Time Off',
    'summary': 'Department-based leave approval with restricted manager visibility',
    'description': """
Department-Based Leave Approval System
======================================

This module implements department-based leave approval with the following features:

* Managers can only see employees in their own department
* Managers can only see leave requests from their department employees
* Proper record rules for hr.employee and hr.leave models
* Security groups and access rights configuration
* Manager assignment to departments

Key Features:
* Clean separation of department access
* Managers see only their team's data
* Proper Odoo 18 patterns and security implementation
* No core module modifications
* Upgrade-safe implementation

Technical Implementation:
* Record rules for hr.employee and hr.leave models
* Domain filters for department-based visibility
* Proper security configuration
* Manager-employee relationship validation
""",
    'author': 'Custom Development',
    'website': '',
    'license': 'LGPL-3',
    'depends': [
        'hr',
        'hr_holidays',
    ],
    'data': [
        'security/ir.model.access.csv',
        'security/hr_department_security.xml',
    ],
    'demo': [],
    'installable': True,
    'auto_install': False,
    'application': False,
}