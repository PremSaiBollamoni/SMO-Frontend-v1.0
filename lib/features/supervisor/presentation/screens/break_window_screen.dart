import 'package:flutter/material.dart';
import '../../data/api/break_window_api_service.dart';
import '../../../../core/utils/api_error_helper.dart';
import '../../../../core/theme/app_theme.dart';

/// Break Window Management Screen
/// Supervisor can add/remove daily break windows (e.g. Lunch 1:00 PM - 2:00 PM).
/// These are automatically deducted from tracking durations.
class BreakWindowScreen extends StatefulWidget {
  const BreakWindowScreen({super.key});

  @override
  State<BreakWindowScreen> createState() => _BreakWindowScreenState();
}

class _BreakWindowScreenState extends State<BreakWindowScreen> {
  final BreakWindowApiService _api = BreakWindowApiService();
  List<Map<String, dynamic>> _windows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getAllBreakWindows();
      if (!mounted) return;
      setState(() {
        _windows = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiErrorHelper.getMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _showAddDialog() async {
    final nameCtrl = TextEditingController(text: 'Lunch Break');
    TimeOfDay startTime = const TimeOfDay(hour: 13, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 14, minute: 0);
    bool submitting = false;
    String? err;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.free_breakfast, color: Colors.orange),
              SizedBox(width: 8),
              Text('Add Break Window'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Break name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text('Start: ${startTime.format(ctx)}'),
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: startTime,
                        );
                        if (t != null) setS(() => startTime = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text('End: ${endTime.format(ctx)}'),
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: endTime,
                        );
                        if (t != null) setS(() => endTime = t);
                      },
                    ),
                  ),
                ],
              ),
              if (err != null) ...[
                const SizedBox(height: 8),
                Text(err!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      setS(() {
                        submitting = true;
                        err = null;
                      });
                      try {
                        String fmt(TimeOfDay t) =>
                            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                        await _api.createBreakWindow(
                          breakName: nameCtrl.text.trim().isEmpty
                              ? 'Break'
                              : nameCtrl.text.trim(),
                          breakStart: fmt(startTime),
                          breakEnd: fmt(endTime),
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _load();
                      } catch (e) {
                        setS(() {
                          err = ApiErrorHelper.getMessage(e);
                          submitting = false;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Break Window'),
        content: Text('Remove "$name"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _api.deleteBreakWindow(id);
      _load();
    }
  }

  String _formatTime(String? t) {
    if (t == null) return '';
    // t is HH:mm:ss or HH:mm
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '${h12.toString().padLeft(2, '0')}:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Break windows are automatically deducted from tracking durations. '
                    'E.g. if lunch is 1:00 PM - 2:00 PM and a tray was tracked from '
                    '12:30 PM to 2:15 PM, the actual work time shown will be 45 min.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade400, size: 48),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _windows.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.free_breakfast,
                                    size: 56,
                                    color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'No break windows set',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap + to add a lunch or tea break',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _windows.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final w = _windows[i];
                              final id = w['id'] as int?;
                              final name =
                                  (w['breakName'] ?? 'Break').toString();
                              final start =
                                  _formatTime(w['breakStart']?.toString());
                              final end =
                                  _formatTime(w['breakEnd']?.toString());
                              final active = w['isActive'] == true;

                              return Card(
                                elevation: 1,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: active
                                        ? Colors.orange
                                        : Colors.grey.shade400,
                                    child: const Icon(Icons.free_breakfast,
                                        color: Colors.white, size: 20),
                                  ),
                                  title: Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text('$start  →  $end'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!active)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text('Inactive',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey)),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red),
                                        onPressed: id == null
                                            ? null
                                            : () => _delete(id, name),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Break'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }
}
