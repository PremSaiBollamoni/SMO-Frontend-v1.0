import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class HourlyTargetsScreen extends StatefulWidget {
  const HourlyTargetsScreen({super.key});
  @override
  State<HourlyTargetsScreen> createState() => _HourlyTargetsScreenState();
}

class _HourlyTargetsScreenState extends State<HourlyTargetsScreen> {
  List<Map<String, dynamic>> _targets = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/api/analytics/hourly-targets');
      if (res.statusCode == 200) {
        final list = List<Map<String, dynamic>>.from(res.data);
        list.sort((a, b) => (a['operationName']?.toString() ?? '').compareTo(b['operationName']?.toString() ?? ''));
        setState(() {
          _targets = list;
          _filtered = list;
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _applySearch(String query) {
    setState(() {
      _search = query;
      _filtered = _targets.where((t) =>
        (t['operationName']?.toString().toLowerCase() ?? '').contains(query.toLowerCase())
      ).toList();
    });
  }

  Future<void> _editTarget(Map<String, dynamic> target) async {
    final ctrl = TextEditingController(text: target['targetPerHour']?.toString() ?? '30');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Target', style: AppTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              target['operationName']?.toString() ?? '',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: AppTheme.inputDecoration('Target per hour *').copyWith(
                suffixText: 'pcs/hr',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim());
              if (val != null && val > 0) Navigator.pop(ctx, val);
            },
            style: AppTheme.primaryButtonStyle.copyWith(
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        final res = await ApiClient().dio.put(
          '/api/analytics/hourly-targets/${target['id']}',
          data: {'targetPerHour': result},
        );
        if (res.statusCode == 200) {
          CustomSnackbar.showSuccess(context, 'Target updated to $result pcs/hr');
          await _load();
        }
      } catch (e) {
        if (mounted) CustomSnackbar.showError(context, 'Failed to update target');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hourly Targets')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: _applySearch,
                    decoration: AppTheme.inputDecoration('Search operation...').copyWith(
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('${_filtered.length} operations', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
                      const Spacer(),
                      Text('Tap any row to edit', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final t = _filtered[i];
                      final tph = (t['targetPerHour'] as num?)?.toInt() ?? 30;
                      final color = tph >= 40 ? AppTheme.success : (tph >= 25 ? AppTheme.secondary : AppTheme.error);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '$tph',
                                style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 15),
                              ),
                            ),
                          ),
                          title: Text(
                            t['operationName']?.toString() ?? '',
                            style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '$tph pieces per hour',
                            style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
                            onPressed: () => _editTarget(t),
                          ),
                          onTap: () => _editTarget(t),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
