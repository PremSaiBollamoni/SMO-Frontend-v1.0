import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/api/production_api_service.dart';
import '../../data/api/report_api_service.dart';
import '../../data/models/production_models.dart';
import '../../data/models/report_models.dart';
import '../widgets/report_pdf_builder.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _prodApi = ProductionApiService();
  final _reportApi = ReportApiService();

  List<EmployeeEfficiency> _employees = [];
  ReportResult? _report;
  bool _loading = true;
  bool _generating = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final emps = await _prodApi.getEfficiencyToday();
      if (mounted) setState(() { _employees = emps; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _generate() async {
    setState(() { _generating = true; _error = null; });
    try {
      final result = await _reportApi.generateReport();
      if (mounted) setState(() { _report = result; _generating = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _generating = false; });
    }
  }

  Future<void> _downloadPdf() async {
    if (_report == null) return;
    await Printing.layoutPdf(
      name: 'production_report_${DateTime.now().millisecondsSinceEpoch}',
      onLayout: (_) async => buildReportPdf(_employees, _report!),
    );
  }

  Color _effColor(double e) => e >= 100 ? Colors.green : e >= 80 ? Colors.orange : Colors.red;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('AI Report'),
        actions: [
          if (_report != null)
            IconButton(icon: const Icon(Icons.download_rounded), tooltip: 'Download PDF', onPressed: _downloadPdf),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _efficiencyChart(),
                    const SizedBox(height: 16),
                    _piecesChart(),
                    const SizedBox(height: 20),
                    if (_report == null) _generateButton() else _insightsCard(),
                    const SizedBox(height: 80),
                  ]),
                ),
      floatingActionButton: _report != null
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              onPressed: _downloadPdf,
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Download PDF', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  Widget _errorView() => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48, color: Colors.red),
      const SizedBox(height: 12),
      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _load, child: const Text('Retry')),
    ]),
  ));

  Widget _efficiencyChart() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Operator Efficiency %', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black87)),
      const SizedBox(height: 12),
      SizedBox(height: 200, child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        primaryXAxis: const CategoryAxis(labelStyle: TextStyle(fontSize: 9)),
        primaryYAxis: const NumericAxis(maximum: 150, labelFormat: '{value}%', labelStyle: TextStyle(fontSize: 9)),
        series: [ColumnSeries<EmployeeEfficiency, String>(
          dataSource: _employees,
          xValueMapper: (e, _) => e.empName.split(' ').first,
          yValueMapper: (e, _) => e.efficiencyPct,
          pointColorMapper: (e, _) => _effColor(e.efficiencyPct),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          dataLabelSettings: const DataLabelSettings(isVisible: true, labelAlignment: ChartDataLabelAlignment.top,
            textStyle: TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
        )],
      )),
    ]),
  );

  Widget _piecesChart() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Pieces Produced Today', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black87)),
      const SizedBox(height: 12),
      SizedBox(height: 200, child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        primaryXAxis: const CategoryAxis(labelStyle: TextStyle(fontSize: 9)),
        primaryYAxis: const NumericAxis(labelStyle: TextStyle(fontSize: 9)),
        series: [ColumnSeries<EmployeeEfficiency, String>(
          dataSource: _employees,
          xValueMapper: (e, _) => e.empName.split(' ').first,
          yValueMapper: (e, _) => e.totalPieces,
          color: AppTheme.primary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          dataLabelSettings: const DataLabelSettings(isVisible: true, labelAlignment: ChartDataLabelAlignment.top,
            textStyle: TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
        )],
      )),
    ]),
  );

  Widget _generateButton() => Center(child: Column(children: [
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36),
        const SizedBox(height: 12),
        const Text('Generate AI Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 4),
        const Text('Claude AI will analyze today\'s production\nand generate actionable insights', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 16),
        _generating
            ? const CircularProgressIndicator(color: Colors.white)
            : ElevatedButton.icon(
                onPressed: _generate,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                label: const Text('Generate Report', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
      ]),
    ),
  ]));

  Widget _insightsCard() {
    final sections = _parseSections(_report!.insights);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 18),
        const SizedBox(width: 8),
        const Text('AI Insights', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
        const Spacer(),
        Text(_report!.generatedAt, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ]),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: const Text('Powered by Claude (claude-haiku-4-5)', style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600)),
      ),
      const SizedBox(height: 12),
      ...sections.entries.map((e) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.key, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(e.value.trim(), style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.6)),
        ]),
      )),
    ]);
  }

  Map<String, String> _parseSections(String text) {
    final labels = ['EXECUTIVE SUMMARY', 'TOP PERFORMERS', 'AREAS OF CONCERN', 'OPERATIONAL INSIGHTS', 'RECOMMENDATIONS FOR TOMORROW'];
    final result = <String, String>{};
    for (int i = 0; i < labels.length; i++) {
      final label = labels[i];
      final start = text.indexOf('$label:');
      if (start == -1) continue;
      final contentStart = start + label.length + 1;
      final nextLabel = i + 1 < labels.length ? text.indexOf('${labels[i + 1]}:', contentStart) : -1;
      final content = nextLabel == -1 ? text.substring(contentStart) : text.substring(contentStart, nextLabel);
      result[label] = content.trim();
    }
    if (result.isEmpty) result['ANALYSIS'] = text;
    return result;
  }
}
