import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../core/theme/app_theme.dart';
import 'analytics_api.dart';

class EmployeeStatsScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  final String initialDate;

  const EmployeeStatsScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
    required this.initialDate,
  });

  @override
  State<EmployeeStatsScreen> createState() => _EmployeeStatsScreenState();
}

class _EmployeeStatsScreenState extends State<EmployeeStatsScreen> {
  final AnalyticsApi _api = AnalyticsApi();
  late String _selectedDate;
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getEmployeeStats(widget.employeeId, _selectedDate);
      if (mounted) setState(() { _stats = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_selectedDate),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _selectedDate = picked.toIso8601String().substring(0, 10);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employeeName),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickDate, tooltip: 'Pick Date'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? Center(child: Text('No data for $_selectedDate', style: AppTheme.bodyLarge))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final s = _stats!;
    final hourlyData = (s['hourlyData'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    final operationData = (s['operationData'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date chip
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(_selectedDate, style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 16),

          // KPI cards
          Row(
            children: [
              Expanded(child: _kpiCard('Total Output', '${s['totalQty'] ?? 0}', Icons.inventory_2_outlined, AppTheme.primary)),
              const SizedBox(width: 12),
              Expanded(child: _kpiCard('Completed', '${s['completedCount'] ?? 0}', Icons.check_circle_outline, AppTheme.success)),
              const SizedBox(width: 12),
              Expanded(child: _kpiCard('Avg Time', '${s['avgDurationMinutes'] ?? 0} min', Icons.timer_outlined, AppTheme.secondary)),
            ],
          ),
          const SizedBox(height: 20),

          // Hourly output chart
          if (hourlyData.isNotEmpty) ...[
            Text('Hourly Output vs Target', style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 260,
                child: SfCartesianChart(
                  primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0)),
                  primaryYAxis: const NumericAxis(axisLine: AxisLine(width: 0), majorTickLines: MajorTickLines(size: 0)),
                  tooltipBehavior: TooltipBehavior(enable: true),
                  legend: const Legend(isVisible: true, position: LegendPosition.bottom),
                  series: <CartesianSeries>[
                    ColumnSeries<Map<String, dynamic>, String>(
                      name: 'Actual',
                      dataSource: hourlyData,
                      xValueMapper: (d, _) => d['label'] as String,
                      yValueMapper: (d, _) => (d['actual'] as num).toDouble(),
                      pointColorMapper: (d, _) {
                        final actual = (d['actual'] as num).toDouble();
                        final target = (d['target'] as num).toDouble();
                        return actual >= target ? AppTheme.success : AppTheme.error;
                      },
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      dataLabelSettings: const DataLabelSettings(isVisible: false),
                    ),
                    LineSeries<Map<String, dynamic>, String>(
                      name: 'Target',
                      dataSource: hourlyData,
                      xValueMapper: (d, _) => d['label'] as String,
                      yValueMapper: (d, _) => (d['target'] as num).toDouble(),
                      color: AppTheme.secondary,
                      width: 2,
                      dashArray: const [6, 4],
                      markerSettings: const MarkerSettings(isVisible: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Per-operation chart
          if (operationData.isNotEmpty) ...[
            Text('Output by Operation', style: AppTheme.titleLarge),
            const SizedBox(height: 8),
            Container(
              decoration: AppTheme.cardDecoration,
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 260,
                child: SfCartesianChart(
                  primaryXAxis: const CategoryAxis(
                    majorGridLines: MajorGridLines(width: 0),
                    labelRotation: -30,
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  primaryYAxis: const NumericAxis(axisLine: AxisLine(width: 0), majorTickLines: MajorTickLines(size: 0)),
                  tooltipBehavior: TooltipBehavior(enable: true),
                  series: <CartesianSeries>[
                    ColumnSeries<Map<String, dynamic>, String>(
                      name: 'Actual',
                      dataSource: operationData,
                      xValueMapper: (d, _) => (d['operationName'] as String).length > 12
                          ? '${(d['operationName'] as String).substring(0, 12)}...'
                          : d['operationName'] as String,
                      yValueMapper: (d, _) => (d['actual'] as num).toDouble(),
                      pointColorMapper: (d, _) => (d['aboveTarget'] as bool? ?? false) ? AppTheme.success : AppTheme.error,
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      dataLabelSettings: const DataLabelSettings(isVisible: true, textStyle: TextStyle(fontSize: 10)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: AppTheme.titleLarge.copyWith(color: color, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
