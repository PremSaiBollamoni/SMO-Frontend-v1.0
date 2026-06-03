import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/api_error_helper.dart';
import 'core/widgets/dashboard_shell.dart';
import 'login_screen.dart';
import 'profile_tab.dart';
import 'core/network/api_client.dart';
import 'features/gm/presentation/widgets/pending_approvals_view.dart';
import 'features/gm/presentation/widgets/approved_process_plans_view.dart';
import 'features/gm/presentation/widgets/orders_view.dart';
import 'features/gm/presentation/widgets/master_data_view.dart';
import 'features/supervisor/presentation/screens/temp_qr_management_screen.dart';
import 'features/analytics/analytics_screen.dart';

class GmWorkspace extends StatefulWidget {
  final String empId;
  final String employeeName;
  final String role;
  final List<String> activities;

  const GmWorkspace({
    super.key,
    required this.empId,
    required this.employeeName,
    required this.role,
    required this.activities,
  });

  @override
  State<GmWorkspace> createState() => _GmWorkspaceState();
}

class _GmWorkspaceState extends State<GmWorkspace> {
  String get _empId => widget.empId.trim();

  @override
  void initState() {
    super.initState();
    ApiClient().setEmpId(_empId);
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
    final overview = <FeatureCard>[];
    final management = <FeatureCard>[];
    final account = <FeatureCard>[];

    // Overview group
    if (acts.contains('PP_APPROVE') || acts.contains('PP_VIEW_ALL')) {
      overview.add(FeatureCard(
        icon: Icons.trending_up_outlined,
        label: 'Process Plans Overview',
        screen: _GmProductionTab(empId: _empId),
        color: AppTheme.primary,
      ));
    }
    if (acts.contains('PP_VIEW_ALL')) {
      overview.add(FeatureCard(
        icon: Icons.warehouse_outlined,
        label: 'Inventory Analysis',
        screen: _GmInventoryTab(empId: _empId),
        color: AppTheme.info,
      ));
      overview.add(FeatureCard(
        icon: Icons.assessment_outlined,
        label: 'Reports',
        screen: _GmReportsTab(empId: _empId),
        color: AppTheme.tertiary,
      ));
    }

    // Management group
    if (acts.contains('PP_APPROVE')) {
      management.add(FeatureCard(
        icon: Icons.shopping_cart_outlined,
        label: 'Orders',
        screen: OrdersView(empId: _empId),
        color: AppTheme.secondary,
      ));
      management.add(FeatureCard(
        icon: Icons.pending_actions_outlined,
        label: 'Pending Approvals',
        screen: PendingApprovalsView(empId: _empId),
        color: AppTheme.warning,
      ));
    }
    if (acts.contains('PP_VIEW_ALL')) {
      management.add(FeatureCard(
        icon: Icons.account_tree_outlined,
        label: 'Process Plans',
        screen: GmApprovedProcessPlansView(empId: _empId),
        color: AppTheme.primary,
      ));
    }
    if (acts.contains('PP_APPROVE') || acts.contains('PP_VIEW_ALL')) {
      management.add(FeatureCard(
        icon: Icons.storage_outlined,
        label: 'Master Data',
        screen: MasterDataView(empId: _empId),
        color: AppTheme.info,
      ));
    }
    if (acts.contains('MANAGE_TEMP_QR_CODES')) {
      management.add(FeatureCard(
        icon: Icons.qr_code_scanner,
        label: 'Temp QR Codes',
        screen: TempQrManagementScreen(empId: _empId),
        color: AppTheme.tertiary,
      ));
    }

    // Account
    account.add(FeatureCard(
      icon: Icons.person_outline,
      label: 'My Profile',
      screen: ProfileTab(empId: _empId),
      color: AppTheme.onSurfaceVariant,
    ));
    account.add(FeatureCard(
      icon: Icons.analytics_outlined,
      label: 'Analytics',
      screen: const AnalyticsScreen(),
      color: AppTheme.info,
    ));

    final groups = <FeatureGroup>[];
    if (overview.isNotEmpty) groups.add(FeatureGroup(title: 'Overview', cards: overview));
    if (management.isNotEmpty) groups.add(FeatureGroup(title: 'Management', cards: management));
    groups.add(FeatureGroup(title: 'Account', cards: account));
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'GM Dashboard',
      employeeName: widget.employeeName,
      empId: widget.empId,
      role: widget.role,
      roleIcon: Icons.business_center_outlined,
      groups: _buildGroups(),
      onLogout: _logout,
    );
  }
}

// ─── Extracted tab widgets (self-contained, fetch their own data) ───

class _GmProductionTab extends StatefulWidget {
  final String empId;
  const _GmProductionTab({required this.empId});
  @override
  State<_GmProductionTab> createState() => _GmProductionTabState();
}

class _GmProductionTabState extends State<_GmProductionTab> {
  bool _loading = false;
  Map<String, dynamic>? _insights;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/api/insights/gm');
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() => _insights = Map<String, dynamic>.from(res.data as Map));
      }
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, ApiErrorHelper.getMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _insights;
    final chartData = d != null
        ? [
            _ChartData('Pending', (d['pendingProcessPlans'] ?? 0).toDouble(), AppTheme.warning),
            _ChartData('Approved', (d['approvedProcessPlans'] ?? 0).toDouble(), AppTheme.success),
          ]
        : <_ChartData>[];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: Text('Process Plan Statistics', style: AppTheme.headlineMedium)),
              IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (d == null)
            Text('No data. Pull to refresh.', style: AppTheme.bodyLarge)
          else
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Process Plans Overview', style: AppTheme.titleLarge),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: SfCartesianChart(
                        primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0)),
                        primaryYAxis: const NumericAxis(axisLine: AxisLine(width: 0), majorTickLines: MajorTickLines(size: 0)),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CartesianSeries>[
                          ColumnSeries<_ChartData, String>(
                            dataSource: chartData,
                            xValueMapper: (_ChartData data, _) => data.category,
                            yValueMapper: (_ChartData data, _) => data.value,
                            pointColorMapper: (_ChartData data, _) => data.color,
                            dataLabelSettings: const DataLabelSettings(isVisible: true, textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GmInventoryTab extends StatefulWidget {
  final String empId;
  const _GmInventoryTab({required this.empId});
  @override
  State<_GmInventoryTab> createState() => _GmInventoryTabState();
}

class _GmInventoryTabState extends State<_GmInventoryTab> {
  bool _loading = false;
  Map<String, dynamic>? _insights;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/api/insights/gm');
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() => _insights = Map<String, dynamic>.from(res.data as Map));
      }
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, ApiErrorHelper.getMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _insights;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: Text('Inventory Analysis', style: AppTheme.headlineMedium)),
              IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (d == null)
            Text('No data. Pull to refresh.', style: AppTheme.bodyLarge)
          else ...[
            Text('Stock Summary', style: AppTheme.titleLarge),
            const SizedBox(height: 14),
            _infoRow('Total Inventory Qty', '${d['totalInventoryQty'] ?? 0}'),
            _infoRow('Active WIP Records', '${d['activeWipRecords'] ?? 0}'),
            _infoRow('Total WIP Records', '${d['totalWipRecords'] ?? 0}'),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTheme.bodyMedium)),
          Text(value, style: AppTheme.titleMedium.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _GmReportsTab extends StatefulWidget {
  final String empId;
  const _GmReportsTab({required this.empId});
  @override
  State<_GmReportsTab> createState() => _GmReportsTabState();
}

class _GmReportsTabState extends State<_GmReportsTab> {
  bool _loading = false;
  Map<String, dynamic>? _insights;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/api/insights/gm');
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() => _insights = Map<String, dynamic>.from(res.data as Map));
      }
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, ApiErrorHelper.getMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _insights;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Reports', style: AppTheme.headlineMedium),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (d == null)
            Text('No data. Pull to refresh.', style: AppTheme.bodyLarge)
          else ...[
            Row(
              children: [
                Icon(
                  d['reportStatus'] == 'READY' ? Icons.check_circle_outline : Icons.hourglass_empty,
                  color: d['reportStatus'] == 'READY' ? AppTheme.success : AppTheme.warning,
                ),
                const SizedBox(width: 8),
                Text('Report Status: ${d['reportStatus'] ?? '-'}', style: AppTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 14),
            _infoRow('Total WIP Records', '${d['totalWipRecords'] ?? 0}'),
            _infoRow('Active WIP', '${d['activeWipRecords'] ?? 0}'),
            _infoRow('Total Inventory Qty', '${d['totalInventoryQty'] ?? 0}'),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTheme.bodyMedium)),
          Text(value, style: AppTheme.titleMedium.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.category, this.value, this.color);
  final String category;
  final double value;
  final Color color;
}
