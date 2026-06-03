import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class MachineAnalyticsScreen extends StatefulWidget {
  const MachineAnalyticsScreen({super.key});
  @override
  State<MachineAnalyticsScreen> createState() => _MachineAnalyticsScreenState();
}

class _MachineAnalyticsScreenState extends State<MachineAnalyticsScreen> {
  List<Map<String, dynamic>> _machines = [];
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
      final res = await ApiClient().dio.get('/api/analytics/machines', queryParameters: {'date': dateStr});
      if (res.statusCode == 200) setState(() => _machines = List<Map<String, dynamic>>.from(res.data));
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
    final filtered = _machines.where((m) {
      final name = m['machineName']?.toString().toLowerCase() ?? '';
      return name.contains(_search.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Machine Utilisation'),
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
                    decoration: AppTheme.inputDecoration('Search machine...').copyWith(
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.precision_manufacturing_outlined, size: 56, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text('No machines found', style: AppTheme.titleMedium.copyWith(color: AppTheme.onSurfaceVariant)),
                          ],
                        ))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final m = filtered[i];
                            final activeH = (m['activeHours'] as num?)?.toDouble() ?? 0;
                            final jobs = (m['jobsCount'] as num?)?.toInt() ?? 0;
                            final utilPct = activeH > 0 ? ((activeH / 8) * 100).clamp(0, 100).toInt() : 0;
                            final color = utilPct >= 70 ? AppTheme.success : (utilPct >= 40 ? AppTheme.secondary : AppTheme.error);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _MachineDetailScreen(
                                  machineId: m['machineId'] as int,
                                  machineName: m['machineName']?.toString() ?? '',
                                  date: _selectedDate,
                                ))),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48, height: 48,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.precision_manufacturing_outlined, color: color, size: 24),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(m['machineName']?.toString() ?? '', style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 2),
                                            Text('${m['machineType'] ?? ''} • ${activeH.toStringAsFixed(1)}h active • $jobs jobs', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
                                            const SizedBox(height: 6),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: (activeH / 8).clamp(0.0, 1.0),
                                                minHeight: 5,
                                                backgroundColor: AppTheme.surfaceVariant,
                                                valueColor: AlwaysStoppedAnimation(color),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text('$utilPct%', style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)),
                                    ],
                                  ),
                                ),
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

class _MachineDetailScreen extends StatefulWidget {
  final int machineId;
  final String machineName;
  final DateTime date;
  const _MachineDetailScreen({required this.machineId, required this.machineName, required this.date});
  @override
  State<_MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<_MachineDetailScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dateStr = '${widget.date.year}-${widget.date.month.toString().padLeft(2,'0')}-${widget.date.day.toString().padLeft(2,'0')}';
      final res = await ApiClient().dio.get('/api/analytics/machine/${widget.machineId}/stats', queryParameters: {'date': dateStr});
      if (res.statusCode == 200) setState(() => _stats = Map<String, dynamic>.from(res.data));
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.machineName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? Center(child: Text('No data', style: AppTheme.bodyLarge.copyWith(color: AppTheme.onSurfaceVariant)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final s = _stats!;
    final activeH = (s['activeHours'] as num?)?.toDouble() ?? 0;
    final idleH = (s['idleHours'] as num?)?.toDouble() ?? 8;
    final utilPct = (s['utilizationPercent'] as num?)?.toInt() ?? 0;
    final operators = (s['uniqueOperators'] as num?)?.toInt() ?? 0;
    final perOp = List<Map<String, dynamic>>.from(s['perOperation'] ?? []);
    final hourlyData = List<Map<String, dynamic>>.from(s['hourlyData'] ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // KPI row
        Row(
          children: [
            Expanded(child: _kpiCard('Active', '${activeH.toStringAsFixed(1)}h', Icons.play_circle_outline, AppTheme.success)),
            const SizedBox(width: 12),
            Expanded(child: _kpiCard('Idle', '${idleH.toStringAsFixed(1)}h', Icons.pause_circle_outline, AppTheme.onSurfaceVariant)),
            const SizedBox(width: 12),
            Expanded(child: _kpiCard('Operators', '$operators', Icons.people_outline, AppTheme.primary)),
          ],
        ),
        const SizedBox(height: 16),

        // Donut chart
        Container(
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Utilisation — $utilPct%', style: AppTheme.titleLarge),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: SfCircularChart(
                  legend: const Legend(isVisible: true, position: LegendPosition.bottom),
                  series: <CircularSeries>[
                    DoughnutSeries<_PieData, String>(
                      dataSource: [
                        _PieData('Active', activeH, AppTheme.success),
                        _PieData('Idle', idleH, AppTheme.surfaceVariant),
                      ],
                      xValueMapper: (d, _) => d.label,
                      yValueMapper: (d, _) => d.value,
                      pointColorMapper: (d, _) => d.color,
                      dataLabelSettings: const DataLabelSettings(isVisible: true),
                      innerRadius: '55%',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Per-operation bar chart
        if (perOp.isNotEmpty) ...[
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Usage by Operation (hours)', style: AppTheme.titleLarge),
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
                            yValueMapper: (d, _) => (d['hours'] as num?)?.toDouble() ?? 0,
                            color: AppTheme.tertiary,
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
          const SizedBox(height: 16),
        ],

        // Hourly usage bar chart
        if (hourlyData.isNotEmpty)
          Container(
            decoration: AppTheme.cardDecoration,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hourly Usage (minutes)', style: AppTheme.titleLarge),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: SfCartesianChart(
                    primaryXAxis: const CategoryAxis(majorGridLines: MajorGridLines(width: 0)),
                    primaryYAxis: const NumericAxis(axisLine: AxisLine(width: 0), majorTickLines: MajorTickLines(size: 0)),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <CartesianSeries>[
                      ColumnSeries<Map<String, dynamic>, String>(
                        dataSource: hourlyData,
                        xValueMapper: (d, _) => d['label']?.toString() ?? '',
                        yValueMapper: (d, _) => (d['minutes'] as num?)?.toDouble() ?? 0,
                        color: AppTheme.primary,
                        borderRadius: const BorderRadius.all(Radius.circular(4)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: AppTheme.titleLarge.copyWith(color: color, fontWeight: FontWeight.bold)),
          Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _PieData {
  final String label;
  final double value;
  final Color color;
  _PieData(this.label, this.value, this.color);
}
