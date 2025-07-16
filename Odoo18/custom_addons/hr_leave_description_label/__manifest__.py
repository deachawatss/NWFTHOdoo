# -*- coding: utf-8 -*-
{
    "name": "HR Leave Description Label",
    "version": "1.0",
    "summary": "Customized description field for leave requests",
    "category": "Human Resources/Time Off",
    "author": "Custom Developer",
    "website": "https://yourwebsite.example.com",
    "description": """
Customized description field for leave requests with translation support.
    """,
    "depends": ["hr_holidays"],
    "data": [
        "views/hr_leave_views.xml",
    ],
    "installable": True,
    "application": False,
    "auto_install": False,
    "license": "LGPL-3",
}
