# -*- coding: utf-8 -*-

from odoo import models, fields, api, _
from odoo.exceptions import ValidationError, AccessError


class HrLeave(models.Model):
    _inherit = 'hr.leave'

    @api.model
    def _get_department_leave_domain(self):
        """
        Get domain for department-based leave visibility.
        Managers can see:
        1. Their own leave requests
        2. Leave requests from employees in their managed department(s)
        """
        return [
            '|',
            ('employee_id.id', '=', self.env.user.employee_id.id),
            ('employee_id.department_id.manager_id.user_id', '=', self.env.user.id)
        ]

    def _check_department_manager_leave_access(self):
        """
        Check if current user has access to this leave record.
        Used for validation in business logic.
        """
        if self.env.user.has_group('hr_holidays.group_hr_holidays_manager'):
            # HR leave managers have full access
            return True
        
        if not self.env.user.employee_id:
            # User without employee record has no access
            return False
        
        user_employee = self.env.user.employee_id
        
        # Check if user is accessing their own leave request
        if self.employee_id.id == user_employee.id:
            return True
        
        # Check if user is a department manager and leave is from their department
        if (self.employee_id.department_id and 
            self.employee_id.department_id.manager_id and 
            self.employee_id.department_id.manager_id.user_id.id == self.env.user.id):
            return True
        
        return False

    @api.constrains('employee_id')
    def _check_employee_department_access(self):
        """
        Ensure users can only create/modify leave requests they have access to.
        This constraint helps maintain data integrity.
        """
        for leave in self:
            if not leave._check_department_manager_leave_access():
                raise ValidationError(_(
                    "You can only create or modify leave requests for employees "
                    "in your department or your own leave requests. "
                    "Employee: %s, Department: %s"
                ) % (
                    leave.employee_id.name,
                    leave.employee_id.department_id.name if leave.employee_id.department_id else _('No Department')
                ))

    def action_approve(self):
        """
        Override approve action to ensure only department managers can approve
        leave requests from their department employees.
        """
        for leave in self:
            if not leave._check_department_manager_leave_access():
                raise AccessError(_(
                    "You can only approve leave requests from employees in your department. "
                    "Employee: %s, Department: %s"
                ) % (
                    leave.employee_id.name,
                    leave.employee_id.department_id.name if leave.employee_id.department_id else _('No Department')
                ))
        
        return super(HrLeave, self).action_approve()

    def action_refuse(self):
        """
        Override refuse action to ensure only department managers can refuse
        leave requests from their department employees.
        """
        for leave in self:
            if not leave._check_department_manager_leave_access():
                raise AccessError(_(
                    "You can only refuse leave requests from employees in your department. "
                    "Employee: %s, Department: %s"
                ) % (
                    leave.employee_id.name,
                    leave.employee_id.department_id.name if leave.employee_id.department_id else _('No Department')
                ))
        
        return super(HrLeave, self).action_refuse()

    @api.model
    def get_department_leave_statistics(self):
        """
        Get leave statistics for departments managed by current user.
        Returns data useful for dashboard views and reporting.
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
            # Get leave statistics for this department
            domain = [('employee_id.department_id', '=', department.id)]
            
            total_leaves = self.search_count(domain)
            pending_leaves = self.search_count(domain + [('state', '=', 'confirm')])
            approved_leaves = self.search_count(domain + [('state', '=', 'validate')])
            refused_leaves = self.search_count(domain + [('state', '=', 'refuse')])
            
            # Get current month statistics
            from datetime import datetime
            current_month_start = datetime.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            current_month_domain = domain + [('date_from', '>=', current_month_start)]
            current_month_leaves = self.search_count(current_month_domain)
            
            stats[department.id] = {
                'name': department.name,
                'total_leaves': total_leaves,
                'pending_leaves': pending_leaves,
                'approved_leaves': approved_leaves,
                'refused_leaves': refused_leaves,
                'current_month_leaves': current_month_leaves,
            }
        
        return stats

    def get_my_team_leaves(self):
        """
        Get all leave requests from employees that the current user manages.
        Useful for manager views and dashboards.
        """
        if not self.env.user.employee_id:
            return self.env['hr.leave']
        
        managed_departments = self.env['hr.department'].search([
            ('manager_id.user_id', '=', self.env.user.id)
        ])
        
        if not managed_departments:
            # Return only the user's own leave requests
            return self.search([('employee_id', '=', self.env.user.employee_id.id)])
        
        # Return all leave requests from managed departments plus own requests
        domain = [
            '|',
            ('employee_id.id', '=', self.env.user.employee_id.id),
            ('employee_id.department_id', 'in', managed_departments.ids)
        ]
        
        return self.search(domain)

    @api.model
    def get_pending_approvals(self):
        """
        Get pending leave requests that require approval from the current user.
        Only includes requests from employees in departments managed by the user.
        """
        if not self.env.user.employee_id:
            return self.env['hr.leave']
        
        managed_departments = self.env['hr.department'].search([
            ('manager_id.user_id', '=', self.env.user.id)
        ])
        
        if not managed_departments:
            return self.env['hr.leave']
        
        # Get pending leave requests from managed departments
        domain = [
            ('employee_id.department_id', 'in', managed_departments.ids),
            ('state', '=', 'confirm'),
            ('employee_id.id', '!=', self.env.user.employee_id.id)  # Exclude own requests
        ]
        
        return self.search(domain, order='date_from asc')