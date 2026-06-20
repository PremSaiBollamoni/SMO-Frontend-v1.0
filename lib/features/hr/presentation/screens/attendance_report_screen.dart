import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_setup.dart';
import '../../../../core/theme/app_theme.dart';

class _AttRecord {
  final String empName;
  final String status;
  final String? checkIn;
  final String? checkOut;
  final String shift;

  _AttRecord({required this.empName, required this.status, this.checkIn, this.checkOut, required this.shift});

  factory _AttRecord.fromJson(Map<String, dynamic> j) {
    String fmt(String? dt) {
      if (dt == null) return '—';
      try {
        final t = DateTime.parse(dt);
        return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      } catch (_) { return dt; }
    }
    return _AttRecord(
      empName: j['empName'] ?? 'Unknown',
      status: j['status'] ?? '—',
      checkIn: fmt(j['checkIn']),
      checkOut: fmt(j['checkOut']),
      shift: j['shiftName'] ?? '—',
    );
  }
}

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  late final Dio _dio;
  DateTime _selectedDate = DateTime.now();
  List<_AttRecord> _records = [];
  bool _loading = true;
  String? _error;
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    _dio = createDio(AppConfig.baseUrl);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final d = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final res = await _dio.get('/api/attendance/date', queryParameters: {'date': d});
      final list = (res.data as List).map((j) => _AttRecord.fromJson(j)).toList();
      if (mounted) setState(() { _records = list; _loading = false; });
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
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
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

  List<_AttRecord> get _filtered {
    if (_filter == 'ALL') return _records;
    return _records.where((r) => r.status == _filter).toList();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'CHECKED_OUT': return Colors.green;
      case 'CHECKED_IN': return Colors.blue;
      case 'ABSENT': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'CHECKED_OUT': return 'Checked Out';
      case 'CHECKED_IN': return 'Present';
      case 'ABSENT': return 'Absent';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final present = _records.where((r) => r.status == 'CHECKED_IN' || r.status == 'CHECKED_OUT').length;
    final absent = _records.where((r) => r.status == 'ABSENT').length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Attendance Reports'),
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white70),
            label: Text(_dateLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : Column(children: [
                  _summaryBar(present, absent),
                  _filterChips(),
                  Expanded(child: _filtered.isEmpty ? _emptyView() : _list()),
                ]),
    );
  }

  Widget _summaryBar(int present, int absent) => Container(
    color: AppTheme.primary,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: Row(children: [
      _summaryTile('Total', _records.length.toString(), Colors.white),
      const SizedBox(width: 12),
      _summaryTile('Present', present.toString(), Colors.greenAccent),
      const SizedBox(width: 12),
      _summaryTile('Absent', absent.toString(), Colors.redAccent.shade100),
    ]),
  );

  Widget _summaryTile(String label, String val, Color valColor) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: valColor)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
      ]),
    ),
  );

  Widget _filterChips() {
    final opts = ['ALL', 'CHECKED_OUT', 'CHECKED_IN', 'ABSENT'];
    final labels = {'ALL': 'All', 'CHECKED_OUT': 'Checked Out', 'CHECKED_IN': 'Present', 'ABSENT': 'Absent'};
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: opts.map((o) {
        final active = _filter == o;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _filter = o),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppTheme.primary : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(labels[o]!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: active ? Colors.white : Colors.grey.shade600)),
            ),
          ),
        );
      }).toList()),
    );
  }

  Widget _list() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: _filtered.length,
    itemBuilder: (_, i) {
      final r = _filtered[i];
      final color = _statusColor(r.status);
      final initials = r.empName.trim().split(' ').take(2)
          .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryVariant],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(initials,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.empName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 2),
            Text(r.shift, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(_statusLabel(r.status),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            ),
            const SizedBox(height: 4),
            Text('In: ${r.checkIn}  Out: ${r.checkOut}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ]),
        ]),
      );
    },
  );

  Widget _emptyView() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.people_outline_rounded, size: 56, color: Colors.grey.shade300),
    const SizedBox(height: 12),
    Text('No records for $_dateLabel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
  ]));

  Widget _errorView() => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48, color: Colors.red),
      const SizedBox(height: 12),
      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _load, child: const Text('Retry')),
    ]),
  ));
}
