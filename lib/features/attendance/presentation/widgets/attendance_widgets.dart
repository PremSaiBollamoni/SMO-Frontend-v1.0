import 'package:flutter/material.dart';
import '../../data/models/attendance_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../hr/data/models/shift_models.dart';

class IdleScanPrompt extends StatelessWidget {
  final VoidCallback onScan;

  const IdleScanPrompt({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.qr_code_scanner, size: 64, color: AppTheme.primary),
      ),
      const SizedBox(height: 20),
      Text('Ready to Scan', style: AppTheme.titleLarge.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(
        'Scan employee temp QR to check in or check out.\nSystem auto-detects based on current status.',
        textAlign: TextAlign.center,
        style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant),
      ),
      const SizedBox(height: 32),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onScan,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan QR'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ]);
  }
}

class StepHeader extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;

  const StepHeader({super.key, required this.step, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.primary,
          child: Text(step, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w700, color: AppTheme.primary)),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
        ])),
      ]),
    );
  }
}

class EmployeeDropdown extends StatelessWidget {
  final List<EmployeeOption> employees;
  final EmployeeOption? selected;
  final void Function(EmployeeOption?)? onChanged;

  const EmployeeDropdown({super.key, required this.employees, this.selected, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<EmployeeOption>(
      value: selected,
      decoration: InputDecoration(
        labelText: 'Select Employee',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      isExpanded: true,
      items: employees.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
      onChanged: onChanged,
      hint: const Text('Choose employee...'),
    );
  }
}

class InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const InfoChip({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Text('$label: ', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
          Text(value, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class ShiftTile extends StatelessWidget {
  final ShiftTemplateModel shift;
  final VoidCallback? onTap;

  const ShiftTile({super.key, required this.shift, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.primary,
          child: Icon(Icons.schedule, color: Colors.white, size: 18),
        ),
        title: Text(shift.shiftName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${_fmt(shift.startTime)} – ${_fmt(shift.endTime)}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _fmt(String t) => t.length >= 5 ? t.substring(0, 5) : t;
}

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const ErrorBanner({super.key, required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 13))),
        IconButton(
          icon: const Icon(Icons.close, size: 16),
          onPressed: onDismiss,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}
