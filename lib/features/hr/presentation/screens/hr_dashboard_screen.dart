import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../login_screen.dart';
import '../../../../profile_tab.dart';
import '../controller/hr_controller.dart';
import '../widgets/dashboard_view.dart';
import '../widgets/roles_view.dart';
import '../widgets/employees_view.dart';
import '../widgets/create_role_dialog.dart';
import '../widgets/create_employee_dialog.dart';
import '../../domain/models/employee_profile_model.dart';
import 'shift_management_screen.dart';

class HrDashboardScreen extends StatefulWidget {
  final String? empId;
  final String? employeeName;
  final List<String>? activities;
  final Function(bool)? setDarkMode;

  const HrDashboardScreen({
    super.key,
    this.empId,
    this.employeeName,
    this.activities,
    this.setDarkMode,
  });

  @override
  State<HrDashboardScreen> createState() => _HrDashboardScreenState();
}

class _HrDashboardScreenState extends State<HrDashboardScreen> {
  final HrController _controller = Get.put(HrController());
  String _empId = '';
  String _employeeName = 'HR';
  List<String> _acts = [];
  @override
  void initState() {
    super.initState();
    _loadSessionAndData();
  }

  Future<void> _loadSessionAndData() async {
    final prefs = await SharedPreferences.getInstance();
    _employeeName = widget.employeeName ?? prefs.getString('EMPLOYEE_NAME') ?? 'HR';
    _empId = widget.empId ?? prefs.getString('EMP_ID') ?? '';
    final stored = prefs.getString('ACTIVITIES') ?? '';
    _acts = widget.activities ??
        stored.split(',').map((a) => a.trim().toUpperCase()).where((a) => a.isNotEmpty).toList();
    ApiClient().setEmpId(_empId);
    _controller.initialize(_empId, _employeeName);
    await _controller.refreshAll();
    if (mounted) setState(() {});
  }

  bool _has(String activity) => _acts.contains(activity);

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(setDarkMode: widget.setDarkMode)),
      (route) => false,
    );
  }


  Future<void> _showEmployeeProfile(String empId) async {
    final profile = await _controller.fetchEmployeeProfile(empId);
    if (profile == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _EmployeeProfileDialog(profile: profile),
    );
  }

  Future<void> _showCreateRoleDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => CreateRoleDialog(
        onCreateRole: ({
          required int roleId,
          required String roleName,
          required String activity,
          required String status,
        }) async {
          final success = await _controller.createRole(
            roleId: roleId,
            roleName: roleName,
            activity: activity,
            status: status,
          );
          if (!mounted) return;
          if (success) {
            CustomSnackbar.showSuccess(context, 'Role created');
          } else {
            CustomSnackbar.showError(context, 'Role creation failed');
          }
        },
      ),
    );
  }

  Future<void> _showCreateEmployeeDialog() async {
    final roles = _controller.roles.toList();
    if (roles.isEmpty) {
      if (!mounted) return;
      CustomSnackbar.showError(context, 'Create at least one role first');
      return;
    }
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => CreateEmployeeDialog(
        roles: roles,
        onCreateEmployee: ({
          required String empId,
          required String empName,
          required role,
          dob,
          phone,
          address,
          required String email,
          salary,
          empDate,
          bloodGroup,
          emergencyContact,
          aadharNumber,
          panCardNumber,
          required String password,
        }) async {
          return await _controller.createEmployee(
            empId: empId,
            empName: empName,
            role: role,
            dob: dob,
            phone: phone,
            address: address,
            email: email,
            salary: salary,
            empDate: empDate,
            bloodGroup: bloodGroup,
            emergencyContact: emergencyContact,
            aadharNumber: aadharNumber,
            panCardNumber: panCardNumber,
            password: password,
          );
        },
      ),
    );
    if (!mounted) return;
    if (result != null) {
      CustomSnackbar.showSuccess(context, 'Employee created (ID: ${result['empId']})');
      await _controller.fetchEmployees();
    }
  }

  List<FeatureGroup> _buildGroups() {
    final management = <FeatureCard>[];
    if (_has('HR_DASHBOARD')) {
      management.add(FeatureCard(icon: Icons.dashboard_outlined, label: 'Dashboard', screen: DashboardView(), color: AppTheme.primary));
    }
    if (_has('HR_MANAGE_ROLES')) {
      management.add(FeatureCard(
        icon: Icons.badge_outlined, label: 'Role Management', screen: const RolesView(), color: AppTheme.secondary,
        fab: FloatingActionButton(onPressed: _showCreateRoleDialog, child: const Icon(Icons.add)),
      ));
    }
    if (_has('HR_MANAGE_EMPLOYEES')) {
      management.add(FeatureCard(
        icon: Icons.people_outlined, label: 'Employee Management',
        screen: EmployeesView(onEmployeeTap: _showEmployeeProfile), color: AppTheme.tertiary,
        fab: FloatingActionButton(onPressed: _showCreateEmployeeDialog, child: const Icon(Icons.add)),
      ));
    }
    if (_has('HR_ATTENDANCE_REPORT')) {
      management.add(FeatureCard(
        icon: Icons.fact_check_outlined, label: 'Attendance Reports',
        screen: const Center(child: Text('Attendance Reports — Coming Soon')), color: const Color(0xFF7B61FF),
      ));
    }
    if (_has('HR_MANAGE_EMPLOYEES')) {
      management.add(FeatureCard.lazy(
        icon: Icons.schedule_outlined, label: 'Shifts & Breaks',
        screenBuilder: () => ShiftManagementScreen(empId: _empId),
        color: const Color(0xFF00897B), hasOwnScaffold: true,
      ));
    }
    final account = <FeatureCard>[
      FeatureCard(icon: Icons.person_outline, label: 'My Profile', screen: ProfileTab(empId: _empId.trim()), color: AppTheme.onSurfaceVariant),
    ];
    return [
      if (management.isNotEmpty) FeatureGroup(title: 'Management', cards: management),
      FeatureGroup(title: 'Account', cards: account),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'HR / Admin',
      employeeName: _employeeName,
      empId: _empId,
      role: 'HR',
      roleIcon: Icons.admin_panel_settings_outlined,
      groups: _buildGroups(),
      onLogout: _logout,
    );
  }
}

class _EmployeeProfileDialog extends StatelessWidget {
  final EmployeeProfileModel profile;
  const _EmployeeProfileDialog({required this.profile});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Profile — ${profile.empName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Employee ID', profile.empId),
            _row('Name', profile.empName),
            _row('Role', profile.role.roleName),
            _row('Email', profile.email),
            _row('Phone', profile.phone.isEmpty ? '-' : profile.phone),
            _row('Address', profile.address.isEmpty ? '-' : profile.address),
            _row('DOB', profile.dob.isEmpty ? '-' : profile.dob),
            _row('Blood Group', profile.bloodGroup.isEmpty ? '-' : profile.bloodGroup),
            _row('Emergency', profile.emergencyContact.isEmpty ? '-' : profile.emergencyContact),
            _row('Aadhar', profile.aadharNumber.isEmpty ? '-' : profile.aadharNumber),
            _row('PAN', profile.panCardNumber.isEmpty ? '-' : profile.panCardNumber),
            _row('Status', profile.status),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
