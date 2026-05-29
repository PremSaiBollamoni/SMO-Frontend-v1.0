import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/api_error_helper.dart';
import '../../domain/models/role_model.dart';

/// Dialog to assign multiple roles to an employee.
/// Loads current roles, shows a checklist of all available roles,
/// and saves the selection via PUT /api/hr/employees/{empId}/roles.
class EmployeeRolesDialog extends StatefulWidget {
  final String empId;
  final String empName;
  final List<RoleModel> allRoles;

  const EmployeeRolesDialog({
    super.key,
    required this.empId,
    required this.empName,
    required this.allRoles,
  });

  @override
  State<EmployeeRolesDialog> createState() => _EmployeeRolesDialogState();
}

class _EmployeeRolesDialogState extends State<EmployeeRolesDialog> {
  final Dio _dio = ApiClient().dio;
  Set<int> _selectedRoleIds = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentRoles();
  }

  Future<void> _loadCurrentRoles() async {
    try {
      final response = await _dio.get('/api/hr/employees/${widget.empId}/roles');
      if (response.statusCode == 200 && response.data is List) {
        final ids = (response.data as List)
            .map((r) => (r['roleId'] as num).toInt())
            .toSet();
        if (!mounted) return;
        setState(() {
          _selectedRoleIds = ids;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // If 404 or empty, just show all roles unchecked
        _selectedRoleIds = {};
      });
    }
  }

  Future<void> _save() async {
    if (_selectedRoleIds.isEmpty) {
      setState(() => _error = 'Please select at least one role.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _dio.put(
        '/api/hr/employees/${widget.empId}/roles',
        data: {'roleIds': _selectedRoleIds.toList()},
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiErrorHelper.getMessage(e);
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.switch_account, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Assign Roles'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.empName,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select all roles this employee should have access to:',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: SingleChildScrollView(
                      child: Column(
                        children: widget.allRoles.map((role) {
                          final selected = _selectedRoleIds.contains(role.roleId);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedRoleIds.add(role.roleId);
                                } else {
                                  _selectedRoleIds.remove(role.roleId);
                                }
                              });
                            },
                            title: Text(role.roleName,
                                style: const TextStyle(fontSize: 14)),
                            subtitle: role.activity.isNotEmpty
                                ? Text(
                                    _summarize(role.activity),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            dense: true,
                            activeColor: AppTheme.primary,
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_loading || _saving) ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  String _summarize(String activities) {
    final parts = activities.split(',').map((a) => a.trim()).toList();
    if (parts.length <= 2) return parts.join(', ');
    return '${parts.take(2).join(', ')} +${parts.length - 2} more';
  }
}
