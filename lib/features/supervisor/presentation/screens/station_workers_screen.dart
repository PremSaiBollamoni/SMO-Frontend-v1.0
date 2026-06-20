import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../hr/data/models/station_models.dart';
import '../../data/api/production_api_service.dart';
import '../../data/models/production_models.dart';
import 'worker_slots_screen.dart';

class StationWorkersScreen extends StatefulWidget {
  final StationModel station;
  const StationWorkersScreen({super.key, required this.station});

  @override
  State<StationWorkersScreen> createState() => _StationWorkersScreenState();
}

class _StationWorkersScreenState extends State<StationWorkersScreen> {
  final _api = ProductionApiService();
  List<WorkerProduction> _workers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getStationProductionToday(widget.station.wsId);
      if (mounted) setState(() { _workers = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Color _effColor(double eff) {
    if (eff >= 100) return Colors.green;
    if (eff >= 80) return Colors.orange;
    return Colors.red;
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    return parts.take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.station.wsCode),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _workers.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.people_outline, size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No production logged today', style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w600)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _workers.length,
                      itemBuilder: (_, i) {
                        final w = _workers[i];
                        final color = _effColor(w.efficiencyPct);
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerSlotsScreen(worker: w))),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: color.withValues(alpha: 0.3)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Row(children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryVariant], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(child: Text(_initials(w.empName), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(w.empName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
                                const SizedBox(height: 2),
                                Text('${w.totalPieces} pcs · ${w.slots.length} slots', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                Text(w.opName, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.4))),
                                child: Column(children: [
                                  Text('${w.efficiencyPct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
                                  Text('Eff', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                            ]),
                          ),
                        );
                      },
                    ),
    );
  }
}
