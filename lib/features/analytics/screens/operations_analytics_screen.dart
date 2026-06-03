import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import 'employee_stats_screen.dart';

class OperationsAnalyticsScreen extends StatefulWidget {
  const OperationsAnalyticsScreen({super.key});
  @override
  State<OperationsAnalyticsScreen> createState() => _OperationsAnalyticsScreenState();
}

class _OperationsAnalyticsScreenState extends State<OperationsAnalyticsScreen> {
  List<Map<String, dynamic>> _routings = [];
  Map<String, dynamic>? _selectedRouting;
  List<Map<String, dynamic>> _operations = [];
  bool _loading = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadRoutings();
  }

  Future<void> _loadRoutings() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().dio.get('/api/analytics/routings');
      if (res.statusCode == 200) {
        setState(() => _routings = List<Map<String, dynamic>>.from(res.data));
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _loadOperations(Map<String, dynamic> routing) async {
    setState(() { _selectedRouting = routing; _loading = true; _operations = []; });
    try {
      final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.day.toString().padLeft(2,'0')}';
      final res = await ApiClient().dio.get('/api/analytics/routing/${routing['routingId']}/operations', queryParameters: {'date': dateStr});
      if (res.statusCode == 200) {
        setState(() => _operations = List<Map<String, dynamic>>.from(res.data));
      }
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
    if (picked != null) {
      setState(() => _selectedDate = picked);
      if (_selectedRouting != null) _loadOperations(_selectedRouting!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operations Analytics'),
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
            label: Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _selectedRouting == null
              ? _buildRoutingPicker()
              : _buildOperationsList(),
    );
  }

  Widget _buildRoutingPicker() {
    if (_routings.isEmpty) {
      return Center(child: Text('No approved routings found', style: AppTheme.bodyLarge.copyWith(color: AppTheme.onSurfaceVariant)));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Select Routing', style: AppTheme.titleLarge),
        const SizedBox(height: 12),
        ..._routings.map((r) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.route, color: AppTheme.primary),
            ),
            title: Text('Routing #${r['routingId']}', style: AppTheme.titleMedium.copyWith(fontWeight: FontWeight.w700)),
            subtitle: Text('Product #${r['productId']} • v${r['version']}', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _loadOperations(r),
          ),
        )),
      ],
    );
  }

  Widget _buildOperationsList() {
    if (_operations.isEmpty) {
      return Column(
        children: [
          _buildDateHeader(),
          Expanded(child: Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart_outlined, size: 56, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text('No data for this date', style: AppTheme.titleMedium.copyWith(color: AppTheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('Try a different date or check tracking records', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
            ],
          ))),
        ],
      );
    }

    final chartData = _operations.map((op) => _ChartData(
      op['operationName']?.toString() ?? 'Op',
      (op['totalQty'] as num?)?.toDouble() ?? 0,
      (op['expectedDayTotal'] as num?)?.toDouble() ?? 0,
    )).toList();

    return Column(
      children: [
        _buildDateHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Bar chart
              Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Output vs Target', style: AppTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('Actual vs Expected day total', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 280,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: (chartData.length * 80.0).clamp(300, double.infinity),
                          child: SfCartesianChart(
                            primaryXAxis: const CategoryAxis(
                              majorGridLines: MajorGridLines(width: 0),
                              labelRotation: -45,
                              labelStyle: TextStyle(fontSize: 10),
                            ),
                            primaryYAxis: const NumericAxis(
                              axisLine: AxisLine(width: 0),
                              majorTickLines: MajorTickLines(size: 0),
                            ),
                            tooltipBehavior: TooltipBehavior(enable: true),
                            legend: const Legend(isVisible: true, position: LegendPosition.bottom),
                            series: <CartesianSeries>[
                              ColumnSeries<_ChartData, String>(
                                name: 'Actual',
                                dataSource: chartData,
                                xValueMapper: (d, _) => d.label,
                                yValueMapper: (d, _) => d.actual,
                                color: AppTheme.primary,
                                borderRadius: const BorderRadius.all(Radius.circular(4)),
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  textStyle: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                              ColumnSeries<_ChartData, String>(
                                name: 'Target',
                                dataSource: chartData,
                                xValueMapper: (d, _) => d.label,
                                yValueMapper: (d, _) => d.target,
                                color: AppTheme.secondary.withValues(alpha: 0.6),
                                borderRadius: const BorderRadius.all(Radius.circular(4)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Operations', style: AppTheme.titleLarge),
              const SizedBox(height: 8),
              ..._operations.map((op) {
                final actual = (op['totalQty'] as num?)?.toInt() ?? 0;
                final expected = (op['expectedDayTotal'] as num?)?.toInt() ?? 1;
                final pct = (op['achievementPercent'] as num?)?.toInt() ?? 0;
                final onTarget = actual >= expected;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _OperationDetailScreen(
                      operationId: op['operationId'] as int,
                      operationName: op['operationName']?.toString() ?? '',
                      date: _selectedDate,
                    ))),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(op['operationName']?.toString() ?? '', style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w700))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (onTarget ? AppTheme.success : AppTheme.error).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('$pct%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: onTarget ? AppTheme.success : AppTheme.error)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: expected > 0 ? (actual / expected).clamp(0.0, 1.0) : 0,
                              minHeight: 6,
                              backgroundColor: AppTheme.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation(onTarget ? AppTheme.success : AppTheme.error),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('Actual: $actual', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                              Text('Target: $expected', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
                              const Spacer(),
                              Text('${op['activeCount'] ?? 0} active', style: AppTheme.bodySmall.copyWith(color: AppTheme.info)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
      child: Row(
        children: [
          Icon(Icons.route, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text('Routing #${_selectedRouting!['routingId']}', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() { _selectedRouting = null; _operations = []; }),
            icon: const Icon(Icons.swap_horiz, size: 16),
            label: const Text('Change'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
          ),
        ],
      ),
    );
  }
}

class _OperationDetailScreen extends StatefulWidget {
  final int operationId;
  final String operationName;
  final DateTime date;
  const _OperationDetailScreen({required this.operationId, required this.operationName, required this.date});
  @override
  State<_OperationDetailScreen> createState() => _OperationDetailScreenState();
}

class _OperationDetailScreenState extends State<_OperationDetailScreen> {
  List<Map<String, dynamic>> _employees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dateStr = '${widget.date.year}-${widget.date.month.toString().padLeft(2,'0')}-${widget.date.day.toString().padLeft(2,'0')}';
      final res = await ApiClient().dio.get('/api/analytics/operation/${widget.operationId}/employees', queryParameters: {'date': dateStr});
      if (res.statusCode == 200) setState(() => _employees = List<Map<String, dynamic>>.from(res.data));
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.operationName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
              ? Center(child: Text('No employees tracked for this operation', style: AppTheme.bodyLarge.copyWith(color: AppTheme.onSurfaceVariant)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Employees at this Operation', style: AppTheme.titleLarge),
                    const SizedBox(height: 12),
                    ..._employees.map((emp) {
                      final qty = (emp['totalQty'] as num?)?.toInt() ?? 0;
                      final target = (emp['targetPerHour'] as num?)?.toInt() ?? 30;
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
                          subtitle: Text('Output: $qty • Target/hr: $target', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeStatsScreen(
                            employeeId: emp['employeeId'] as int,
                            employeeName: emp['employeeName']?.toString() ?? '',
                            initialDate: widget.date,
                          ))),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}

class _ChartData {
  final String label;
  final double actual;
  final double target;
  _ChartData(this.label, this.actual, this.target);
}
