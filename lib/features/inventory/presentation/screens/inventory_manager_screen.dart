import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../login_screen.dart';
import '../../../../profile_tab.dart';
import '../controllers/inventory_controller.dart';
import 'inventory_dashboard_screen.dart';
import 'manage_stock_limits_screen.dart';
import 'stock_alerts_screen.dart';
import 'stock_movements_screen.dart';
import 'daily_ledger_screen.dart';
import 'stock_management_screen.dart';
import 'wip_stock_screen.dart';

/// Inventory Manager Screen - Activity-driven dashboard home
class InventoryManagerScreen extends StatefulWidget {
  final String empId;
  final String employeeName;
  final String role;
  final List<String> activities;

  const InventoryManagerScreen({
    super.key,
    required this.empId,
    required this.employeeName,
    required this.role,
    required this.activities,
  });

  @override
  State<InventoryManagerScreen> createState() => _InventoryManagerScreenState();
}

class _InventoryManagerScreenState extends State<InventoryManagerScreen> {
  late final InventoryController _controller;

  @override
  void initState() {
    super.initState();
    ApiClient().setEmpId(widget.empId);
    _controller = Get.put(InventoryController());
    _controller.loadDashboard();
  }

  @override
  void dispose() {
    Get.delete<InventoryController>();
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
    final inventory = <FeatureCard>[];
    final management = <FeatureCard>[];
    final reports = <FeatureCard>[];
    final account = <FeatureCard>[];

    // Inventory Monitoring group
    if (acts.contains('INVENTORY_VIEW_DASHBOARD')) {
      inventory.add(FeatureCard(
        icon: Icons.dashboard_outlined,
        label: 'Stock Dashboard',
        screen: const InventoryDashboardScreen(),
        color: AppTheme.primary,
      ));
    }
    if (acts.contains('INVENTORY_VIEW_DASHBOARD')) {
      inventory.add(FeatureCard(
        icon: Icons.widgets_outlined,
        label: 'WIP Stock',
        screen: const WipStockScreen(),
        color: Colors.purple[700]!,
      ));
    }
    if (acts.contains('INVENTORY_VIEW_ALERTS')) {
      inventory.add(FeatureCard(
        icon: Icons.notifications_active_outlined,
        label: 'Stock Alerts',
        screen: const StockAlertsScreen(),
        color: AppTheme.error,
      ));
    }
    if (acts.contains('INVENTORY_VIEW_MOVEMENTS')) {
      inventory.add(FeatureCard(
        icon: Icons.swap_horiz_outlined,
        label: 'Stock Movements',
        screen: const StockMovementsScreen(),
        color: AppTheme.info,
      ));
    }

    // Stock Management group
    if (acts.contains('INVENTORY_MANAGE_RAW_MATERIALS')) {
      management.add(FeatureCard(
        icon: Icons.inventory_outlined,
        label: 'Raw Materials',
        screen: const StockManagementScreen(),
        color: AppTheme.primary,
      ));
    }
    if (acts.contains('INVENTORY_MANAGE_STOCK_LIMITS')) {
      management.add(FeatureCard(
        icon: Icons.tune_outlined,
        label: 'Manage Limits',
        screen: const ManageStockLimitsScreen(),
        color: AppTheme.secondary,
      ));
    }

    // Reports group
    if (acts.contains('INVENTORY_VIEW_DAILY_LEDGER')) {
      reports.add(FeatureCard(
        icon: Icons.calendar_today_outlined,
        label: 'Daily Ledger',
        screen: const DailyLedgerScreen(),
        color: AppTheme.info,
      ));
    }
    if (acts.contains('INVENTORY_GENERATE_REPORTS')) {
      reports.add(FeatureCard(
        icon: Icons.assessment_outlined,
        label: 'Stock Reports',
        screen: const Center(child: Text('Stock Reports - Export functionality coming soon')),
        color: AppTheme.secondary,
      ));
    }

    // Account
    account.add(FeatureCard(
      icon: Icons.person_outline,
      label: 'My Profile',
      screen: ProfileTab(empId: widget.empId.trim()),
      color: AppTheme.onSurfaceVariant,
    ));

    final groups = <FeatureGroup>[];
    if (inventory.isNotEmpty) groups.add(FeatureGroup(title: 'Inventory Monitoring', cards: inventory));
    if (management.isNotEmpty) groups.add(FeatureGroup(title: 'Stock Management', cards: management));
    if (reports.isNotEmpty) groups.add(FeatureGroup(title: 'Reports', cards: reports));
    groups.add(FeatureGroup(title: 'Account', cards: account));
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Inventory Manager',
      employeeName: widget.employeeName,
      empId: widget.empId,
      role: widget.role,
      roleIcon: Icons.inventory_2_outlined,
      groups: _buildGroups(),
      onLogout: _logout,
    );
  }
}
