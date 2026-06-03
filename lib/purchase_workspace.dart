import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/dashboard_shell.dart';
import 'login_screen.dart';
import 'profile_tab.dart';

class PurchaseWorkspace extends StatefulWidget {
  final String empId;
  final String employeeName;
  final String role;

  const PurchaseWorkspace({
    super.key,
    required this.empId,
    required this.employeeName,
    required this.role,
  });

  @override
  State<PurchaseWorkspace> createState() => _PurchaseWorkspaceState();
}

class _PurchaseWorkspaceState extends State<PurchaseWorkspace> {
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
    final vendors = <FeatureCard>[
      FeatureCard(
        icon: Icons.list_alt_outlined,
        label: 'Vendor List',
        screen: _VendorListScreen(),
        color: AppTheme.primary,
      ),
      FeatureCard(
        icon: Icons.person_add_alt_1_outlined,
        label: 'Create Vendor',
        screen: _CreateVendorScreen(),
        color: AppTheme.secondary,
      ),
      FeatureCard(
        icon: Icons.sync_alt_outlined,
        label: 'Update Vendor Status',
        screen: _UpdateVendorStatusScreen(),
        color: AppTheme.tertiary,
      ),
    ];

    final orders = <FeatureCard>[
      FeatureCard(
        icon: Icons.receipt_long_outlined,
        label: 'Create Purchase Order',
        screen: _CreatePoScreen(),
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
      FeatureGroup(title: 'Vendors', cards: vendors),
      FeatureGroup(title: 'Purchase Orders', cards: orders),
      FeatureGroup(title: 'Account', cards: account),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Purchase Manager',
      employeeName: widget.employeeName,
      empId: widget.empId,
      role: widget.role,
      roleIcon: Icons.shopping_cart_outlined,
      groups: _buildGroups(),
      onLogout: _logout,
    );
  }
}

// ─── Vendor List ───

class _VendorListScreen extends StatefulWidget {
  const _VendorListScreen();
  @override
  State<_VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<_VendorListScreen> {
  List<Map<String, dynamic>> _vendors = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/api/purchase/vendors');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final list = res.data as List;
        setState(() => _vendors = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: Text('Vendor List', style: AppTheme.headlineMedium)),
              IconButton(onPressed: _loading ? null : _fetch, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_vendors.isEmpty)
            Text('No vendors found.', style: AppTheme.bodyLarge)
          else
            ..._vendors.map((v) {
              final status = (v['status'] ?? '').toString().toUpperCase();
              final acceptable = {'ACCEPTABLE', 'APPROVED', 'ACTIVE'}.contains(status);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${v['name'] ?? '-'} (ID: ${v['vendorId'] ?? '-'})', style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('Type: ${v['type'] ?? '-'}'),
                      Text('Status: $status'),
                      const SizedBox(height: 4),
                      Text(
                        acceptable ? 'Eligible for PO' : 'Not eligible for PO yet',
                        style: AppTheme.bodySmall.copyWith(color: acceptable ? AppTheme.success : AppTheme.error, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── Create Vendor ───

class _CreateVendorScreen extends StatefulWidget {
  const _CreateVendorScreen();
  @override
  State<_CreateVendorScreen> createState() => _CreateVendorScreenState();
}

class _CreateVendorScreenState extends State<_CreateVendorScreen> {
  final _nameCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  String _status = 'PENDING';
  bool _submitting = false;

  @override
  void dispose() { _nameCtrl.dispose(); _typeCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      CustomSnackbar.showError(context, 'Vendor name is required');
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await ApiClient().dio.post('/api/purchase/vendors', data: {
        'name': _nameCtrl.text.trim(),
        'type': _typeCtrl.text.trim().isEmpty ? null : _typeCtrl.text.trim(),
        'status': _status,
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        final id = (res.data is Map) ? res.data['vendorId'] : '-';
        CustomSnackbar.showSuccess(context, 'Vendor created (ID: $id)');
        _nameCtrl.clear();
        _typeCtrl.clear();
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
        Text('Create Vendor / Supplier', style: AppTheme.headlineMedium),
        const SizedBox(height: 16),
        TextField(controller: _nameCtrl, decoration: AppTheme.inputDecoration('Vendor Name *')),
        const SizedBox(height: 12),
        TextField(controller: _typeCtrl, decoration: AppTheme.inputDecoration('Type (optional)')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _status,
          decoration: AppTheme.inputDecoration('Initial Status'),
          items: const [
            DropdownMenuItem(value: 'PENDING', child: Text('PENDING')),
            DropdownMenuItem(value: 'ACCEPTABLE', child: Text('ACCEPTABLE')),
            DropdownMenuItem(value: 'APPROVED', child: Text('APPROVED')),
            DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
            DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
          ],
          onChanged: (v) { if (v != null) setState(() => _status = v); },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: AppTheme.primaryButtonStyle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: _submitting
                ? const CircularProgressIndicator(color: AppTheme.onPrimary)
                : Text('CREATE VENDOR', style: AppTheme.labelLarge.copyWith(color: AppTheme.onPrimary, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

// ─── Update Vendor Status ───

class _UpdateVendorStatusScreen extends StatefulWidget {
  const _UpdateVendorStatusScreen();
  @override
  State<_UpdateVendorStatusScreen> createState() => _UpdateVendorStatusScreenState();
}

class _UpdateVendorStatusScreenState extends State<_UpdateVendorStatusScreen> {
  final _idCtrl = TextEditingController();
  String _status = 'ACCEPTABLE';
  bool _submitting = false;

  @override
  void dispose() { _idCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final id = int.tryParse(_idCtrl.text.trim());
    if (id == null) {
      CustomSnackbar.showError(context, 'Vendor ID is required (numeric)');
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await ApiClient().dio.patch('/api/purchase/vendors/$id/status', queryParameters: {'status': _status});
      if (!mounted) return;
      if (res.statusCode == 200) {
        CustomSnackbar.showSuccess(context, 'Vendor #$id status updated to $_status');
        _idCtrl.clear();
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
        Text('Update Vendor Status', style: AppTheme.headlineMedium),
        const SizedBox(height: 16),
        TextField(controller: _idCtrl, keyboardType: TextInputType.number, decoration: AppTheme.inputDecoration('Vendor ID *')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _status,
          decoration: AppTheme.inputDecoration('New Status *'),
          items: const [
            DropdownMenuItem(value: 'PENDING', child: Text('PENDING')),
            DropdownMenuItem(value: 'ACCEPTABLE', child: Text('ACCEPTABLE')),
            DropdownMenuItem(value: 'APPROVED', child: Text('APPROVED')),
            DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
            DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
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
                : Text('UPDATE STATUS', style: AppTheme.labelLarge.copyWith(color: AppTheme.onPrimary, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

// ─── Create Purchase Order ───

class _CreatePoScreen extends StatefulWidget {
  const _CreatePoScreen();
  @override
  State<_CreatePoScreen> createState() => _CreatePoScreenState();
}

class _CreatePoScreenState extends State<_CreatePoScreen> {
  final _vendorIdCtrl = TextEditingController();
  String _poStatus = 'CREATED';
  bool _submitting = false;

  @override
  void dispose() { _vendorIdCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final vendorId = int.tryParse(_vendorIdCtrl.text.trim());
    if (vendorId == null) {
      CustomSnackbar.showError(context, 'Vendor ID is required (numeric)');
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = await ApiClient().dio.post('/api/purchase/purchase-orders', data: {
        'vendorId': vendorId,
        'status': _poStatus,
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        final poId = (res.data is Map) ? res.data['poId'] : '-';
        CustomSnackbar.showSuccess(context, 'Purchase Order created (PO ID: $poId)');
        _vendorIdCtrl.clear();
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
        Text('Create Purchase Order', style: AppTheme.headlineMedium),
        const SizedBox(height: 10),
        Text('Only acceptable/approved/active vendors can have POs.', style: AppTheme.bodyMedium.copyWith(color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        TextField(controller: _vendorIdCtrl, keyboardType: TextInputType.number, decoration: AppTheme.inputDecoration('Vendor ID *')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _poStatus,
          decoration: AppTheme.inputDecoration('PO Status'),
          items: const [
            DropdownMenuItem(value: 'CREATED', child: Text('CREATED')),
            DropdownMenuItem(value: 'APPROVED', child: Text('APPROVED')),
            DropdownMenuItem(value: 'OPEN', child: Text('OPEN')),
          ],
          onChanged: (v) { if (v != null) setState(() => _poStatus = v); },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: AppTheme.tertiaryButtonStyle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: _submitting
                ? const CircularProgressIndicator(color: AppTheme.onPrimary)
                : Text('CREATE PO', style: AppTheme.labelLarge.copyWith(color: AppTheme.onPrimary, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
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

