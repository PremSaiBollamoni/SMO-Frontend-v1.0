import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../login_screen.dart';
import '../../../../profile_tab.dart';
import '../controller/operator_controller.dart';
import '../widgets/start_work_view.dart';
import '../widgets/complete_work_view.dart';
import '../widgets/assigned_tasks_view.dart';
import '../widgets/performance_view.dart';

/// Operator Screen - Main workspace for operators
class OperatorScreen extends StatefulWidget {
  final String empId;
  final String employeeName;
  final String role;

  const OperatorScreen({
    super.key,
    required this.empId,
    required this.employeeName,
    required this.role,
  });

  @override
  State<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends State<OperatorScreen> {
  @override
  void initState() {
    super.initState();
    ApiClient().setEmpId(widget.empId);
    final controller = Get.put(OperatorController());
    controller.initialize(widget.empId, widget.employeeName, widget.role);
    controller.fetchTasks();
    controller.fetchPerformance();
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
    final work = <FeatureCard>[
      FeatureCard(
        icon: Icons.play_circle_outline,
        label: 'Start Work',
        screen: StartWorkView(),
        color: AppTheme.primary,
      ),
      FeatureCard(
        icon: Icons.task_alt_outlined,
        label: 'Complete Work',
        screen: CompleteWorkView(),
        color: AppTheme.success,
      ),
      FeatureCard(
        icon: Icons.assignment_outlined,
        label: 'Assigned Tasks',
        screen: AssignedTasksView(),
        color: AppTheme.secondary,
      ),
      FeatureCard(
        icon: Icons.insights_outlined,
        label: 'Performance',
        screen: PerformanceView(),
        color: AppTheme.info,
      ),
    ];

    final account = <FeatureCard>[
      FeatureCard(
        icon: Icons.person_outline,
        label: 'My Profile',
        screen: ProfileTab(empId: widget.empId),
        color: AppTheme.onSurfaceVariant,
      ),
    ];

    return [
      FeatureGroup(title: 'Work', cards: work),
      FeatureGroup(title: 'Account', cards: account),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Operator',
      employeeName: widget.employeeName,
      empId: widget.empId,
      role: widget.role,
      roleIcon: Icons.precision_manufacturing,
      groups: _buildGroups(),
      onLogout: _logout,
    );
  }
}

