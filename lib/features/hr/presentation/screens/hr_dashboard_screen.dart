import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../login_screen.dart';
import '../../../../profile_tab.dart';
import '../controller/hr_controller.dart';
import '../widgets/dashboard_view.dart';
import '../widgets/roles_view.dart';
import '../widgets/employees_view.dart';
import '../widgets/create_role_dialog.dart';
import '../widgets/create_employee_dialog.dart';
import '../../domain/models/employee_profile_model.dart';
import '../../../../features/analytics/analytics_screen.dart';

/// HR Dashboard Screen - Clean Architecture Implementation
class HrDashboardScreen extends StatefulWidget {
  final Function(bool)? setDarkMode;

  const HrDashboardScreen({super.key, this.setDarkMode});

  @override
  State<HrDashboardScreen> createState() => _HrDashboardScreenState();
}

class _HrDashboardScreenState extends State<HrDashboardScreen> {
  final HrController _controller = Get.put(HrController());
  String _empId = '';
  String _employeeName = 'HR';

  @override
  void initState() {
    super.initState();
    _loadSessionAndData();
  }

  Future<void> _loadSessionAndData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _employeeName = prefs.getString('EMPLOYEE_NAME') ?? 'HR';
      _empId = prefs.getString('EMP_ID') ?? '1001';

      ApiClient().setEmpId(_empId);
      _controller.initialize(_empId, _employeeName);
      await _controller.refreshAll();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Session load error: $e');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(setDarkMode: widget.setDarkMode),
      ),
      (route) => false,
    );
  }

  List<FeatureGroup> _buildGroups() {
    final management = <FeatureCard>[
      FeatureCard(
        icon: Icons.dashboard_outlined,
        label: 'Dashboard',
        screen: DashboardView(),
        color: AppTheme.primary,
      ),
      FeatureCard(
        icon: Icons.badge_outlined,
        label: 'Roles',
        screen: const RolesView(),
        color: AppTheme.secondary,
        fab: FloatingActionButton(
          onPressed: () => _showCreateRoleDialog(),
          child: const Icon(Icons.add),
        ),
      ),
      FeatureCard(
        icon: Icons.people_outlined,
        label: 'Employees',
        screen: EmployeesView(onEmployeeTap: _showEmployeeProfile),
        color: AppTheme.tertiary,
        fab: FloatingActionButton(
          onPressed: () => _showCreateEmployeeDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    ];

    final account = <FeatureCard>[
      FeatureCard(
        icon: Icons.person_outline,
        label: 'My Profile',
        screen: ProfileTab(empId: _empId.trim()),
        color: AppTheme.onSurfaceVariant,
      ),
      FeatureCard(
        icon: Icons.analytics_outlined,
        label: 'Analytics',
        screen: const AnalyticsScreen(),
        color: AppTheme.info,
      ),
    ];

    return [
      FeatureGroup(title: 'Management', cards: management),
      FeatureGroup(title: 'Account', cards: account),
    ];
  }

  Future<void> _showEmployeeProfile(String empId) async {
    final profile = await _controller.fetchEmployeeProfile(empId);
    if (profile == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _buildEmployeeProfileDialog(profile),
    );
  }

  Widget _buildEmployeeProfileDialog(EmployeeProfileModel profile) {
    return AlertDialog(
      title: Text('Profile - ${profile.empName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee ID: ${profile.empId}'),
            const SizedBox(height: 6),
            Text('Name: ${profile.empName}'),
            const SizedBox(height: 6),
            Text('Role: ${profile.role.roleName}'),
            const SizedBox(height: 6),
            Text('Email: ${profile.email}'),
            const SizedBox(height: 6),
            Text('Phone: ${profile.phone.isEmpty ? '-' : profile.phone}'),
            const SizedBox(height: 6),
            Text('Address: ${profile.address.isEmpty ? '-' : profile.address}'),
            const SizedBox(height: 6),
            Text('DOB: ${profile.dob.isEmpty ? '-' : profile.dob}'),
            const SizedBox(height: 6),
            Text('Blood Group: ${profile.bloodGroup.isEmpty ? '-' : profile.bloodGroup}'),
            const SizedBox(height: 6),
            Text('Emergency Contact: ${profile.emergencyContact.isEmpty ? '-' : profile.emergencyContact}'),
            const SizedBox(height: 6),
            Text('Aadhar: ${profile.aadharNumber.isEmpty ? '-' : profile.aadharNumber}'),
            const SizedBox(height: 6),
            Text('PAN: ${profile.panCardNumber.isEmpty ? '-' : profile.panCardNumber}'),
            const SizedBox(height: 6),
            Text('Status: ${profile.status}'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
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
      final createdEmpId = result['empId'];
      CustomSnackbar.showSuccess(context, 'Employee created successfully (ID: $createdEmpId)');
      await _controller.fetchEmployees();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'HR / Admin',
      employeeName: _employeeName,
      empId: _empId,
      role: 'HR/Admin',
      roleIcon: Icons.admin_panel_settings_outlined,
      groups: _buildGroups(),
      onLogout: _logout,
    );
  }
}

