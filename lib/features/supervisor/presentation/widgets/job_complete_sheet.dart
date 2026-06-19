import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/job_assignment_model.dart';

class JobCompleteSheet extends StatelessWidget {
  final CompletedJob job;
  const JobCompleteSheet({super.key, required this.job});

  static Future<void> show(BuildContext context, CompletedJob job) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => JobCompleteSheet(job: job),
      );

  Color get _color {
    if (job.efficiencyPct >= 150) return AppTheme.success;
    if (job.efficiencyPct >= 100) return const Color(0xFF2E7D32);
    if (job.efficiencyPct >= 85) return AppTheme.secondary;
    if (job.efficiencyPct >= 50) return Colors.orange.shade700;
    return AppTheme.error;
  }

  String get _label {
    if (job.efficiencyPct >= 150) return 'EXCELLENT';
    if (job.efficiencyPct >= 100) return 'GOOD';
    if (job.efficiencyPct >= 85) return 'MARGINAL';
    if (job.efficiencyPct >= 50) return 'LOW';
    return 'CRITICAL';
  }

  IconData get _icon {
    if (job.efficiencyPct >= 100) return Icons.emoji_events_rounded;
    if (job.efficiencyPct >= 85) return Icons.thumb_up_rounded;
    if (job.efficiencyPct >= 50) return Icons.trending_down_rounded;
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),

        // Big efficiency circle
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color.withValues(alpha: 0.1),
            border: Border.all(color: _color.withValues(alpha: 0.3), width: 3),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(_icon, color: _color, size: 28),
            const SizedBox(height: 4),
            Text('${job.efficiencyPct.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _color)),
          ]),
        ),
        const SizedBox(height: 14),

        Text('Job Complete!',
            style: AppTheme.headlineSmall.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(job.empName,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _color.withValues(alpha: 0.4)),
          ),
          child: Text(_label,
              style: TextStyle(color: _color, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1)),
        ),
        const SizedBox(height: 24),

        // Stats grid
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            _StatRow(Icons.build_circle_outlined, 'Operation', job.opName),
            _StatRow(Icons.inventory_2_outlined, 'Qty', '${job.bundleQty} pcs'),
            _StatRow(Icons.speed_outlined, 'SAM', '${job.samValue.toStringAsFixed(2)} min/pc'),
            _StatRow(Icons.schedule_outlined, 'Estimated', '${job.estMinutes.toStringAsFixed(1)} min'),
            _StatRow(Icons.timer_outlined, 'Actual', '${job.actualMinutes.toStringAsFixed(1)} min',
                valueColor: _color),
          ]),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _StatRow(this.icon, this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, size: 15, color: AppTheme.onSurfaceVariant),
      const SizedBox(width: 10),
      Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
      const Spacer(),
      Text(value, style: AppTheme.bodySmall.copyWith(
          fontWeight: FontWeight.w700, color: valueColor ?? AppTheme.onSurface)),
    ]),
  );
}
