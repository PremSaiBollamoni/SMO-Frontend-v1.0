import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/api_error_helper.dart';
import '../../domain/models/role_model.dart';
import '../../domain/models/employee_profile_model.dart';

/// Edit employee dialog widget
class EditEmployeeDialog extends StatefulWidget {
  final EmployeeProfileModel employee;
  final List<RoleModel> roles;
  final Function({
    required String empId,
    required String empName,
    required RoleModel role,
    String? dob,
    String? phone,
    String? address,
    required String email,
    double? salary,
    String? empDate,
    String? bloodGroup,
    String? emergencyContact,
    String? aadharNumber,
    String? panCardNumber,
    required String status,
  })
  onUpdateEmployee;

  const EditEmployeeDialog({
    super.key,
    required this.employee,
    required this.roles,
    required this.onUpdateEmployee,
  });

  @override
  State<EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<EditEmployeeDialog> {
  late TextEditingController _empNameController;
  late TextEditingController _empDobController;
  late TextEditingController _empPhoneController;
  late TextEditingController _empAddressController;
  late TextEditingController _empEmailController;
  late TextEditingController _empSalaryController;
  late TextEditingController _empDateController;
  late TextEditingController _empBloodGroupController;
  late TextEditingController _empEmergencyController;
  late TextEditingController _empAadharController;
  late TextEditingController _empPanCardController;
  late String? _selectedRoleId;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _empNameController = TextEditingController(text: widget.employee.empName);
    _empDobController = TextEditingController(text: widget.employee.dob);
    _empPhoneController = TextEditingController(text: widget.employee.phone);
    _empAddressController = TextEditingController(text: widget.employee.address);
    _empEmailController = TextEditingController(text: widget.employee.email);
    _empSalaryController = TextEditingController(
      text: widget.employee.salary.isEmpty ? '0' : widget.employee.salary,
    );
    _empDateController = TextEditingController(
      text: widget.employee.empDate.isEmpty ? '' : widget.employee.empDate,
    );
    _empBloodGroupController =
        TextEditingController(text: widget.employee.bloodGroup);
    _empEmergencyController =
        TextEditingController(text: widget.employee.emergencyContact);
    _empAadharController =
        TextEditingController(text: widget.employee.aadharNumber);
    _empPanCardController =
        TextEditingController(text: widget.employee.panCardNumber);
    _selectedRoleId = widget.employee.role.roleId.toString();
    _selectedStatus = widget.employee.status;
  }

  @override
  void dispose() {
    _empNameController.dispose();
    _empDobController.dispose();
    _empPhoneController.dispose();
    _empAddressController.dispose();
    _empEmailController.dispose();
    _empSalaryController.dispose();
    _empDateController.dispose();
    _empBloodGroupController.dispose();
    _empEmergencyController.dispose();
    _empAadharController.dispose();
    _empPanCardController.dispose();
    super.dispose();
  }

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        decoration: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkInputDecoration(label)
            : AppTheme.inputDecoration(label),
      ),
    );
  }

  void _handleUpdate() async {
    if (_selectedRoleId == null) {
      CustomSnackbar.showError(context, 'Please select a role');
      return;
    }

    final selectedRole = widget.roles.firstWhere(
      (r) => r.roleId.toString() == _selectedRoleId,
    );

    if (_empNameController.text.trim().isEmpty) {
      CustomSnackbar.showError(context, 'Employee Name is required');
      return;
    }
    if (_empEmailController.text.trim().isEmpty) {
      CustomSnackbar.showError(context, 'Email is required');
      return;
    }

    final salary = _empSalaryController.text.trim().isEmpty
        ? null
        : double.tryParse(_empSalaryController.text.trim());

    try {
      await widget.onUpdateEmployee(
        empId: widget.employee.empId,
        empName: _empNameController.text.trim(),
        role: selectedRole,
        dob: _empDobController.text.trim().isEmpty
            ? null
            : _empDobController.text.trim(),
        phone: _empPhoneController.text.trim().isEmpty
            ? null
            : _empPhoneController.text.trim(),
        address: _empAddressController.text.trim().isEmpty
            ? null
            : _empAddressController.text.trim(),
        email: _empEmailController.text.trim(),
        salary: salary,
        empDate: _empDateController.text.trim().isEmpty
            ? null
            : _empDateController.text.trim(),
        bloodGroup: _empBloodGroupController.text.trim().isEmpty
            ? null
            : _empBloodGroupController.text.trim(),
        emergencyContact: _empEmergencyController.text.trim().isEmpty
            ? null
            : _empEmergencyController.text.trim(),
        aadharNumber: _empAadharController.text.trim().isEmpty
            ? null
            : _empAadharController.text.trim(),
        panCardNumber: _empPanCardController.text.trim().isEmpty
            ? null
            : _empPanCardController.text.trim(),
        status: _selectedStatus,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, ApiErrorHelper.getMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Employee'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_empNameController, 'Employee Name'),
            _field(_empEmailController, 'Email'),
            _field(_empPhoneController, 'Phone'),
            _field(_empAddressController, 'Address'),
            _field(_empDobController, 'Date of Birth (YYYY-MM-DD)'),
            _field(_empDateController, 'Joining Date (YYYY-MM-DD)'),
            _field(_empSalaryController, 'Salary'),
            _field(_empBloodGroupController, 'Blood Group'),
            _field(_empEmergencyController, 'Emergency Contact'),
            _field(_empAadharController, 'Aadhar Number'),
            _field(_empPanCardController, 'PAN Card Number'),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DropdownButtonFormField<String>(
                value: _selectedRoleId,
                decoration: AppTheme.inputDecoration('Role'),
                items: widget.roles
                    .map(
                      (r) => DropdownMenuItem(
                        value: r.roleId.toString(),
                        child: Text(r.roleName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedRoleId = value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: AppTheme.inputDecoration('Status'),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                  DropdownMenuItem(value: 'RESIGNED', child: Text('RESIGNED')),
                  DropdownMenuItem(
                    value: 'TERMINATED',
                    child: Text('TERMINATED'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleUpdate,
          child: const Text('Update'),
        ),
      ],
    );
  }
}
