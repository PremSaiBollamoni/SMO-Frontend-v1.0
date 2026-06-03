import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/dashboard_shell.dart';
import 'login_screen.dart';
import 'profile_tab.dart';
import 'core/network/api_client.dart';

class QcWorkspace extends StatefulWidget {
  final String empId;
  final String employeeName;
  final String role;

  const QcWorkspace({
    super.key,
    required this.empId,
    required this.employeeName,
    required this.role,
  });

  @override
  State<QcWorkspace> createState() => _QcWorkspaceState();
}

class _QcWorkspaceState extends State<QcWorkspace> {
  String get _actorEmpId => widget.empId.trim();

  @override
  void initState() {
    super.initState();
    ApiClient().setEmpId(widget.empId);
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
    final inspection = <FeatureCard>[
      FeatureCard(
        icon: Icons.fact_check_outlined,
        label: 'Perform Inspection',
        screen: _QcInspectionScreen(),
        color: AppTheme.primary,
      ),
      FeatureCard(
        icon: Icons.rule_outlined,
        label: 'Approve / Reject',
        screen: _QcDecisionScreen(),
        color: AppTheme.secondary,
      ),
      FeatureCard(
        icon: Icons.replay_outlined,
        label: 'Send for Rework',
        screen: _QcReworkScreen(),
        color: AppTheme.tertiary,
      ),
    ];

    final packaging = <FeatureCard>[
      FeatureCard(
        icon: Icons.inventory_outlined,
        label: 'Packaging',
        screen: _QcPackagingScreen(),
        color: AppTheme.info,
      ),
    ];

    final account = <FeatureCard>[
      FeatureCard(
        icon: Icons.person_outline,
        label: 'My Profile',
        screen: ProfileTab(empId: _actorEmpId),
        color: AppTheme.onSurfaceVariant,
      ),
    ];

    return [
      FeatureGroup(title: 'Quality Control', cards: inspection),
      FeatureGroup(title: 'Packaging', cards: packaging),
      FeatureGroup(title: 'Account', cards: account),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'QC Engineer',
      employeeName: widget.employeeName,
      empId: widget.empId,
      role: widget.role,
      roleIcon: Icons.verified_outlined,
      groups: _buildGroups(),
      onLogout: _logout,
    );
  }
}

// ─── QC Feature Screens (self-contained) ───

class _QcInspectionScreen extends StatefulWidget {
  const _QcInspectionScreen();
  @override
  State<_QcInspectionScreen> createState() => _QcInspectionScreenState();
}

class _QcInspectionScreenState extends State<_QcInspectionScreen> {
  final _garmentIdCtrl = TextEditingController();
  final _defectsCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _garmentIdCtrl.dispose();
    _defectsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final garmentId = int.tryParse(_garmentIdCtrl.text.trim());
    if (garmentId == null) {
      CustomSnackbar.showError(context, 'Garment ID is required (numeric)');
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await ApiClient().dio.post('/api/qc/inspection', data: {
        'garmentId': garmentId,
        'status': 'INSPECTED',
        'defects': _defectsCtrl.text.trim().isEmpty ? null : _defectsCtrl.text.trim(),
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        final qcId = (res.data is Map) ? res.data['qcId'] : '-';
        CustomSnackbar.showSuccess(context, 'Inspection recorded (QC ID: $qcId)');
        _garmentIdCtrl.clear();
        _defectsCtrl.clear();
      }
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, _extractError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Perform QC Inspection', style: AppTheme.headlineMedium),
        const SizedBox(height: 16),
        TextField(controller: _garmentIdCtrl, keyboardType: TextInputType.number, decoration: AppTheme.inputDecoration('Garment ID *')),
        const SizedBox(height: 12),
        TextField(controller: _defectsCtrl, maxLines: 4, decoration: AppTheme.inputDecoration('Defects (optional)')),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: AppTheme.primaryButtonStyle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: _submitting
                ? const CircularProgressIndicator(color: AppTheme.onPrimary)
                : Text('SUBMIT INSPECTION', style: AppTheme.labelLarge.copyWith(color: AppTheme.onPrimary, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _QcDecisionScreen extends StatefulWidget {
  const _QcDecisionScreen();
  @override
  State<_QcDecisionScreen> createState() => _QcDecisionScreenState();
}

class _QcDecisionScreenState extends State<_QcDecisionScreen> {
  final _qcIdCtrl = TextEditingController();
  String _status = 'APPROVED';
  bool _submitting = false;

  @override
  void dispose() {
    _qcIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qcId = int.tryParse(_qcIdCtrl.text.trim());
    if (qcId == null) {
      CustomSnackbar.showError(context, 'QC ID is required (numeric)');
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await ApiClient().dio.patch('/api/qc/$qcId/decision', queryParameters: {'status': _status});
      if (!mounted) return;
      if (res.statusCode == 200) {
        CustomSnackbar.showSuccess(context, 'Decision updated to $_status');
        _qcIdCtrl.clear();
      }
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, _extractError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Approve / Reject', style: AppTheme.headlineMedium),
        const SizedBox(height: 16),
        TextField(controller: _qcIdCtrl, keyboardType: TextInputType.number, decoration: AppTheme.inputDecoration('QC ID *')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _status,
          decoration: AppTheme.inputDecoration('Decision Status *'),
          items: const [
            DropdownMenuItem(value: 'APPROVED', child: Text('APPROVED')),
            DropdownMenuItem(value: 'REJECTED', child: Text('REJECTED')),
          ],
          onChanged: (v) { if (v != null) setState(() => _status = v); },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: AppTheme.secondaryButtonStyle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: _submitting
                ? const CircularProgressIndicator(color: AppTheme.onPrimary)
                : Text('SUBMIT DECISION', style: AppTheme.labelLarge.copyWith(color: AppTheme.onPrimary, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _QcReworkScreen extends StatefulWidget {
  const _QcReworkScreen();
  @override
  State<_QcReworkScreen> createState() => _QcReworkScreenState();
}

class _QcReworkScreenState extends State<_QcReworkScreen> {
  final _qcIdCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _qcIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qcId = int.tryParse(_qcIdCtrl.text.trim());
    if (qcId == null) {
      CustomSnackbar.showError(context, 'QC ID is required (numeric)');
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await ApiClient().dio.patch('/api/qc/$qcId/rework');
      if (!mounted) return;
      if (res.statusCode == 200) {
        CustomSnackbar.showSuccess(context, 'Sent to rework');
        _qcIdCtrl.clear();
      }
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, _extractError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Send for Rework', style: AppTheme.headlineMedium),
        const SizedBox(height: 16),
        TextField(controller: _qcIdCtrl, keyboardType: TextInputType.number, decoration: AppTheme.inputDecoration('QC ID *')),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: AppTheme.tertiaryButtonStyle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: _submitting
                ? const CircularProgressIndicator(color: AppTheme.onPrimary)
                : Text('MARK REWORK', style: AppTheme.labelLarge.copyWith(color: AppTheme.onPrimary, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _QcPackagingScreen extends StatefulWidget {
  const _QcPackagingScreen();
  @override
  State<_QcPackagingScreen> createState() => _QcPackagingScreenState();
}

class _QcPackagingScreenState extends State<_QcPackagingScreen> {
  final _garmentIdCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  bool _packaging = false;
  List<Map<String, dynamic>> _approvedGarments = [];
  bool _loadingGarments = false;

  @override
  void initState() {
    super.initState();
    _loadApproved();
  }

  @override
  void dispose() {
    _garmentIdCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadApproved() async {
    setState(() => _loadingGarments = true);
    try {
      final res = await ApiClient().dio.get('/api/packaging/approved-garments');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final list = res.data as List;
        setState(() => _approvedGarments = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _loadingGarments = false); }
  }

  Future<void> _package() async {
    final garmentId = int.tryParse(_garmentIdCtrl.text.trim());
    if (garmentId == null) {
      CustomSnackbar.showError(context, 'Garment ID is required');
      return;
    }
    setState(() => _packaging = true);
    try {
      final res = await ApiClient().dio.post('/api/packaging/package', data: {
        'garmentId': garmentId,
        'qty': int.tryParse(_qtyCtrl.text.trim()) ?? 1,
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        _garmentIdCtrl.clear();
        _qtyCtrl.text = '1';
        CustomSnackbar.showSuccess(context, 'Garment packaged successfully');
        await _loadApproved();
      }
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, _extractError(e));
    } finally {
      if (mounted) setState(() => _packaging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadApproved,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Package Finished Goods', style: AppTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('Only APPROVED garments can be packaged.', style: AppTheme.bodyMedium.copyWith(color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 14),
          TextField(controller: _garmentIdCtrl, keyboardType: TextInputType.number, decoration: AppTheme.inputDecoration('Garment ID *')),
          const SizedBox(height: 12),
          TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: AppTheme.inputDecoration('Qty')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _packaging ? null : _package,
            style: AppTheme.tertiaryButtonStyle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: _packaging
                  ? const CircularProgressIndicator(color: AppTheme.onPrimary)
                  : Text('PACKAGE GARMENT', style: AppTheme.labelLarge.copyWith(color: AppTheme.onPrimary, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Text('Approved Garments', style: AppTheme.titleLarge)),
              IconButton(onPressed: _loadingGarments ? null : _loadApproved, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingGarments)
            const Center(child: CircularProgressIndicator())
          else if (_approvedGarments.isEmpty)
            Text('No approved garments.', style: AppTheme.bodyLarge)
          else
            ..._approvedGarments.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Garment #${g['garmentId']} • Bundle: ${g['bundleId'] ?? '-'} • ${g['status']}', style: AppTheme.bodyMedium)),
                ],
              ),
            )),
        ],
      ),
    );
  }
}

// Helper
String _extractError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) return data['message']?.toString() ?? data['error']?.toString() ?? 'API Error';
    if (data is String && data.isNotEmpty) return data;
    return e.message ?? 'Unknown network error';
  }
  return e.toString();
}

