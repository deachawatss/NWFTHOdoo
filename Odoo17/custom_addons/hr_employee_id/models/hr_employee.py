# -*- coding: utf-8 -*-
from odoo import models, fields, api, _
from odoo.exceptions import ValidationError


class HrEmployee(models.Model):
    _inherit = "hr.employee"

    employee_id = fields.Char(
        string="Employee ID",
        help="รหัสพนักงาน (Employee ID)",
        copy=False,
        index=True,
        tracking=True,
        required=True,
    )

    _sql_constraints = [
        ("employee_id_unique", "UNIQUE(employee_id)", "Employee ID must be unique!")
    ]

    @api.constrains("employee_id")
    def _check_employee_id_format(self):
        for record in self:
            if record.employee_id:
                if len(record.employee_id) < 3:
                    raise ValidationError(_("Employee ID must be at least 3 characters long."))
