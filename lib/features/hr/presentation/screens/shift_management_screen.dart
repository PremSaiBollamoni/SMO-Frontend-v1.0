import 'package:flutter/material.dart';
import '../../data/api/shift_api_service.dart';
import '../../data/models/shift_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/create_shift_dialog.dart';
import '../widgets/add_break_dialog.dart';
import '../widgets/shift_card.dart';

class ShiftManagementScreen extends StatefulWidget {
  final String empId;

  const ShiftManagementScreen({super.key, required this.empId});

  @override
  State<ShiftManagementScreen> createState() => _ShiftManagementScreenState();
}

class _ShiftManagementScreenState extends State<ShiftManagementScreen> {
  final ShiftApiService _api = ShiftApiService();
  List<ShiftTemplateModel> _shifts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final shifts = await _api.getAllShifts();
      if (mounted) setState(() { _shifts = shifts; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _createShift() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => CreateShiftDialog(empId: int.tryParse(widget.empId) ?? 0),
    );
    if (ok == true) _load();
  }

  Future<void> _addBreak(ShiftTemplateModel shift) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AddBreakDialog(templateId: shift.templateId, shiftName: shift.shiftName),
    );
    if (ok == true) _load();
  }

  Future<void> _deleteBreak(int breakId) async {
    if (!await _confirm('Delete this break?')) return;
    try { await _api.deleteBreak(breakId); _load(); } catch (e) { _showError(e.toString()); }
  }

  Future<void> _toggleStatus(ShiftTemplateModel shift) async {
    try { await _api.toggleStatus(shift.templateId); _load(); } catch (e) { _showError(e.toString()); }
  }

  Future<void> _deleteShift(ShiftTemplateModel shift) async {
    if (!await _confirm('Delete "${shift.shiftName}"? This cannot be undone.')) return;
    try { await _api.deleteShift(shift.templateId); _load(); } catch (e) { _showError(e.toString()); }
  }

  Future<bool> _confirm(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirm'),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ?? false;

  void _showError(String msg) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(msg),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Shifts & Breaks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createShift,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Shift'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _shifts.isEmpty
                  ? _EmptyView(onAdd: _createShift)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _shifts.length,
                        itemBuilder: (_, i) => ShiftCard(
                          shift: _shifts[i],
                          onAddBreak: () => _addBreak(_shifts[i]),
                          onDeleteBreak: _deleteBreak,
                          onToggleStatus: () => _toggleStatus(_shifts[i]),
                          onDelete: () => _deleteShift(_shifts[i]),
                        ),
                      ),
                    ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    ));
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyView({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.schedule_outlined, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text('No shifts defined yet.', style: AppTheme.titleMedium.copyWith(color: AppTheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      ElevatedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Create First Shift'),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
      ),
    ]));
  }
}
