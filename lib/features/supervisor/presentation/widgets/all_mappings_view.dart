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
      return const Center(
        child: Text('No QR mappings found'),
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
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isActive ? AppTheme.success : Colors.grey,
              child: Icon(
                isActive ? Icons.qr_code : Icons.check_circle,
                color: Colors.white,
              ),
            ),
            title: Text(
              'QR: ${mapping.qrId}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Employee ID: ${mapping.employeeId}'),
                Text('Check-in: ${DateFormat('MMM dd, HH:mm').format(mapping.startTime)}'),
                if (mapping.endTime != null)
                  Text('Check-out: ${DateFormat('MMM dd, HH:mm').format(mapping.endTime!)}'),
                Text(
                  'Duration: ${duration.inHours}h ${duration.inMinutes % 60}m',
                  style: TextStyle(
                    color: isActive ? AppTheme.primary : Colors.grey,
                  ),
                ),
              ],
            ),
            trailing: Chip(
              label: Text(
                mapping.status,
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: isActive ? AppTheme.success : Colors.grey[300],
              labelStyle: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }
}
