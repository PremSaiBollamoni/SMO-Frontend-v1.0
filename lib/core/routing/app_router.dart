import 'package:flutter/material.dart';
import '../../access_denied_screen.dart';
import '../../features/hr/presentation/screens/hr_dashboard_screen.dart';
import '../../features/supervisor/presentation/screens/supervisor_screen.dart';
import '../../features/gm/presentation/screens/gm_screen.dart';
import '../../role_picker_screen.dart';
import '../../features/auth/domain/models/role_response.dart';

class AppRouter {
  static Widget buildHomeForRole({
    required String role,
    required String empId,
    required String employeeName,
    required String activities,
    Function(bool)? setDarkMode,
  }) {
    if (activities.isEmpty) {
      return AccessDeniedScreen(
        message: 'No activities assigned to your role.',
        roleName: role,
        activities: activities,
        setDarkMode: setDarkMode,
      );
    }

    final activityList = activities
        .split(',')
        .map((a) => a.trim().toUpperCase())
        .toList();

    if (activityList.any((a) => a.startsWith('HR_'))) {
      return HrDashboardScreen(
        empId: empId,
        employeeName: employeeName,
        activities: activityList,
        setDarkMode: setDarkMode,
      );
    }

    // Supervisor screen disabled due to compilation errors - TODO: Fix supervisor screens
    // if (activityList.any((a) => a.startsWith('SUPERVISOR_'))) {
    //   return SupervisorScreen(
    //     empId: empId,
    //     employeeName: employeeName,
    //     role: role,
    //     activities: activityList,
    //   );
    // }

    if (activityList.any((a) => a.startsWith('GM_'))) {
      return GmScreen(
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
      setDarkMode: setDarkMode,
    );
  }

  static void toHome({
    required BuildContext context,
    required String role,
    required String empId,
    required String employeeName,
    required String activities,
    Function(bool)? setDarkMode,
  }) {
    final home = buildHomeForRole(
      role: role,
      empId: empId,
      employeeName: employeeName,
      activities: activities,
      setDarkMode: setDarkMode,
    );
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => home));
  }

  static void toRolePicker({
    required BuildContext context,
    required RoleResponse roleResponse,
    Function(bool)? setDarkMode,
  }) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (pickerContext) => RolePickerScreen(
          empId: roleResponse.empId,
          employeeName: roleResponse.employeeName,
          roles: roleResponse.allRoles,
          onRoleSelected: (selectedRole, selectedActivities) {
            final home = buildHomeForRole(
              role: selectedRole.toUpperCase().trim(),
              empId: roleResponse.empId,
              employeeName: roleResponse.employeeName,
              activities: selectedActivities,
              setDarkMode: setDarkMode,
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
}
