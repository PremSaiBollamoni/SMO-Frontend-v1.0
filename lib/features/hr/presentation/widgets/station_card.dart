import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/station_models.dart';

class StationCard extends StatelessWidget {
  final StationModel station;
  final List<OperationModel> operations;
  final void Function(int opId) onAssignOperation;
  final VoidCallback onDelete;
  final void Function(String wsCode, String? machineCode) onEdit;

  const StationCard({
    super.key,
    required this.station,
    required this.operations,
    required this.onAssignOperation,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final op = station.operation;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _Badge(station.wsCode),
            const SizedBox(width: 8),
            if (station.machineCode != null)
              _MachineChip(station.machineCode!),
            const Spacer(),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'assign') _showAssignDialog(context);
                if (v == 'edit') _showEditDialog(context);
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'assign', child: Row(children: [Icon(Icons.link_rounded, size: 16), SizedBox(width: 8), Text('Assign Operation')])),
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit Station')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
              ],
            ),
          ]),
          const SizedBox(height: 10),
          if (op != null) ...[
            Text(op.opName, style: AppTheme.titleMedium),
            const SizedBox(height: 4),
            Wrap(spacing: 8, children: [
              _InfoChip(Icons.grade_outlined, op.skillGrade ?? '—'),
              _InfoChip(Icons.timer_outlined,
                  op.sam != null ? '${op.sam!.toStringAsFixed(2)} min/pc' : 'No SAM'),
              _InfoChip(Icons.flag_outlined,
                  op.targetPcs != null ? '${op.targetPcs} pcs/shift' : 'No target'),
            ]),
          ] else
            Text('No operation assigned',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
        ]),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final codeCtrl = TextEditingController(text: station.wsCode);
    final machineCtrl = TextEditingController(text: station.machineCode ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Station', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: codeCtrl,
            decoration: InputDecoration(labelText: 'Station Number', prefixIcon: const Icon(Icons.workspaces_outlined, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: machineCtrl,
            decoration: InputDecoration(labelText: 'Machine Code (optional)', prefixIcon: const Icon(Icons.qr_code_2_outlined, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final mc = machineCtrl.text.trim();
              onEdit(codeCtrl.text.trim(), mc.isEmpty ? null : mc);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    int? selectedId = station.operation?.opId;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Assign Operation — ${station.wsCode}'),
          content: SizedBox(
            width: double.maxFinite,
            child: DropdownButtonFormField<int>(
              value: selectedId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Select Operation',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: operations.map((op) => DropdownMenuItem(
                    value: op.opId,
                    child: Text('${op.opCode} — ${op.opName}', overflow: TextOverflow.ellipsis),
                  )).toList(),
              onChanged: (v) => setS(() => selectedId = v),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedId != null ? () { Navigator.pop(ctx); onAssignOperation(selectedId!); } : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      );
}

class _MachineChip extends StatelessWidget {
  final String code;
  const _MachineChip(this.code);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.4))),
        child: Text(code, style: TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppTheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
      ]);
}
