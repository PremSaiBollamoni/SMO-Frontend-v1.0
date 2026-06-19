import 'package:flutter/material.dart';
import '../../data/models/attendance_models.dart';
import '../../../../core/theme/app_theme.dart';

class LogTab extends StatelessWidget {
  final List<AttendanceRecord> records;
  final bool loading;
  final VoidCallback onRefresh;

  const LogTab({super.key, required this.records, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (records.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.people_outline, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No attendance recorded today.',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.onSurfaceVariant)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        itemBuilder: (_, i) => _AttendanceRecordTile(record: records[i]),
      ),
    );
  }
}

class _AttendanceRecordTile extends StatelessWidget {
  final AttendanceRecord record;

  const _AttendanceRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final isIn = record.isCheckedIn;
    final color = isIn ? Colors.green : Colors.blue;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(isIn ? Icons.login : Icons.logout, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(record.empName.isNotEmpty ? record.empName : 'Emp ${record.empId}',
                style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('${record.tempQrToken}  •  ${record.machineCode}',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
            if (record.shiftName != null)
              Text(record.shiftName!, style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(isIn ? 'IN' : 'OUT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: isIn ? Colors.green.shade700 : Colors.blue.shade700)),
            ),
            const SizedBox(height: 4),
            Text(_fmtDt(record.checkIn),
                style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
            if (record.checkOut != null)
              Text(_fmtDt(record.checkOut!),
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
          ]),
        ]),
      ),
    );
  }

  String _fmtDt(String dt) {
    try { return dt.substring(11, 16); } catch (_) { return dt; }
  }
}
