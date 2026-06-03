import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class TrayQuantityStepper extends StatelessWidget {
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<int>? onValueChanged;

  const TrayQuantityStepper({
    super.key,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    this.onValueChanged,
  });

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: value.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Enter Quantity', style: AppTheme.titleLarge),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: AppTheme.inputDecoration('Quantity'),
          onSubmitted: (val) {
            _applyValue(ctx, controller.text);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _applyValue(ctx, controller.text),
            style: AppTheme.primaryButtonStyle.copyWith(
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            ),
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _applyValue(BuildContext ctx, String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed != null && parsed >= 1) {
      if (onValueChanged != null) {
        onValueChanged!(parsed);
      }
      Navigator.pop(ctx);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.surfaceVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement button
          IconButton(
            onPressed: value > 1 ? onDecrement : null,
            icon: const Icon(Icons.remove),
            color: value > 1 ? AppTheme.primary : AppTheme.disabled,
            splashRadius: 20,
          ),

          // Tappable value — tap to type directly
          GestureDetector(
            onTap: () => _showEditDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value.toString(),
                style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Increment button
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add),
            color: AppTheme.primary,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
