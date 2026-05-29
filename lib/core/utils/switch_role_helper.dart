import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../role_picker_screen.dart';
import '../../login_screen.dart';
import '../../features/hr/presentation/screens/hr_dashboard_screen.dart';
import '../../features/operator/presentation/screens/operator_screen.dart';
import '../../features/store/presentation/screens/store_screen.dart';
import '../../qc_workspace.dart';
import '../../purchase_workspace.dart';
import '../../features/supervisor/presentation/screens/supervisor_screen.dart';
import '../../gm_workspace.dart';
import '../../features/process_planner/presentation/screens/process_planner_screen.dart';
import '../../access_denied_screen.dart';
import '../network/api_client.dart';

/// Utility for Switch Role feature.
/// Reads ALL_ROLES from SharedPreferences and shows the role picker.
/// Only call this when hasMultipleRoles() returns true.
class SwitchRoleHelper {
  /// Returns true if the current session has multiple roles available.
  static Future<bool> hasMultipleRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('ALL_ROLES') ?? '';
    if (raw.isEmpty) return false;
    final parts = raw.split(';;').where((s) => s.trim().isNotEmpty).toList();
    return parts.length > 1;
  }

  /// Decode ALL_ROLES string back to list of role maps.
  static Future<List<Map<String, dynamic>>> loadAllRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('ALL_ROLES') ?? '';
    if (raw.isEmpty) return [];
    return raw.split(';;')
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

  /// Show the role picker and navigate to the selected role's screen.
  /// Call this from any screen's drawer.
  static Future<void> showRolePicker(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('EMP_ID') ?? '';
    final empName = prefs.getString('EMPLOYEE_NAME') ?? '';
    final roles = await loadAllRoles();

    if (roles.length < 2 || !context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pickerContext) => RolePickerScreen(
          empId: empId,
          employeeName: empName,
          roles: roles,
          onRoleSelected: (selectedRole, selectedActivities) async {
            // Save selected role to prefs
            await prefs.setString('ROLE', selectedRole);
            await prefs.setString('ACTIVITIES', selectedActivities);

            final activityList = selectedActivities
                .split(',')
                .map((a) => a.trim().toUpperCase())
                .toList();

            final home = _buildHomeForRole(
              selectedRole.toUpperCase().trim(),
              empId,
              empName,
              selectedActivities,
              activityList,
            );

            Navigator.of(pickerContext).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => home),
              (_) => false,
            );
          },
        ),
      ),
    );
  }

  static Widget _buildHomeForRole(
    String role,
    String empId,
    String employeeName,
    String activities,
    List<String> activityList,
  ) {
    if (activities.isEmpty) {
      return AccessDeniedScreen(
        message: 'No activities assigned to your role.',
        roleName: role,
        activities: activities,
      );
    }

    if (activityList.contains('HR_DASHBOARD') || activityList.contains('ADMIN')) {
      return const HrDashboardScreen();
    }
    if (activityList.contains('OPERATOR_SCAN_BARCODE') ||
        activityList.contains('OPERATOR_COMPLETE_OPERATION')) {
      return OperatorScreen(empId: empId, employeeName: employeeName, role: role);
    }
    if (activityList.contains('STORE_MANAGE_INVENTORY') ||
        activityList.contains('STORE_RECEIVE_MATERIALS')) {
      return StoreScreen(empId: empId, employeeName: employeeName, role: role);
    }
    if (activityList.contains('PURCHASE_CREATE_PO') ||
        activityList.contains('PURCHASE_MANAGE_SUPPLIERS')) {
      return PurchaseWorkspace(empId: empId, employeeName: employeeName, role: role);
    }
    if (activityList.contains('QC_INSPECT_QUALITY') ||
        activityList.contains('QC_APPROVE_REJECT')) {
      return QcWorkspace(empId: empId, employeeName: employeeName, role: role);
    }
    if (activityList.contains('SUPERVISOR_MONITOR_WIP') ||
        activityList.contains('SUPERVISOR_QR_ASSIGNMENT') ||
        activityList.contains('SUPERVISOR_TRACKING')) {
      return SupervisorScreen(
        empId: empId,
        employeeName: employeeName,
        role: role,
        activities: activityList,
      );
    }
    if (activityList.contains('PROCESS_ROUTING')) {
      return ProcessPlannerScreen(empId: empId, employeeName: employeeName, role: role);
    }
    if (activityList.contains('GM_VIEW_PRODUCTION') ||
        activityList.contains('GM_VIEW_REPORTS')) {
      return GmWorkspace(
        empId: empId,
        employeeName: employeeName,
        role: role,
        activities: activityList,
      );
    }
    return AccessDeniedScreen(
      message: 'Your role does not have permission to access any screens.',
      roleName: role,
      activities: activities,
    );
  }
}
