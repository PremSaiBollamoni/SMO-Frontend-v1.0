import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class JobMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const JobMetricBox(this.label, this.value, this.color, this.icon, {super.key});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border(top: BorderSide(color: color, width: 3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontFamily: 'monospace', fontSize: 12,
            fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceVariant, letterSpacing: 0.5)),
      ]),
    ),
  );
}

class JobEfficiencyBar extends StatelessWidget {
  final double efficiency;
  const JobEfficiencyBar(this.efficiency, {super.key});

  Color get _color {
    if (efficiency >= 100) return AppTheme.success;
    if (efficiency >= 85) return AppTheme.secondary;
    if (efficiency >= 50) return Colors.orange.shade700;
    return AppTheme.error;
  }

  String get _label {
    if (efficiency >= 100) return 'EXCELLENT';
    if (efficiency >= 85) return 'GOOD';
    if (efficiency >= 50) return 'MARGINAL';
    return 'LOW';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: Row(children: [
      Icon(Icons.show_chart_rounded, size: 16, color: _color),
      const SizedBox(width: 10),
      const Text('Efficiency', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.onSurface)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _color.withValues(alpha: 0.3)),
        ),
        child: Text(_label, style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.w800)),
      ),
      const SizedBox(width: 10),
      Text('${efficiency.toStringAsFixed(1)}%',
          style: TextStyle(color: _color, fontSize: 15, fontWeight: FontWeight.w900)),
    ]),
  );
}

class JobInfoCard extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  const JobInfoCard(this.title, this.rows, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w800, color: AppTheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      ...rows,
    ]),
  );
}

class JobInfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const JobInfoRow(this.icon, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, size: 13, color: AppTheme.onSurfaceVariant),
      const SizedBox(width: 6),
      Expanded(child: Text(value, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis)),
    ]),
  );
}

class SamCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const SamCard(this.label, this.value, this.color, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(children: [
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant)),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color, fontFamily: 'monospace')),
    ]),
  );
}

class MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const MetricPill(this.label, this.value, this.icon, this.color, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant)),
      ]),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color, fontFamily: 'monospace')),
    ]),
  );
}
