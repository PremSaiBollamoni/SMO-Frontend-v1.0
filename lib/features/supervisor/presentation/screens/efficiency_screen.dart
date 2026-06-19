import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/api/job_api_service.dart';
import '../../data/models/job_assignment_model.dart';

class EfficiencyScreen extends StatefulWidget {
  final String supervisorEmpId;
  const EfficiencyScreen({super.key, required this.supervisorEmpId});

  @override
  State<EfficiencyScreen> createState() => _EfficiencyScreenState();
}

class _EfficiencyScreenState extends State<EfficiencyScreen> {
  final _api = JobApiService();
  List<ActiveJob> _jobs = [];
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
      final jobs = await _api.getAllJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs.where((j) => j.status == 'COMPLETED').toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  double _calculateOverallEfficiency() {
    if (_jobs.isEmpty) return 0;
    double totalSam = 0, totalActual = 0;
    for (final job in _jobs) {
      totalSam += job.estMinutes;
      totalActual += job.elapsedSeconds / 60.0;
    }
    return totalActual > 0 ? (totalSam / totalActual * 100) : 0;
  }

  Map<String, double> _getEmployeeEfficiency() {
    final map = <String, List<ActiveJob>>{};
    for (final job in _jobs) {
      map.putIfAbsent(job.empName, () => []).add(job);
    }
    final effMap = <String, double>{};
    for (final entry in map.entries) {
      double totalSam = 0, totalActual = 0;
      for (final job in entry.value) {
        totalSam += job.estMinutes;
        totalActual += job.elapsedSeconds / 60.0;
      }
      effMap[entry.key] = totalActual > 0 ? (totalSam / totalActual * 100) : 0;
    }
    return effMap;
  }

  @override
  Widget build(BuildContext context) {
    final overallEff = _calculateOverallEfficiency();
    final empEff = _getEmployeeEfficiency();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Efficiency Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          Text('Line performance metrics', style: TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Overall efficiency card
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    const Text('Overall Line Efficiency', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
                    const SizedBox(height: 12),
                    Text('${overallEff.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('${_jobs.length} jobs completed today',
                        style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ]),
                ),
                const SizedBox(height: 24),

                // Employee efficiency section
                if (empEff.isNotEmpty) ...[
                  const Text('Employee Efficiency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 12),
                  ...empEff.entries.map((e) {
                    final isAboveAverage = e.value >= 95;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text('${_jobs.where((j) => j.empName == e.key).length} jobs',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ]),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isAboveAverage ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isAboveAverage ? Colors.green.shade300 : Colors.orange.shade300),
                            ),
                            child: Column(children: [
                              Text('${e.value.toStringAsFixed(1)}%',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                                      color: isAboveAverage ? Colors.green.shade700 : Colors.orange.shade700)),
                              Text(isAboveAverage ? 'Good' : 'Target 95%',
                                  style: TextStyle(fontSize: 9, color: isAboveAverage ? Colors.green.shade600 : Colors.orange.shade600)),
                            ]),
                          ),
                        ]),
                      ),
                    );
                  }).toList(),
                ] else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(children: [
                        Icon(Icons.trending_up_outlined, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No jobs completed yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                      ]),
                    ),
                  ),
              ]),
            ),
    );
  }
}
