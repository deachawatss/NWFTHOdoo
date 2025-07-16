# -*- coding: utf-8 -*-
from odoo import models, fields, api, _
from odoo.exceptions import ValidationError


class HrLeave(models.Model):
    _inherit = "hr.leave"

    name = fields.Text(string="Description (If Compensatory, Please explain your work day)")

    @api.onchange("holiday_status_id")
    def _onchange_holiday_status_id(self):
        """Set default text for compensatory leave."""
        res = super()._onchange_holiday_status_id()
        if self.holiday_status_id and self.holiday_status_id.time_type == "compensatory":
            if not self.name or self.name.strip() == "":
                self.name = _("Please explain your work day")  # Translatable text
        return res

    @api.constrains("holiday_status_id", "name")
    def _check_compensatory_description(self):
        """Enforce description for compensatory leave."""
        for record in self:
            if record.holiday_status_id and record.holiday_status_id.time_type == "compensatory":
                if not record.name or not record.name.strip():
                    raise ValidationError(
                        _("Please explain your work day for Compensatory Time Off.")
                    )
