# -*- coding: utf-8 -*-

from odoo import models, fields, api, _
from odoo.exceptions import ValidationError


class HrEmployee(models.Model):
    _inherit = 'hr.employee'

    @api.model
    def _get_department_manager_domain(self):
        """
        Get domain for department manager visibility.
        Managers can see:
        1. Themselves
        2. Employees in departments they manage
        """
        return [
            '|',
            ('id', '=', self.env.user.employee_id.id),
            ('department_id.manager_id.user_id', '=', self.env.user.id)
        ]

    def _check_department_manager_access(self):
        """
        Check if current user has access to this employee record.
        Used for validation in business logic.
        """
        if self.env.user.has_group('hr.group_hr_manager'):
            # HR managers have full access
            return True
        
        if not self.env.user.employee_id:
            # User without employee record has no access
            return False
        
        user_employee = self.env.user.employee_id
        
        # Check if user is accessing their own record
        if self.id == user_employee.id:
            return True
        
        # Check if user is a department manager and employee is in their department
        if (self.department_id and 
            self.department_id.manager_id and 
            self.department_id.manager_id.user_id.id == self.env.user.id):
            return True
        
        return False

    @api.constrains('department_id')
    def _check_department_manager_constraint(self):
        """
        Ensure department manager relationships are valid.
        This constraint helps maintain data integrity.
        """
        for employee in self:
            if employee.department_id and employee.department_id.manager_id:
                # Verify that the department manager is properly set
                if not employee.department_id.manager_id.user_id:
                    raise ValidationError(_(
                        "Department manager must have an associated user account. "
                        "Please set a user for the department manager: %s"
                    ) % employee.department_id.manager_id.name)

    def get_manager_employees(self):
        """
        Get all employees that the current user manages.
        Useful for reporting and dashboard views.
        """
        if not self.env.user.employee_id:
            return self.env['hr.employee']
        
        managed_departments = self.env['hr.department'].search([
            ('manager_id.user_id', '=', self.env.user.id)
        ])
        
        if not managed_departments:
            # Return only the user's own employee record
            return self.env.user.employee_id
        
        # Return all employees in managed departments plus the manager themselves
        domain = [
            '|',
            ('id', '=', self.env.user.employee_id.id),
            ('department_id', 'in', managed_departments.ids)
        ]
        
        return self.search(domain)

    @api.model
    def get_department_statistics(self):
        """
        Get statistics for the departments managed by current user.
        Returns data useful for dashboard views.
        """
        if not self.env.user.employee_id:
            return {}
        
        managed_departments = self.env['hr.department'].search([
            ('manager_id.user_id', '=', self.env.user.id)
        ])
        
        if not managed_departments:
            return {}
        
        stats = {}
        for department in managed_departments:
            employee_count = self.search_count([
                ('department_id', '=', department.id)
            ])
            
            stats[department.id] = {
                'name': department.name,
                'employee_count': employee_count,
                'manager': department.manager_id.name if department.manager_id else False,
            }
        
        return stats