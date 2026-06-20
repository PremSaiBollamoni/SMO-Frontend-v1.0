import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/production_models.dart';

class EmployeeDetailScreen extends StatelessWidget {
  final String empName;
  final List<WorkerProduction> operations;

  const EmployeeDetailScreen({super.key, required this.empName, required this.operations});

  Color _effColor(double e) => e >= 100 ? Colors.green : e >= 80 ? Colors.orange : Colors.red;

  String get _initials {
    final parts = empName.trim().split(' ');
    return parts.take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }

  int get _totalPieces => operations.fold(0, (s, o) => s + o.totalPieces);

  double get _overallEff {
    if (operations.isEmpty) return 0;
    double totalTarget = operations.fold(0.0, (s, o) => s + o.slots.length * o.targetPcs);
    if (totalTarget == 0) return 0;
    return (_totalPieces * 100.0 / totalTarget);
  }

  void _showSlotDetail(BuildContext context, WorkerProduction op, ProductionSlot slot) {
    final color = _effColor(slot.slotEfficiencyPct);
    final sam = 60.0 / op.targetPcs;
    final actualSam = slot.piecesProduced > 0 ? 60.0 / slot.piecesProduced : 0.0;
    final barWidth = (slot.slotEfficiencyPct / 150).clamp(0.0, 1.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),

          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryVariant], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(_initials, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(empName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
                Text(op.opName, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.4))),
                child: Column(children: [
                  Text('${slot.slotEfficiencyPct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
                  Text(slot.timeLabel, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // Metrics row
          Row(children: [
            _metricBox('Pieces', '${slot.piecesProduced}', 'produced', AppTheme.primary),
            const SizedBox(width: 8),
            _metricBox('Target', '${op.targetPcs}', 'pcs/hr', Colors.orange),
            const SizedBox(width: 8),
            _metricBox('Gap', '${(slot.piecesProduced - op.targetPcs).abs()}', slot.piecesProduced >= op.targetPcs ? 'above target' : 'below target', color),
          ]),
          const SizedBox(height: 12),

          // Efficiency bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Slot Efficiency', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                Text('${slot.slotEfficiencyPct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: barWidth, backgroundColor: Colors.grey.shade100, valueColor: AlwaysStoppedAnimation(color), minHeight: 10),
              ),
              const SizedBox(height: 12),
              Row(children: [
                _samPill('Target SAM', sam.toStringAsFixed(3), AppTheme.primary),
                const SizedBox(width: 8),
                _samPill('Actual SAM', actualSam.toStringAsFixed(3), color),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _metricBox(String label, String value, String sub, Color color) => Expanded(child:
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        Text(sub, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7))),
      ]),
    ),
  );

  Widget _samPill(String label, String value, Color color) => Expanded(child:
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final eff = _overallEff;
    final effColor = _effColor(eff);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(empName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryVariant], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(_initials, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(empName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
                const SizedBox(height: 2),
                Text('${_totalPieces} pcs total · ${operations.length} operation${operations.length > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: effColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: effColor.withValues(alpha: 0.4)),
                ),
                child: Column(children: [
                  Text('${eff.toStringAsFixed(1)}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: effColor)),
                  Text('Overall', style: TextStyle(fontSize: 9, color: effColor, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // One section per operation
          ...operations.map((op) => _operationSection(context, op)),
        ]),
      ),
    );
  }

  Widget _operationSection(BuildContext context, WorkerProduction op) {
    final color = _effColor(op.efficiencyPct);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
          child: Text(op.opName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primary)),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.4))),
          child: Text('${op.efficiencyPct.toStringAsFixed(1)}%  ${op.totalPieces} pcs',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ),
      ]),
      const SizedBox(height: 8),
      ...op.slots.map((slot) {
        final slotColor = _effColor(slot.slotEfficiencyPct);
        final barWidth = (slot.slotEfficiencyPct / 150).clamp(0.0, 1.0);
        return GestureDetector(
          onTap: () => _showSlotDetail(context, op, slot),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: slotColor.withValues(alpha: 0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 5)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text(slot.timeLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ),
                const Spacer(),
                Text('${slot.piecesProduced} pcs', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: slotColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: slotColor.withValues(alpha: 0.4))),
                  child: Text('${slot.slotEfficiencyPct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: slotColor)),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade400),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: barWidth,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation(slotColor),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 3),
              Text('Target: ${op.targetPcs} pcs/hr · tap for details', style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
            ]),
          ),
        );
      }),
      const SizedBox(height: 16),
    ]);
  }
}
