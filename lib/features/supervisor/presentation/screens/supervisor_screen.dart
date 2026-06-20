import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../login_screen.dart';
import '../../../../profile_tab.dart';
import '../controller/supervisor_controller.dart';
import '../../../attendance/presentation/screens/attendance_screen.dart';
import '../../../hr/presentation/screens/sam_management_screen.dart';
import '../../../hr/presentation/screens/station_management_screen.dart';
import 'station_list_screen.dart';
import 'assignment_history_screen.dart';
import 'efficiency_screen.dart';

class SupervisorScreen extends StatefulWidget {
  final String empId;
  final String employeeName;
  final String role;
  final List<String> activities;

  const SupervisorScreen({
    super.key,
    required this.empId,
    required this.employeeName,
    required this.role,
    required this.activities,
  });

  @override
  State<SupervisorScreen> createState() => _SupervisorScreenState();
}

class _SupervisorScreenState extends State<SupervisorScreen> {
  late final SupervisorController _controller;
  late final List<String> _acts;

  @override
  void initState() {
    super.initState();
    ApiClient().setEmpId(widget.empId);
    _acts = widget.activities.map((a) => a.toUpperCase()).toList();
    _controller = Get.put(SupervisorController());
    _controller.initialize(widget.empId, widget.employeeName, widget.role);
  }

  @override
  void dispose() {
    Get.delete<SupervisorController>();
    super.dispose();
  }

  bool _has(String activity) => _acts.contains(activity);

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    ApiClient().clearEmpId();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  List<FeatureGroup> _buildGroups() {
    final tracking = <FeatureCard>[];
    final management = <FeatureCard>[];

    if (_has('SUPERVISOR_WORK_ASSIGNMENT')) {
      tracking.add(FeatureCard(
        icon: Icons.qr_code_scanner_outlined, label: 'Work Assignment',
        screen: StationListScreen(supervisorEmpId: widget.empId),
        color: AppTheme.primary, hasOwnScaffold: true,
      ));
    }
    if (_has('SUPERVISOR_EFFICIENCY')) {
      tracking.add(FeatureCard(
        icon: Icons.bar_chart_outlined, label: 'Efficiency',
        screen: EfficiencyScreen(supervisorEmpId: widget.empId),
        color: const Color(0xFF7B61FF), hasOwnScaffold: true,
      ));
    }
    if (_has('SUPERVISOR_HISTORY')) {
      tracking.add(FeatureCard(
        icon: Icons.history_outlined, label: 'Assignment History',
        screen: AssignmentHistoryScreen(supervisorEmpId: widget.empId),
        color: AppTheme.tertiary, hasOwnScaffold: true,
      ));
    }
    if (_has('SUPERVISOR_ATTENDANCE')) {
      management.add(FeatureCard.lazy(
        icon: Icons.fact_check_outlined, label: 'Attendance',
        screenBuilder: () => AttendanceScreen(supervisorEmpId: widget.empId),
        color: AppTheme.primary,
      ));
    }
    if (_has('SUPERVISOR_LINE_BALANCING')) {
      management.add(FeatureCard(
        icon: Icons.balance_outlined, label: 'Line Balancing',
        screen: const _PlaceholderScreen(title: 'Line Balancing', icon: Icons.balance_outlined),
        color: AppTheme.secondary,
      ));
    }
    if (_has('SUPERVISOR_WORK_ASSIGNMENT')) {
      management.add(FeatureCard(
        icon: Icons.timer_outlined, label: 'Operations & SAM',
        screen: const SamManagementScreen(), color: const Color(0xFFE65100), hasOwnScaffold: true,
      ));
      management.add(FeatureCard(
        icon: Icons.workspaces_outlined, label: 'Stations',
        screen: const StationManagementScreen(), color: const Color(0xFF00897B), hasOwnScaffold: true,
      ));
    }
    return [
      if (tracking.isNotEmpty) FeatureGroup(title: 'Tracking', cards: tracking),
      if (management.isNotEmpty) FeatureGroup(title: 'Management', cards: management),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Supervisor',
      employeeName: widget.employeeName,
      empId: widget.empId,
      role: widget.role,
      roleIcon: Icons.factory_outlined,
      groups: _buildGroups(),
      onLogout: _logout,
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 64, color: AppTheme.onSurfaceVariant),
      const SizedBox(height: 16),
      Text(title, style: AppTheme.headlineSmall),
      const SizedBox(height: 8),
      Text('Coming soon', style: AppTheme.bodyMedium.copyWith(color: AppTheme.onSurfaceVariant)),
    ])),
  );
}
