import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class EmployeeBulkBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClear;
  final VoidCallback onDelete;

  const EmployeeBulkBar({
    super.key,
    required this.selectedCount,
    required this.onClear,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.primary.withValues(alpha: 0.1),
      child: Row(children: [
        Text('$selectedCount selected', style: const TextStyle(fontWeight: FontWeight.bold)),
        const Spacer(),
        TextButton.icon(onPressed: onClear, icon: const Icon(Icons.clear), label: const Text('Clear')),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete),
          label: const Text('Delete'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
        ),
      ]),
    );
  }
}
