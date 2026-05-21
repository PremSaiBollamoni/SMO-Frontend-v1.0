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
      return const Center(
        child: Text('No scan history'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final scan = history[index];
        final isCheckIn = scan.scanType == 'CHECK_IN';
        final isManual = scan.scanType == 'MANUAL_UNMAP';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCheckIn
                  ? AppTheme.success
                  : (isManual ? Colors.orange : AppTheme.error),
              child: Icon(
                isCheckIn
                    ? Icons.login
                    : (isManual ? Icons.remove_circle : Icons.logout),
                color: Colors.white,
              ),
            ),
            title: Text(
              'QR: ${scan.qrId}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (scan.employeeId != null)
                  Text('Employee ID: ${scan.employeeId}'),
                Text('Scanned by: ${scan.scannedBy}'),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm:ss').format(scan.scanTime),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Chip(
              label: Text(
                scan.scanType.replaceAll('_', ' '),
                style: const TextStyle(fontSize: 11),
              ),
              backgroundColor: isCheckIn
                  ? AppTheme.success.withValues(alpha: 0.2)
                  : (isManual
                      ? Colors.orange.withValues(alpha: 0.2)
                      : AppTheme.error.withValues(alpha: 0.2)),
            ),
          ),
        );
      },
    );
  }
}
