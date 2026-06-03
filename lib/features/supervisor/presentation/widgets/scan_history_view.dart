import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../controller/temp_qr_controller.dart';

class ScanHistoryView extends StatelessWidget {
  final TempQrController controller;

  const ScanHistoryView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final history = controller.scanHistory;

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_outlined, size: 56, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No scan history', style: AppTheme.titleMedium.copyWith(color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Scans will appear here', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final scan = history[index];
        final isCheckIn = scan.scanType == 'CHECK_IN';
        final isManual = scan.scanType == 'MANUAL_UNMAP';
        final color = isCheckIn ? AppTheme.success : (isManual ? AppTheme.secondary : AppTheme.error);
        final icon = isCheckIn ? Icons.person_add_alt_1 : (isManual ? Icons.person_off_outlined : Icons.person_remove_alt_1);
        final label = scan.scanType.replaceAll('_', ' ');

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: AppTheme.cardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scan.employeeName ?? 'Employee ${scan.employeeId ?? "-"}',
                        style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'QR: ${scan.qrId} • By: ${scan.scannedBy}',
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM dd, yyyy • HH:mm:ss').format(scan.scanTime),
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
