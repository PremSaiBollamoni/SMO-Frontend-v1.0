import 'package:flutter/material.dart';
import '../../data/models/shift_models.dart';
import '../../../../core/theme/app_theme.dart';

class ShiftCard extends StatelessWidget {
  final ShiftTemplateModel shift;
  final VoidCallback onAddBreak;
  final void Function(int breakId) onDeleteBreak;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const ShiftCard({
    super.key,
    required this.shift,
    required this.onAddBreak,
    required this.onDeleteBreak,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = shift.isActive;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _ShiftHeader(shift: shift, isActive: isActive, onToggleStatus: onToggleStatus, onDelete: onDelete),
        _BreaksSection(shift: shift, onAddBreak: onAddBreak, onDeleteBreak: onDeleteBreak),
      ]),
    );
  }
}

class _ShiftHeader extends StatelessWidget {
  final ShiftTemplateModel shift;
  final bool isActive;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _ShiftHeader({required this.shift, required this.isActive, required this.onToggleStatus, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primary : Colors.grey.shade400,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        const Icon(Icons.schedule, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(shift.shiftName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 2),
          Text('${_fmt(shift.startTime)} – ${_fmt(shift.endTime)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ])),
        GestureDetector(
          onTap: onToggleStatus,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(isActive ? 'ACTIVE' : 'INACTIVE',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (v) { if (v == 'delete') onDelete(); },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'delete', child: Text('Delete Shift', style: TextStyle(color: Colors.red))),
          ],
        ),
      ]),
    );
  }

  String _fmt(String t) => t.length >= 5 ? t.substring(0, 5) : t;
}

class _BreaksSection extends StatelessWidget {
  final ShiftTemplateModel shift;
  final VoidCallback onAddBreak;
  final void Function(int) onDeleteBreak;

  const _BreaksSection({required this.shift, required this.onAddBreak, required this.onDeleteBreak});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Breaks', style: AppTheme.labelMedium.copyWith(color: AppTheme.onSurfaceVariant)),
          const Spacer(),
          TextButton.icon(
            onPressed: onAddBreak,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Break'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
          ),
        ]),
        if (shift.breaks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No breaks defined.', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
          )
        else
          ...shift.breaks.map((b) => BreakTile(breakModel: b, onDelete: () => onDeleteBreak(b.breakId))),
      ]),
    );
  }
}

class BreakTile extends StatelessWidget {
  final ShiftBreakModel breakModel;
  final VoidCallback onDelete;

  const BreakTile({super.key, required this.breakModel, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.coffee, size: 16, color: AppTheme.secondary),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(breakModel.breakName, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
          Text('${_fmt(breakModel.startTime)} – ${_fmt(breakModel.endTime)}',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
        ])),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
          onPressed: onDelete,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }

  String _fmt(String t) => t.length >= 5 ? t.substring(0, 5) : t;
}
