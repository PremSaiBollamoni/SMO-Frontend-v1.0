import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/job_assignment_model.dart';
import 'job_detail_widgets.dart';

class JobDetailView extends StatefulWidget {
  final ActiveJob job;
  const JobDetailView({super.key, required this.job});

  @override
  State<JobDetailView> createState() => _JobDetailViewState();
}

class _JobDetailViewState extends State<JobDetailView> {
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
      builder: (_, __) {
        final isCompleted = widget.job.status == 'COMPLETED';
        final elapsedMin = widget.job.elapsedSeconds / 60.0;
        final estMin = widget.job.estMinutes;
        final remaining = (estMin - elapsedMin).clamp(0.0, double.infinity);
        final isOverdue = !isCompleted && elapsedMin > estMin;
        // Use backend efficiency for completed jobs; live SAM-based calc for active jobs
        final efficiency = isCompleted && widget.job.efficiencyPct != null
            ? widget.job.efficiencyPct!
            : elapsedMin > 0 ? (widget.job.samValue * widget.job.bundleQty) / elapsedMin * 100 : 0.0;
        final color = isCompleted ? AppTheme.success
            : isOverdue ? AppTheme.error
            : AppTheme.success;
        final statusLabel = isCompleted ? 'COMPLETED'
            : isOverdue ? 'OVERDUE' : 'ON TRACK';
        final statusIcon = isCompleted ? Icons.task_alt_rounded
            : isOverdue ? Icons.warning_amber_rounded : Icons.check_circle_outline;

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Employee header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryVariant],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(_initials,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.job.empName, style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w800)),
                Text('Job #${widget.job.jobId} · ${widget.job.wsCode}',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statusIcon, color: color, size: 12),
                  const SizedBox(width: 4),
                  Text(statusLabel, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 10),

          // Metric boxes row
          Row(children: [
            JobMetricBox('ELAPSED', _fmtMins(elapsedMin), color, Icons.timer_outlined),
            const SizedBox(width: 8),
            JobMetricBox('ESTIMATED', _fmtMins(estMin), AppTheme.onSurfaceVariant, Icons.schedule_outlined),
            const SizedBox(width: 8),
            JobMetricBox(
              isOverdue ? 'OVER BY' : 'REMAINING',
              isCompleted ? '—' : isOverdue ? '+${_fmtMins(elapsedMin - estMin)}' : _fmtMins(remaining),
              color, Icons.hourglass_bottom_outlined,
            ),
          ]),
          const SizedBox(height: 10),

          // Live efficiency
          JobEfficiencyBar(efficiency),
          const SizedBox(height: 10),

          // SAM Comparison
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SAM Comparison', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppTheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: SamCard('Target SAM', '${widget.job.samValue.toStringAsFixed(3)}', AppTheme.primary)),
                const SizedBox(width: 8),
                Expanded(child: SamCard('Actual SAM', '${(elapsedMin / widget.job.bundleQty).toStringAsFixed(3)}', elapsedMin > widget.job.bundleQty * widget.job.samValue ? AppTheme.error : AppTheme.success)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: MetricPill('Target Pcs/Hr', '${widget.job.targetPcs ?? (widget.job.bundleQty / (widget.job.estMinutes / 60)).toStringAsFixed(1)}', Icons.trending_up_outlined, AppTheme.secondary)),
                const SizedBox(width: 8),
                Expanded(child: MetricPill('Actual Pcs/Hr', '${elapsedMin > 0 ? (widget.job.bundleQty / (elapsedMin / 60)).toStringAsFixed(1) : '0'}', Icons.speed_outlined, color)),
              ]),
            ]),
          ),
          const SizedBox(height: 10),

          // Bundle + Operation info
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: JobInfoCard('Bundle', [
              JobInfoRow(Icons.qr_code_2_outlined, widget.job.barcode),
              JobInfoRow(Icons.inventory_2_outlined, '${widget.job.bundleQty} pcs'),
            ])),
            const SizedBox(width: 8),
            Expanded(child: JobInfoCard('Operation', [
              JobInfoRow(Icons.build_circle_outlined, widget.job.opName),
              JobInfoRow(Icons.speed_outlined, '${widget.job.samValue.toStringAsFixed(2)} SAM'),
              JobInfoRow(Icons.star_outline_rounded, widget.job.skillGrade),
            ])),
          ]),
        ]);
      },
    );
  }

  String _fmtMins(double mins) {
    if (mins < 0) return '0:00';
    final totalSecs = (mins * 60).round();
    final h = (totalSecs / 3600).floor();
    final m = ((totalSecs % 3600) / 60).floor();
    final s = totalSecs % 60;
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}' : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
