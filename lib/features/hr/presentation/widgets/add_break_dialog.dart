import 'package:flutter/material.dart';
import '../../data/api/shift_api_service.dart';
import '../../../../core/theme/app_theme.dart';

class AddBreakDialog extends StatefulWidget {
  final int templateId;
  final String shiftName;

  const AddBreakDialog({super.key, required this.templateId, required this.shiftName});

  @override
  State<AddBreakDialog> createState() => _AddBreakDialogState();
}

class _AddBreakDialogState extends State<AddBreakDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 13, minute: 30);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) { _startTime = picked; } else { _endTime = picked; }
    });
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      await ShiftApiService().addBreak(
        templateId: widget.templateId,
        breakName: _nameCtrl.text.trim(),
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(children: [
            Icon(Icons.coffee, color: AppTheme.secondary),
            SizedBox(width: 8),
            Text('Add Break'),
          ]),
          const SizedBox(height: 4),
          Text(widget.shiftName,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.normal)),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Break Name', hintText: 'e.g. Lunch Break'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _TimeTile(
                    label: 'From',
                    time: _startTime,
                    onTap: () => _pickTime(true),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _TimeTile(
                    label: 'To',
                    time: _endTime,
                    onTap: () => _pickTime(false),
                  )),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondary, foregroundColor: Colors.white),
          child: _saving
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Add'),
        ),
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeTile({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 15, color: AppTheme.secondary),
                const SizedBox(width: 6),
                Text(time.format(context),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
