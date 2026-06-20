import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/api_error_helper.dart';
import '../controller/hr_controller.dart';
import 'employee_list_item.dart';
import 'edit_employee_dialog.dart';
import 'employee_roles_dialog.dart';
import 'employee_toolbar.dart';
import 'employee_bulk_bar.dart';

class EmployeesView extends StatelessWidget {
  final Function(String) onEmployeeTap;

  const EmployeesView({super.key, required this.onEmployeeTap});

  Future<void> _manageRoles(BuildContext context, HrController c, String empId, String empName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EmployeeRolesDialog(empId: empId, empName: empName, allRoles: c.roles.toList()),
    );
    if (result == true && context.mounted) {
      CustomSnackbar.showSuccess(context, 'Roles updated for $empName');
      await c.fetchEmployees();
    }
  }

  Future<void> _deleteEmployee(BuildContext context, HrController c, String empId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Employee'),
        content: const Text('Are you sure you want to delete this employee?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final success = await c.deleteEmployee(empId);
      if (context.mounted) {
        success
            ? CustomSnackbar.showSuccess(context, 'Employee deleted')
            : CustomSnackbar.showError(context, 'Failed to delete employee.');
      }
    }
  }

  Future<void> _editEmployee(BuildContext context, HrController c, String empId) async {
    final profile = await c.fetchEmployeeProfile(empId);
    if (profile == null || !context.mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EditEmployeeDialog(
        employee: profile,
        roles: c.roles.toList(),
        onUpdateEmployee: ({required empId, required empName, required role, dob, phone, address,
            required email, salary, empDate, bloodGroup, emergencyContact, aadharNumber, panCardNumber, required status}) async {
          return await c.updateEmployee(
            empId: empId, empName: empName, role: role, dob: dob, phone: phone,
            address: address, email: email, salary: salary, empDate: empDate,
            bloodGroup: bloodGroup, emergencyContact: emergencyContact,
            aadharNumber: aadharNumber, panCardNumber: panCardNumber, status: status,
          );
        },
      ),
    );
    if (context.mounted && result == true) {
      CustomSnackbar.showSuccess(context, 'Employee updated');
      await c.fetchEmployees();
    }
  }

  Future<void> _deleteBulk(BuildContext context, HrController c) async {
    final ids = c.selectedEmployeeIds.toList();
    if (ids.isEmpty) { CustomSnackbar.showError(context, 'Select employees to delete'); return; }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Employees'),
        content: Text('Delete ${ids.length} employee(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final success = await c.deleteEmployees(ids);
      if (context.mounted) {
        success
            ? CustomSnackbar.showSuccess(context, '${ids.length} employee(s) deleted')
            : CustomSnackbar.showError(context, 'Failed to delete employees.');
      }
    }
  }

  Future<void> _export(BuildContext context, HrController c) async {
    try {
      CustomSnackbar.showInfo(context, 'Preparing export...');
      final success = await c.exportEmployees();
      if (context.mounted) {
        success
            ? CustomSnackbar.showSuccess(context, 'Export successful! Check downloads.')
            : CustomSnackbar.showError(context, 'Export failed.');
      }
    } catch (e) {
      if (context.mounted) CustomSnackbar.showError(context, ApiErrorHelper.getMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HrController>();
    return Obx(() => Column(children: [
          EmployeeToolbar(onExport: () => _export(context, c)),
          EmployeeBulkBar(
            selectedCount: c.selectedEmployeeIds.length,
            onClear: c.clearEmployeeSelections,
            onDelete: () => _deleteBulk(context, c),
          ),
          Expanded(
            child: c.filteredEmployees.isEmpty
                ? Center(child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.cardDecoration,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.people_outline, size: 48, color: AppTheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text('No employees found', style: AppTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Try adjusting your search or filters',
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant),
                          textAlign: TextAlign.center),
                    ]),
                  ))
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                    itemCount: c.filteredEmployees.length,
                    itemBuilder: (_, i) {
                      final emp = c.filteredEmployees[i];
                      return EmployeeListItem(
                        employee: emp,
                        isSelected: c.selectedEmployeeIds.contains(emp.empId),
                        isSelectionMode: c.selectedEmployeeIds.isNotEmpty,
                        onTap: () => onEmployeeTap(emp.empId),
                        onLongPress: () => c.toggleEmployeeSelection(emp.empId),
                        onCheckboxChanged: () => c.toggleEmployeeSelection(emp.empId),
                        onEdit: () => _editEmployee(context, c, emp.empId),
                        onDelete: () => _deleteEmployee(context, c, emp.empId),
                        onManageRoles: () => _manageRoles(context, c, emp.empId, emp.empName),
                      );
                    },
                  ),
          ),
        ]));
  }
}
