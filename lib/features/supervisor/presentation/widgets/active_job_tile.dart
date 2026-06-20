import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/job_assignment_model.dart';

class ActiveJobTile extends StatefulWidget {
  final ActiveJob job;
  const ActiveJobTile({super.key, required this.job});

  @override
  State<ActiveJobTile> createState() => _ActiveJobTileState();
}

class _ActiveJobTileState extends State<ActiveJobTile> {
  late final Stream<int> _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Stream.periodic(const Duration(seconds: 1), (i) => i);
  }

  String get _initials {
    final parts = widget.job.empName.trim().split(' ');
    return parts.take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _ticker,
      builder: (_, snapshot) {
        final tickCount = snapshot.data ?? 0;
        final totalElapsedSecs = widget.job.elapsedSeconds + tickCount;
        final elapsedMin = totalElapsedSecs / 60.0;
        final estMin = widget.job.estMinutes;
        final isOverdue = elapsedMin > estMin;
        final statusColor = isOverdue ? AppTheme.error : AppTheme.success;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.white, Colors.grey.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1.5),
            boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [statusColor, statusColor.withValues(alpha: 0.6)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Center(child: Text(_initials, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.job.empName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(widget.job.opName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(_fmtDuration(Duration(seconds: totalElapsedSecs)), style: TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w900, color: statusColor)),
                      const SizedBox(height: 2),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text(isOverdue ? 'OVERDUE' : 'ON TRACK', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.3))),
                    ]),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _MetricChip('Qty: ${widget.job.bundleQty} pcs', Icons.inventory_2_outlined)),
                    const SizedBox(width: 8),
                    Expanded(child: _MetricChip('Est: ${widget.job.estMinutes.toStringAsFixed(0)} min', Icons.schedule_outlined)),
                  ]),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class CompletedJobTile extends StatelessWidget {
  final ActiveJob job;
  final VoidCallback onTap;
  const CompletedJobTile({super.key, required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final eff = job.efficiencyPct ?? (job.elapsedSeconds > 0 ? (job.samValue * job.bundleQty) / (job.elapsedSeconds / 60) * 100 : 0.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.task_alt_rounded, color: Colors.green.shade600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(job.empName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            Text('${job.opName} · ${job.bundleQty} pcs', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            if (job.endTime != null)
              Text('Completed: ${job.endTime.toString().substring(0, 16)}', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade300)),
            child: Text('${eff.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.green.shade700)),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 18),
        ]),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _MetricChip(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 13, color: AppTheme.primary),
        const SizedBox(width: 4),
        Flexible(child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primary), overflow: TextOverflow.ellipsis, maxLines: 1)),
      ]),
    );
  }
}
