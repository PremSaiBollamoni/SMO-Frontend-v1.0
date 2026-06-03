import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class EmployeeStatsScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  final DateTime? initialDate;

  const EmployeeStatsScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
    this.initialDate,
  });

  @override
  State<EmployeeStatsScreen> createState() => _EmployeeStatsScreenState();
}

class _EmployeeStatsScreenState extends State<EmployeeStatsScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.day.toString().padLeft(2,'0')}';
      final res = await ApiClient().dio.get('/api/analytics/employee/${widget.employeeId}/stats', queryParameters: {'date': dateStr});
      if (res.statusCode == 200) setState(() => _stats = Map<String, dynamic>.from(res.data));
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employeeName),
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
          : _stats == null
              ? Center(child: Text('No data available', style: AppTheme.bodyLarge.copyWith(color: AppTheme.onSurfaceVariant)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final s = _stats!;
    final totalQty = (s['totalQty'] as num?)?.toInt() ?? 0;
    final completedJobs = (s['completedJobs'] as num?)?.toInt() ?? 0;
    final totalMins = (s['totalMinutesWorked'] as num?)?.toInt() ?? 0;
    final avgMin = (s['avgMinPerJob'] as num?)?.toDouble() ?? 0;
    final hourlyData = List<Map<String, dynamic>>.from(s['hourlyData'] ?? []);
    final perOp = List<Map<String, dynamic>>.from(s['perOperation'] ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // KPI Cards
        Row(
          children: [
            Expanded(child: _kpiCard('Total Output', '$totalQty', Icons.inventory_2_outlined, AppTheme.primary)),
            const SizedBox(width: 12),
            Expanded(child: _kpiCard('Jobs Done', '$completedJobs', Icons.check_circle_outline, AppTheme.success)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _kpiCard('Hours Worked', '${(totalMins / 60).toStringAsFixed(1)}h', Icons.access_time_outlined, AppTheme.info)),
            const SizedBox(width: 12),
            Expanded(child: _kpiCard('Avg Min/Job', '${avgMin.toStringAsFixed(1)}m', Icons.speed_outlined, AppTheme.secondary)),
          ],
        ),
        const SizedBox(height: 20),

        // Hourly output line chart
        if (hourlyData.isNotEmpty) ...[
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hourly Output', style: AppTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Actual output vs hourly target', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 240,
                  child: SfCartesianChart(
                    primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0)),
                    primaryYAxis: const NumericAxis(axisLine: AxisLine(width: 0), majorTickLines: MajorTickLines(size: 0)),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    legend: const Legend(isVisible: true, position: LegendPosition.bottom),
                    series: <CartesianSeries>[
                      LineSeries<Map<String, dynamic>, String>(
                        name: 'Actual',
                        dataSource: hourlyData,
                        xValueMapper: (d, _) => d['label']?.toString() ?? '',
                        yValueMapper: (d, _) => (d['qty'] as num?)?.toDouble() ?? 0,
                        color: AppTheme.primary,
                        width: 2.5,
                        markerSettings: const MarkerSettings(isVisible: true, shape: DataMarkerType.circle),
                        dataLabelSettings: const DataLabelSettings(isVisible: true, textStyle: TextStyle(fontSize: 10)),
                      ),
                      LineSeries<Map<String, dynamic>, String>(
                        name: 'Target',
                        dataSource: hourlyData,
                        xValueMapper: (d, _) => d['label']?.toString() ?? '',
                        yValueMapper: (d, _) => (d['target'] as num?)?.toDouble() ?? 0,
                        color: AppTheme.secondary,
                        width: 2,
                        dashArray: const <double>[6, 4],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Per-operation bar chart
        if (perOp.isNotEmpty) ...[
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Output by Operation', style: AppTheme.titleLarge),
                const SizedBox(height: 16),
                SizedBox(
                  height: 260,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: (perOp.length * 80.0).clamp(300, double.infinity),
                      child: SfCartesianChart(
                        primaryXAxis: const CategoryAxis(
                          majorGridLines: MajorGridLines(width: 0),
                          labelRotation: -45,
                          labelStyle: TextStyle(fontSize: 10),
                        ),
                        primaryYAxis: const NumericAxis(axisLine: AxisLine(width: 0), majorTickLines: MajorTickLines(size: 0)),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CartesianSeries>[
                          ColumnSeries<Map<String, dynamic>, String>(
                            dataSource: perOp,
                            xValueMapper: (d, _) => d['operationName']?.toString() ?? '',
                            yValueMapper: (d, _) => (d['qty'] as num?)?.toDouble() ?? 0,
                            pointColorMapper: (d, _) {
                              final qty = (d['qty'] as num?)?.toInt() ?? 0;
                              final tph = (d['targetPerHour'] as num?)?.toInt() ?? 30;
                              return qty >= tph ? AppTheme.success : AppTheme.error;
                            },
                            borderRadius: const BorderRadius.all(Radius.circular(4)),
                            dataLabelSettings: const DataLabelSettings(isVisible: true, textStyle: TextStyle(fontSize: 10)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (hourlyData.isEmpty && perOp.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.bar_chart_outlined, size: 56, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('No tracking data for this date', style: AppTheme.titleMedium.copyWith(color: AppTheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: AppTheme.headlineSmall.copyWith(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
