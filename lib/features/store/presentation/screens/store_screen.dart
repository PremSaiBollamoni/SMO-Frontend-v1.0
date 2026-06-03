import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/dashboard_shell.dart';
import '../../../../login_screen.dart';
import '../../../../profile_tab.dart';
import '../controller/store_controller.dart';
import '../widgets/inventory_view.dart';
import '../widgets/manage_inventory_view.dart';
import '../widgets/stock_levels_view.dart';
import '../widgets/issue_material_view.dart';
import '../widgets/stock_movements_view.dart';
import '../widgets/items_view.dart';
import '../widgets/grn_view.dart';

/// Store Screen - Main workspace for store managers
class StoreScreen extends StatefulWidget {
  final String empId;
  final String employeeName;
  final String role;

  const StoreScreen({
    super.key,
    required this.empId,
    required this.employeeName,
    required this.role,
  });

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  @override
  void initState() {
    super.initState();
    ApiClient().setEmpId(widget.empId);
    final controller = Get.put(StoreController());
    controller.initialize(widget.empId, widget.employeeName, widget.role);
    controller.refreshAll();
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
    final inventory = <FeatureCard>[
      FeatureCard(
        icon: Icons.inventory_2_outlined,
        label: 'Inventory',
        screen: InventoryView(),
        color: AppTheme.primary,
      ),
      FeatureCard(
        icon: Icons.edit_note_outlined,
        label: 'Manage Inventory',
        screen: ManageInventoryView(),
        color: AppTheme.secondary,
      ),
      FeatureCard(
        icon: Icons.stacked_bar_chart_outlined,
        label: 'Stock Levels',
        screen: StockLevelsView(),
        color: AppTheme.info,
      ),
    ];

    final operations = <FeatureCard>[
      FeatureCard(
        icon: Icons.outbox_outlined,
        label: 'Issue Material',
        screen: IssueMaterialView(),
        color: AppTheme.secondary,
      ),
      FeatureCard(
        icon: Icons.swap_horiz_outlined,
        label: 'Stock Movements',
        screen: StockMovementsView(),
        color: AppTheme.tertiary,
      ),
      FeatureCard(
        icon: Icons.category_outlined,
        label: 'Items',
        screen: ItemsView(),
        color: AppTheme.primary,
      ),
      FeatureCard(
        icon: Icons.local_shipping_outlined,
        label: 'Receive Goods (GRN)',
        screen: GrnView(),
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
      FeatureGroup(title: 'Inventory', cards: inventory),
      FeatureGroup(title: 'Operations', cards: operations),
      FeatureGroup(title: 'Account', cards: account),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Store Manager',
      employeeName: widget.employeeName,
      empId: widget.empId,
      role: widget.role,
      roleIcon: Icons.warehouse,
      groups: _buildGroups(),
      onLogout: _logout,
    );
  }
}

