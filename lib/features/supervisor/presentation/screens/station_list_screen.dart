import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/api/job_api_service.dart';
import '../../data/models/job_assignment_model.dart';
import '../../../hr/data/api/workstation_api_service.dart';
import '../../../hr/data/models/station_models.dart';
import 'station_detail_screen.dart';

class StationListScreen extends StatefulWidget {
  final String supervisorEmpId;
  const StationListScreen({super.key, required this.supervisorEmpId});

  @override
  State<StationListScreen> createState() => _StationListScreenState();
}

class _StationListScreenState extends State<StationListScreen> {
  final _wsApi = WorkstationApiService();
  final _jobApi = JobApiService();
  List<StationModel> _stations = [];
  Map<int, int> _activeJobCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stations = await _wsApi.getAll();
    List<ActiveJob> jobs = [];
    try { jobs = await _jobApi.getActiveJobs(); } catch (_) {}
    final counts = <int, int>{};
    for (final job in jobs) {
      counts[job.wsId] = (counts[job.wsId] ?? 0) + 1;
    }
    if (mounted) setState(() { _stations = stations; _activeJobCounts = counts; _loading = false; });
  }

  int get _totalActive => _activeJobCounts.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Bundle Tracking')),
      body: CustomScrollView(
        slivers: [
          if (!_loading)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _totalActive > 0
                      ? AppTheme.secondary.withValues(alpha: 0.1)
                      : AppTheme.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _totalActive > 0
                      ? AppTheme.secondary.withValues(alpha: 0.35)
                      : Colors.grey.shade200),
                ),
                child: Row(children: [
                  Icon(_totalActive > 0 ? Icons.circle : Icons.circle_outlined,
                      size: 10, color: _totalActive > 0 ? AppTheme.secondary : Colors.grey.shade400),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_totalActive > 0
                      ? '$_totalActive active job${_totalActive > 1 ? 's' : ''} across ${_stations.length} stations'
                      : 'No active jobs · ${_stations.length} stations ready',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13,
                          color: _totalActive > 0 ? AppTheme.secondary : AppTheme.onSurfaceVariant))),
                  GestureDetector(
                    onTap: _load,
                    child: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.onSurfaceVariant),
                  ),
                ]),
              ),
            ),
          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_stations.isEmpty)
            SliverFillRemaining(
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.workspaces_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No stations configured',
                    style: AppTheme.titleMedium.copyWith(color: AppTheme.onSurfaceVariant)),
              ])),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final station = _stations[i];
                    final count = _activeJobCounts[station.wsId] ?? 0;
                    return _StationRow(
                      station: station,
                      activeCount: count,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => StationDetailScreen(
                          station: station,
                          supervisorEmpId: widget.supervisorEmpId,
                        ),
                      )).then((_) => _load()),
                    );
                  },
                  childCount: _stations.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StationRow extends StatelessWidget {
  final StationModel station;
  final int activeCount;
  final VoidCallback onTap;
  const _StationRow({required this.station, required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = activeCount > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(color: isActive ? AppTheme.secondary : Colors.grey.shade300, width: 4),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.secondary.withValues(alpha: 0.1) : AppTheme.surfaceVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.precision_manufacturing_outlined,
                      size: 22, color: isActive ? AppTheme.secondary : AppTheme.onSurfaceVariant),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(station.wsCode,
                      style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w800)),
                  if (station.operation != null) ...[
                    const SizedBox(height: 2),
                    Text(station.operation!.opName,
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (station.machineCode != null) ...[
                    const SizedBox(height: 1),
                    Text(station.machineCode!,
                        style: AppTheme.bodySmall.copyWith(color: Colors.grey.shade400, fontSize: 10)),
                  ],
                ])),
                const SizedBox(width: 10),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$activeCount active',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Idle',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
