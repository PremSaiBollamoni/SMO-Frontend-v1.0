import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import 'employee_stats_screen.dart';

class EmployeeAnalyticsScreen extends StatefulWidget {
  const EmployeeAnalyticsScreen({super.key});
  @override
  State<EmployeeAnalyticsScreen> createState() => _EmployeeAnalyticsScreenState();
}

class _EmployeeAnalyticsScreenState extends State<EmployeeAnalyticsScreen> {
  List<Map<String, dynamic>> _employees = [];
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.day.toString().padLeft(2,'0')}';
      final res = await ApiClient().dio.get('/api/analytics/employees', queryParameters: {'date': dateStr});
      if (res.statusCode == 200) setState(() => _employees = List<Map<String, dynamic>>.from(res.data));
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) { setState(() => _selectedDate = picked); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _employees.where((e) {
      final name = e['employeeName']?.toString().toLowerCase() ?? '';
      return name.contains(_search.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Analytics'),
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
            label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: AppTheme.inputDecoration('Search employee...').copyWith(
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  Expanded(child: Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 56, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text('No employee data for this date', style: AppTheme.titleMedium.copyWith(color: AppTheme.onSurfaceVariant)),
                    ],
                  )))
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final emp = filtered[i];
                        final qty = (emp['totalQty'] as num?)?.toInt() ?? 0;
                        final jobs = (emp['completedJobs'] as num?)?.toInt() ?? 0;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                              child: Text(
                                (emp['employeeName']?.toString() ?? 'E')[0].toUpperCase(),
                                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(emp['employeeName']?.toString() ?? '', style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                            subtitle: Text('Output: $qty • Jobs: $jobs', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeStatsScreen(
                              employeeId: emp['employeeId'] as int,
                              employeeName: emp['employeeName']?.toString() ?? '',
                              initialDate: _selectedDate,
                            ))),
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
