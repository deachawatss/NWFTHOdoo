# -*- coding: utf-8 -*-
{
    "name": "HR Employee ID",
    "version": "18.0.1.0.0",
    "summary": "Add Employee ID field to hr.employee",
    "description": """
        This module adds Employee ID field to employee form.
        The field will be displayed in employee form.
    """,
    "author": "NWFTH",
    "category": "Human Resources",
    "depends": ["hr"],
    "data": [
        "data/init.sql",
        "views/hr_employee_views.xml",
    ],
    "installable": True,
    "application": False,
    "auto_install": False,
    "license": "LGPL-3",
}
