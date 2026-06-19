import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../role_picker_screen.dart';
import '../routing/app_router.dart';

class SwitchRoleHelper {
  static Future<bool> hasMultipleRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('ALL_ROLES') ?? '';
    if (raw.isEmpty) return false;
    return raw.split(';;').where((s) => s.trim().isNotEmpty).length > 1;
  }

  static Future<List<Map<String, dynamic>>> loadAllRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('ALL_ROLES') ?? '';
    if (raw.isEmpty) return [];
    return raw
        .split(';;')
        .where((s) => s.trim().isNotEmpty)
        .map((entry) {
          final parts = entry.split('|');
          return <String, dynamic>{
            'roleId': int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
            'roleName': parts.length > 1 ? parts[1] : '',
            'activities': parts.length > 2 ? parts[2] : '',
          };
        })
        .toList();
  }

  static Future<void> showRolePicker(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('EMP_ID') ?? '';
    final empName = prefs.getString('EMPLOYEE_NAME') ?? '';
    final roles = await loadAllRoles();

    if (roles.length < 2) return;
    if (!context.mounted) return;

    final nav = Navigator.of(context);
    nav.push(
      MaterialPageRoute(
        builder: (pickerContext) => RolePickerScreen(
          empId: empId,
          employeeName: empName,
          roles: roles,
          onRoleSelected: (selectedRole, selectedActivities) {
            _switchToRole(
              pickerContext: pickerContext,
              role: selectedRole,
              empId: empId,
              employeeName: empName,
              activities: selectedActivities,
              prefs: prefs,
            );
          },
        ),
      ),
    );
  }

  static void _switchToRole({
    required BuildContext pickerContext,
    required String role,
    required String empId,
    required String employeeName,
    required String activities,
    required SharedPreferences prefs,
  }) {
    prefs.setString('ROLE', role);
    prefs.setString('ACTIVITIES', activities);

    final home = AppRouter.buildHomeForRole(
      role: role.toUpperCase().trim(),
      empId: empId,
      employeeName: employeeName,
      activities: activities,
    );

    if (!pickerContext.mounted) return;
    Navigator.of(pickerContext).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => home),
      (_) => false,
    );
  }
}
