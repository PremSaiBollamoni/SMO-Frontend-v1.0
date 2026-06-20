import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/production_models.dart';

class WorkerSlotsScreen extends StatelessWidget {
  final WorkerProduction worker;
  const WorkerSlotsScreen({super.key, required this.worker});

  Color _effColor(double eff) {
    if (eff >= 100) return Colors.green;
    if (eff >= 80) return Colors.orange;
    return Colors.red;
  }

  String get _initials {
    final parts = worker.empName.trim().split(' ');
    return parts.take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }

  @override
  Widget build(BuildContext context) {
    final dayEff = worker.efficiencyPct;
    final dayColor = _effColor(dayEff);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(worker.empName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryVariant], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(_initials, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${worker.totalPieces} pcs total', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
                Text('${worker.slots.length} productive slots · Target ${worker.targetPcs}/hr', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: dayColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: dayColor.withValues(alpha: 0.4))),
                child: Column(children: [
                  Text('${dayEff.toStringAsFixed(1)}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: dayColor)),
                  Text('Day Eff', style: TextStyle(fontSize: 9, color: dayColor, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Production by Slot', style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 12),
          ...worker.slots.map((slot) {
            final color = _effColor(slot.slotEfficiencyPct);
            final barWidth = (slot.slotEfficiencyPct / 150).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                    child: Text(slot.timeLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                  ),
                  const Spacer(),
                  Text('${slot.piecesProduced} pcs', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.4))),
                    child: Text('${slot.slotEfficiencyPct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
                  ),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: barWidth,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Target: ${worker.targetPcs} pcs', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              ]),
            );
          }),
        ]),
      ),
    );
  }
}
