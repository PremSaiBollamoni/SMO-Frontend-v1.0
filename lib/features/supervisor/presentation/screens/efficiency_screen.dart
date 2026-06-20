import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/api/production_api_service.dart';
import '../../data/models/production_models.dart';
import 'report_screen.dart';

class EfficiencyScreen extends StatefulWidget {
  final String supervisorEmpId;
  const EfficiencyScreen({super.key, required this.supervisorEmpId});

  @override
  State<EfficiencyScreen> createState() => _EfficiencyScreenState();
}

class _EfficiencyScreenState extends State<EfficiencyScreen> {
  final _api = ProductionApiService();
  List<EmployeeEfficiency> _data = [];
  bool _loading = true;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getEfficiencyByDate(_selectedDate);
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      _selectedDate = picked;
      _load();
    }
  }

  String get _dateLabel {
    final now = DateTime.now();
    if (_isSameDay(_selectedDate, now)) return 'Today';
    if (_isSameDay(_selectedDate, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double get _overallEff {
    if (_data.isEmpty) return 0;
    return _data.map((e) => e.efficiencyPct).reduce((a, b) => a + b) / _data.length;
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
    final overall = _overallEff;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Efficiency Report'),
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 16),
            label: Text(_dateLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      floatingActionButton: _data.isEmpty ? null : FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())),
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Generate Report', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Overall card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Column(children: [
                        const Text('Overall Line Efficiency', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text('${overall.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('${_data.length} operators · $_dateLabel', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    if (_data.isEmpty)
                      Center(child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(children: [
                          Icon(Icons.trending_up_outlined, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No production logged today', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                        ]),
                      ))
                    else ...[
                      Text('Operator Efficiency', style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w800, color: Colors.black87)),
                      const SizedBox(height: 12),
                      ...() {
                        final sorted = [..._data]..sort((a, b) => b.efficiencyPct.compareTo(a.efficiencyPct));
                        return sorted.asMap().entries.map((entry) {
                          final rank = entry.key;
                          final emp = entry.value;
                          final color = _effColor(emp.efficiencyPct);
                          final bar = (emp.efficiencyPct / 150).clamp(0.0, 1.0);
                          final isTop = rank == 0;
                          final isBottom = rank == sorted.length - 1 && sorted.length > 1;
                          final rankLabel = rank == 0 ? '🥇' : rank == 1 ? '🥈' : rank == 2 ? '🥉' : '#${rank + 1}';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: isTop
                                ? AppTheme.highlightCardDecoration(AppTheme.success)
                                : isBottom
                                    ? AppTheme.highlightCardDecoration(AppTheme.error)
                                    : BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.2)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                  child: Center(child: Text(_initials(emp.empName), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 13))),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Text(rankLabel, style: const TextStyle(fontSize: 13)),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(emp.empName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                                  ]),
                                  Text(emp.operations.join(', '), style: TextStyle(fontSize: 10, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ])),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.4))),
                                  child: Column(children: [
                                    Text('${emp.efficiencyPct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
                                    Text('${emp.totalPieces} pcs', style: TextStyle(fontSize: 9, color: color)),
                                  ]),
                                ),
                              ]),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(value: bar, backgroundColor: Colors.grey.shade100, valueColor: AlwaysStoppedAnimation(color), minHeight: 5),
                              ),
                              const SizedBox(height: 4),
                              Text('${emp.productiveSlots} productive slots', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                            ]),
                          );
                        });
                      }(),
                    ],
                  ]),
                ),
    );
  }
}
