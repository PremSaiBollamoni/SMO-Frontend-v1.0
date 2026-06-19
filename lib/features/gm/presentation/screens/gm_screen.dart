import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../login_screen.dart';
import '../../../../profile_tab.dart';

class GmScreen extends StatefulWidget {
  final String empId;
  final String employeeName;
  final String role;
  final List<String> activities;

  const GmScreen({
    super.key,
    required this.empId,
    required this.employeeName,
    required this.role,
    required this.activities,
  });

  @override
  State<GmScreen> createState() => _GmScreenState();
}

class _GmScreenState extends State<GmScreen> {
  String get _empId => widget.empId.trim();
  late final List<String> _acts;

  @override
  void initState() {
    super.initState();
    ApiClient().setEmpId(_empId);
    _acts = widget.activities.map((a) => a.toUpperCase()).toList();
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
    final operations = <FeatureCard>[];

    if (_acts.contains('GM_VIEW_PRODUCTION')) {
      operations.add(FeatureCard(
        icon: Icons.factory_outlined,
        label: 'Production',
        screen: const _PlaceholderScreen(title: 'Production Report'),
        color: AppTheme.primary,
      ));
    }

    if (_acts.contains('GM_VIEW_REPORTS')) {
      operations.add(FeatureCard(
        icon: Icons.bar_chart_outlined,
        label: 'Reports',
        screen: const _PlaceholderScreen(title: 'Reports'),
        color: AppTheme.secondary,
      ));
    }

    if (_acts.contains('GM_VIEW_EFFICIENCY')) {
      operations.add(FeatureCard(
        icon: Icons.speed_outlined,
        label: 'Efficiency',
        screen: const _PlaceholderScreen(title: 'Efficiency Analysis'),
        color: AppTheme.tertiary,
      ));
    }

    final account = <FeatureCard>[
      FeatureCard(
        icon: Icons.person_outline,
        label: 'My Profile',
        screen: ProfileTab(empId: _empId),
        color: AppTheme.onSurfaceVariant,
      ),
    ];

    return [
      if (operations.isNotEmpty) FeatureGroup(title: 'Operations', cards: operations),
      FeatureGroup(title: 'Account', cards: account),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Factory Manager',
      employeeName: widget.employeeName,
      empId: widget.empId,
      role: widget.role,
      roleIcon: Icons.business_center_outlined,
      groups: _buildGroups(),
      onLogout: _logout,
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction_outlined, size: 64, color: AppTheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(title, style: AppTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Coming soon', style: AppTheme.bodyMedium.copyWith(color: AppTheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
