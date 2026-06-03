import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../login_screen.dart';
import '../../../../profile_tab.dart';
import '../controller/supervisor_controller.dart';
import '../widgets/dashboard_view.dart';
import '../widgets/wip_stats_view.dart';
import '../widgets/operator_performance_view.dart';
import '../widgets/reassign_work_view.dart';
import '../widgets/workflow_monitoring_view.dart';
import 'temp_qr_management_screen.dart';
import 'break_window_screen.dart';
import '../../../../core/utils/switch_role_helper.dart';
import '../../../../features/process_planner/presentation/widgets/approved_process_plans_view.dart';
import '../../../../features/analytics/analytics_screen.dart';

/// Supervisor Screen - Activity-driven dashboard home.
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

  @override
  void initState() {
    super.initState();
    ApiClient().setEmpId(widget.empId);
    _controller = Get.put(SupervisorController());
    _controller.initialize(widget.empId, widget.employeeName, widget.role);
    _controller.fetchFloorInsights();
  }

  @override
  void dispose() {
    Get.delete<SupervisorController>();
    super.dispose();
  }

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
    final acts = widget.activities;
    final monitoring = <FeatureCard>[];
    final operations = <FeatureCard>[];
    final planning = <FeatureCard>[];
    final account = <FeatureCard>[];

    // Monitoring group
    if (acts.contains('SUPERVISOR_MONITOR_WIP')) {
      monitoring.add(FeatureCard(
        icon: Icons.dashboard_outlined,
        label: 'Monitor WIP',
        screen: const DashboardView(),
        color: AppTheme.primary,
      ));
      monitoring.add(FeatureCard(
        icon: Icons.bar_chart_outlined,
        label: 'WIP Stats',
        screen: const WipStatsView(),
        color: AppTheme.info,
      ));
      monitoring.add(FeatureCard(
        icon: Icons.monitor_outlined,
        label: 'Workflow Monitor',
        screen: WorkflowMonitoringView(empId: widget.empId),
        color: AppTheme.tertiary,
      ));
    }
    if (acts.contains('SUPERVISOR_VIEW_OPERATOR_PERFORMANCE')) {
      monitoring.add(FeatureCard(
        icon: Icons.speed_outlined,
        label: 'Operator Performance',
        screen: const OperatorPerformanceView(),
        color: AppTheme.secondary,
      ));
    }

    // Operations group
    if (acts.contains('MANAGE_TEMP_QR_CODES')) {
      operations.add(FeatureCard(
        icon: Icons.qr_code_scanner,
        label: 'Temp QR Codes',
        screen: TempQrManagementScreen(empId: widget.empId),
        color: AppTheme.primary,
      ));
    }
    if (acts.contains('SUPERVISOR_REASSIGN_WORK')) {
      operations.add(FeatureCard(
        icon: Icons.swap_horiz_outlined,
        label: 'Reassign Work',
        screen: const ReassignWorkView(),
        color: AppTheme.secondary,
      ));
    }
    if (acts.contains('SUPERVISOR_MONITOR_WIP') || acts.contains('PP_VIEW_ALL')) {
      operations.add(FeatureCard(
        icon: Icons.free_breakfast_outlined,
        label: 'Break Windows',
        screen: const BreakWindowScreen(),
        color: AppTheme.tertiary,
      ));
    }

    // Planning group
    if (acts.contains('PP_VIEW_ALL')) {
      planning.add(FeatureCard(
        icon: Icons.account_tree_outlined,
        label: 'Process Plans',
        screen: ApprovedProcessPlansView(empId: widget.empId, activities: widget.activities),
        color: AppTheme.primary,
      ));
    }

    // Account
    account.add(FeatureCard(
      icon: Icons.person_outline,
      label: 'My Profile',
      screen: ProfileTab(empId: widget.empId.trim()),
      color: AppTheme.onSurfaceVariant,
    ));
    account.add(FeatureCard(
      icon: Icons.analytics_outlined,
      label: 'Analytics',
      screen: const AnalyticsScreen(),
      color: AppTheme.info,
    ));

    final groups = <FeatureGroup>[];
    if (monitoring.isNotEmpty) groups.add(FeatureGroup(title: 'Monitoring', cards: monitoring));
    if (operations.isNotEmpty) groups.add(FeatureGroup(title: 'Operations', cards: operations));
    if (planning.isNotEmpty) groups.add(FeatureGroup(title: 'Planning', cards: planning));
    groups.add(FeatureGroup(title: 'Account', cards: account));
    return groups;
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
