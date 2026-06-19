import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/api/workstation_api_service.dart';
import '../../data/models/station_models.dart';

class CreateStationDialog extends StatefulWidget {
  final List<OperationModel> operations;
  const CreateStationDialog({super.key, required this.operations});

  @override
  State<CreateStationDialog> createState() => _CreateStationDialogState();
}

class _CreateStationDialogState extends State<CreateStationDialog> {
  final _wsCodeCtrl = TextEditingController();
  final _machineCtrl = TextEditingController();
  final _api = WorkstationApiService();
  OperationModel? _selectedOp;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _wsCodeCtrl.dispose();
    _machineCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final wsCode = _wsCodeCtrl.text.trim();
    if (wsCode.isEmpty) {
      setState(() => _error = 'Station code is required');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await _api.create(wsCode, _machineCtrl.text.trim().isEmpty ? null : _machineCtrl.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Station'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _field('Station Code (e.g. STN-01)', _wsCodeCtrl),
          const SizedBox(height: 12),
          _field('Machine QR Code (e.g. MACHINE-001)', _machineCtrl),
          const SizedBox(height: 12),
          DropdownButtonFormField<OperationModel>(
            value: _selectedOp,
            decoration: InputDecoration(
              labelText: 'Assign Operation (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: widget.operations.map((op) => DropdownMenuItem(
                  value: op,
                  child: Text('${op.opCode} — ${op.opName}', overflow: TextOverflow.ellipsis),
                )).toList(),
            onChanged: (v) => setState(() => _selectedOp = v),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 12)),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl) => TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      );
}
