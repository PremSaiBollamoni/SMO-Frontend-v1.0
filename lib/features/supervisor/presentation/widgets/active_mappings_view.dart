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
      return const Center(
        child: Text('No active QR mappings'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mappings.length,
      itemBuilder: (context, index) {
        final mapping = mappings[index];
        final duration = DateTime.now().difference(mapping.startTime);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.success,
              child: const Icon(Icons.qr_code, color: Colors.white),
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
                Text(
                  'Duration: ${duration.inHours}h ${duration.inMinutes % 60}m',
                  style: TextStyle(color: AppTheme.primary),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: AppTheme.error),
              onPressed: () => _confirmUnmap(context, mapping.id),
              tooltip: 'Manual Unmap',
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _confirmUnmap(BuildContext context, int mappingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unmap QR Code'),
        content: const Text('Are you sure you want to manually unmap this QR code?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unmap'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && context.mounted) {
      final success = await controller.unmapQrCode(mappingId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'QR code unmapped' : 'Failed to unmap'),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }
}
