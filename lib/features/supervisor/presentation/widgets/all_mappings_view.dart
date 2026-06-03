import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../controller/temp_qr_controller.dart';

class AllMappingsView extends StatelessWidget {
  final TempQrController controller;

  const AllMappingsView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final mappings = controller.allMappings;

    if (mappings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.list_alt_outlined, size: 56, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No QR mappings', style: AppTheme.titleMedium.copyWith(color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('All check-in/out records appear here', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mappings.length,
      itemBuilder: (context, index) {
        final mapping = mappings[index];
        final isActive = mapping.status == 'ACTIVE';
        final duration = mapping.endTime != null
            ? mapping.endTime!.difference(mapping.startTime)
            : DateTime.now().difference(mapping.startTime);
        final durationStr = '${duration.inHours}h ${duration.inMinutes % 60}m';
        final color = isActive ? AppTheme.success : AppTheme.onSurfaceVariant;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: AppTheme.cardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Status dot
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isActive ? Icons.radio_button_checked : Icons.check_circle_outline,
                    color: color, size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              mapping.employeeName ?? 'Employee ${mapping.employeeId}',
                              style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: color.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              isActive ? 'ACTIVE' : 'CLOSED',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'QR: ${mapping.qrId}',
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_add_alt_1, size: 12, color: AppTheme.success),
                              const SizedBox(width: 4),
                              Text(DateFormat('MMM dd, HH:mm').format(mapping.startTime), style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                            ],
                          ),
                          if (mapping.endTime != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_remove_alt_1, size: 12, color: AppTheme.error),
                                const SizedBox(width: 4),
                                Text(DateFormat('MMM dd, HH:mm').format(mapping.endTime!), style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                              ],
                            ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_outlined, size: 12, color: AppTheme.primary),
                              const SizedBox(width: 4),
                              Text(durationStr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                            ],
                          ),
                        ],
                      ),
                    ],
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
