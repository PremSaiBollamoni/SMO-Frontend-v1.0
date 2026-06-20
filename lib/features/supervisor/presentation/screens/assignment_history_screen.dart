import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/api/job_api_service.dart';
import '../../data/models/job_assignment_model.dart';
import 'job_detail_screen.dart';

class AssignmentHistoryScreen extends StatefulWidget {
  final String supervisorEmpId;
  const AssignmentHistoryScreen({super.key, required this.supervisorEmpId});

  @override
  State<AssignmentHistoryScreen> createState() => _AssignmentHistoryScreenState();
}

class _AssignmentHistoryScreenState extends State<AssignmentHistoryScreen> {
  final _api = JobApiService();
  List<ActiveJob> _history = [];
  bool _loading = true;
  String? _error;
  String _filter = 'ALL'; // ALL, TODAY, THIS_WEEK

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final jobs = await _api.getAllJobs();
      if (mounted) {
        setState(() {
          _history = jobs.where((j) => j.status == 'COMPLETED').toList();
          _history.sort((a, b) => b.endTime?.compareTo(a.endTime ?? DateTime.now()) ?? 0);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<ActiveJob> get _filtered {
    if (_filter == 'TODAY') {
      final today = DateTime.now();
      return _history.where((j) => j.endTime?.year == today.year &&
                                    j.endTime?.month == today.month &&
                                    j.endTime?.day == today.day).toList();
    }
    return _history;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Assignment History'),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: ['ALL', 'TODAY'].map((f) {
                final selected = f == _filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: selected,
                    label: Text(f, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_error != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.error_outline, color: AppTheme.error, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: TextStyle(color: AppTheme.error, fontSize: 12))),
              ]),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.history_outlined, size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No completed jobs', style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w600)),
                        ]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final job = _filtered[i];
                          final elapsed = job.elapsedSeconds / 60.0;
                          final est = job.estMinutes;
                          final effVal = job.efficiencyPct ?? (elapsed > 0 ? (job.samValue * job.bundleQty) / elapsed * 100 : 0.0);
                          final efficiency = effVal.toStringAsFixed(1);
                          final isOnTime = effVal >= 100.0;
                          return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailScreen(job: job))),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isOnTime ? Colors.green.shade200 : Colors.orange.shade200),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(job.opName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                                      const SizedBox(height: 3),
                                      Text(job.empName, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                    ]),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isOnTime ? Colors.green.shade50 : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isOnTime ? Colors.green.shade300 : Colors.orange.shade300),
                                    ),
                                    child: Text('$efficiency% Eff', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                        color: isOnTime ? Colors.green.shade700 : Colors.orange.shade700)),
                                  ),
                                ]),
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(child: _StatRow(Icons.inventory_2_outlined, '${job.bundleQty} pcs', Colors.grey.shade600)),
                                  Expanded(child: _StatRow(Icons.timer_outlined, '${elapsed.toStringAsFixed(1)} min', Colors.grey.shade600)),
                                  Expanded(child: _StatRow(Icons.schedule_outlined, '${est.toStringAsFixed(1)} min SAM', Colors.grey.shade600)),
                                ]),
                                if (job.endTime != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Completed: ${job.endTime!.toString().split('.').first}',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                                  ),
                                ],
                              ]),
                            ),
                          ));
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatRow(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: color), maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
  }
}
