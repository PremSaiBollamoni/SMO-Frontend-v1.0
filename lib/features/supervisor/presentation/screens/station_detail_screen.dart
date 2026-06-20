import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/api/job_api_service.dart';
import '../../data/models/job_assignment_model.dart';
import '../../../hr/data/models/station_models.dart';
import '../widgets/active_job_tile.dart';
import '../widgets/job_detail_view.dart';
import '../widgets/qr_scan_section.dart';
import 'job_detail_screen.dart';

class StationDetailScreen extends StatefulWidget {
  final StationModel station;
  final String supervisorEmpId;
  const StationDetailScreen({super.key, required this.station, required this.supervisorEmpId});

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  final _jobApi = JobApiService();
  List<ActiveJob> _activeJobs = [];
  List<ActiveJob> _completedJobs = [];
  ActiveJob? _expandedJob;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final active = await _jobApi.getActiveJobsByStation(widget.station.wsId);
      final all = await _jobApi.getAllJobs();
      if (mounted) setState(() {
        _activeJobs = active;
        _completedJobs = all.where((j) => j.wsId == widget.station.wsId && j.status == 'COMPLETED').toList()
          ..sort((a, b) => b.endTime?.compareTo(a.endTime ?? DateTime.now()) ?? 0);
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
        title: Text(widget.station.wsCode),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _expandedJob != null
              ? _buildJobDetail()
              : _buildMainView(),
    );
  }

  Widget _buildJobDetail() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          JobDetailView(job: _expandedJob!),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _expandedJob = null),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to Jobs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildMainView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          QrScanSection(
            station: widget.station,
            supervisorEmpId: widget.supervisorEmpId,
            onJobAssigned: _load,
            onJobCompleted: () { setState(() => _expandedJob = null); _load(); },
            onError: (msg) => setState(() => _error = msg),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.error.withValues(alpha: 0.3), width: 1)),
              child: Row(children: [
                Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 18),
                const SizedBox(width: 12),
                Expanded(child: Text(_error!, style: TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.w600))),
                GestureDetector(onTap: () => setState(() => _error = null), child: Icon(Icons.close_rounded, color: AppTheme.error, size: 18)),
              ]),
            ),
          ],
          const SizedBox(height: 28),
          Row(children: [
            if (_activeJobs.isNotEmpty)
              Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)),
            if (_activeJobs.isNotEmpty) const SizedBox(width: 8),
            Text(_activeJobs.isEmpty ? 'No Active Jobs' : 'Active Jobs (${_activeJobs.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
            const Spacer(),
            GestureDetector(onTap: _load, child: Icon(Icons.refresh_rounded, color: AppTheme.primary, size: 18)),
          ]),
          const SizedBox(height: 14),
          if (_activeJobs.isEmpty)
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                child: Column(children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No active jobs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text('Assign a job above to get started', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                ]),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activeJobs.length,
              itemBuilder: (_, i) => GestureDetector(onTap: () => setState(() => _expandedJob = _activeJobs[i]), child: ActiveJobTile(job: _activeJobs[i])),
            ),

          if (_completedJobs.isNotEmpty) ...[
            const SizedBox(height: 28),
            Row(children: [
              const Icon(Icons.history_rounded, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text('Previous Jobs (${_completedJobs.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
            ]),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _completedJobs.length,
              itemBuilder: (_, i) {
                final job = _completedJobs[i];
                return CompletedJobTile(
                  job: job,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailScreen(job: job))),
                );
              },
            ),
          ],
        ]),
      ),
    );
  }
}
