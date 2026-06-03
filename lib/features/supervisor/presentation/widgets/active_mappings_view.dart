import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../controller/temp_qr_controller.dart';

class ActiveMappingsView extends StatelessWidget {
  final TempQrController controller;

  const ActiveMappingsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final mappings = controller.activeMappings;

    if (mappings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_2_outlined, size: 56, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No active check-ins', style: AppTheme.titleMedium.copyWith(color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Scan a QR to check in an employee', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mappings.length,
      itemBuilder: (context, index) {
        final mapping = mappings[index];
        final duration = DateTime.now().difference(mapping.startTime);
        final durationStr = '${duration.inHours}h ${duration.inMinutes % 60}m';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppTheme.cardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_pin_outlined, color: AppTheme.success, size: 24),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mapping.employeeName ?? 'Employee ${mapping.employeeId}',
                        style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${mapping.employeeId} • QR: ${mapping.qrId}',
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _chip(Icons.access_time, DateFormat('HH:mm').format(mapping.startTime), AppTheme.primary),
                          const SizedBox(width: 8),
                          _chip(Icons.timer_outlined, durationStr, AppTheme.secondary),
                        ],
                      ),
                    ],
                  ),
                ),
                // Checkout button
                IconButton(
                  onPressed: () => _confirmUnmap(context, mapping.id),
                  icon: const Icon(Icons.logout, size: 22),
                  tooltip: 'Check Out',
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.error.withValues(alpha: 0.1),
                    foregroundColor: AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Future<void> _confirmUnmap(BuildContext context, int mappingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Check Out', style: AppTheme.titleLarge),
        content: Text('Are you sure you want to check out this employee?', style: AppTheme.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('Check Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await controller.unmapQrCode(mappingId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Checked out successfully' : 'Failed to check out'),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
        ));
      }
    }
  }
}
