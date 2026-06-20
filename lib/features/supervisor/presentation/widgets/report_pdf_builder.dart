import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/production_models.dart';
import '../../data/models/report_models.dart';

Future<Uint8List> buildReportPdf(List<EmployeeEfficiency> employees, ReportResult report) async {
  final pdf = pw.Document();
  final sorted = [...employees]..sort((a, b) => b.efficiencyPct.compareTo(a.efficiencyPct));
  final maxPieces = employees.isEmpty ? 1 : employees.map((e) => e.totalPieces).reduce((a, b) => a > b ? a : b);
  final sections = _parseSections(report.insights);

  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    header: (_) => _header(report),
    footer: (_) => pw.Text('PALMS - Production & Labour Management System',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
    build: (ctx) => [
      pw.SizedBox(height: 16),
      _summaryRow(report),
      pw.SizedBox(height: 20),
      _sectionTitle('Efficiency by Operator (%)'),
      pw.SizedBox(height: 10),
      _barChart(sorted, (e) => e.efficiencyPct, 150, (e) => _effPdfColor(e.efficiencyPct), (e) => '${e.efficiencyPct.toStringAsFixed(0)}%'),
      pw.SizedBox(height: 20),
      _sectionTitle('Pieces Produced'),
      pw.SizedBox(height: 10),
      _barChart(sorted, (e) => e.totalPieces.toDouble(), maxPieces.toDouble(), (_) => PdfColors.indigo400, (e) => '${e.totalPieces}'),
      pw.SizedBox(height: 20),
      _sectionTitle('Detailed Breakdown'),
      pw.SizedBox(height: 8),
      _table(sorted),
      pw.SizedBox(height: 24),
      _sectionTitle('AI Insights - Gemini Analysis'),
      pw.SizedBox(height: 8),
      _insightsSection(sections),
    ],
  ));
  return pdf.save();
}

Map<String, String> _parseSections(String text) {
  String clean = text
      .replaceAll(RegExp(r'\*\*'), '')
      .replaceAll(RegExp(r'##+ ?'), '')
      .replaceAll(RegExp(r'\* '), '')
      .replaceAll('—', '-')
      .replaceAll('–', '-');

  final labels = ['EXECUTIVE SUMMARY', 'TOP PERFORMERS', 'AREAS OF CONCERN', 'OPERATIONAL INSIGHTS', 'RECOMMENDATIONS FOR TOMORROW'];
  final result = <String, String>{};
  final upper = clean.toUpperCase();

  for (int i = 0; i < labels.length; i++) {
    final label = labels[i];
    final pattern = RegExp('$label:?', caseSensitive: false);
    final match = pattern.firstMatch(upper);
    if (match == null) continue;
    final contentStart = match.end;
    final nextMatch = i + 1 < labels.length
        ? RegExp('${labels[i + 1]}:?', caseSensitive: false).firstMatch(upper.substring(contentStart))
        : null;
    final content = nextMatch == null
        ? clean.substring(contentStart)
        : clean.substring(contentStart, contentStart + nextMatch.start);
    result[label] = content.trim();
  }
  if (result.isEmpty) result['AI INSIGHTS'] = clean.trim();
  return result;
}

PdfColor _effPdfColor(double e) => e >= 100 ? PdfColors.green700 : e >= 80 ? PdfColors.orange700 : PdfColors.red600;

pw.Widget _header(ReportResult r) => pw.Container(
  padding: const pw.EdgeInsets.only(bottom: 12),
  decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.indigo700, width: 2))),
  child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Production Efficiency Report', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo700)),
      pw.Text('PALMS - Garment Factory Management', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
    ]),
    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
      pw.Text(r.generatedAt, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      pw.Text('AI-Generated · gemini-3-flash-preview', style: pw.TextStyle(fontSize: 9, color: PdfColors.indigo400, fontStyle: pw.FontStyle.italic)),
    ]),
  ]),
);

pw.Widget _summaryRow(ReportResult r) => pw.Row(children: [
  _statBox('Overall Efficiency', '${r.overallEfficiency}%', PdfColors.indigo700),
  pw.SizedBox(width: 12),
  _statBox('Total Operators', '${r.totalOperators}', PdfColors.teal700),
  pw.SizedBox(width: 12),
  _statBox('Total Pieces', '${r.totalPieces}', PdfColors.orange700),
]);

pw.Widget _statBox(String label, String value, PdfColor color) => pw.Expanded(child:
  pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(6)),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
      pw.SizedBox(height: 4),
      pw.Text(value, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    ]),
  ));

pw.Widget _sectionTitle(String t) => pw.Text(t,
  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800));

String _shortName(String name) {
  final parts = name.trim().split(' ');
  if (parts.length == 1) return name;
  // First name + first letter of last name
  return '${parts.first} ${parts.last[0]}.';
}

pw.Widget _barChart(
  List<EmployeeEfficiency> sorted,
  double Function(EmployeeEfficiency) getValue,
  double maxVal,
  PdfColor Function(EmployeeEfficiency) getColor,
  String Function(EmployeeEfficiency) getLabel,
) {
  const chartH = 90.0;
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: sorted.map((emp) {
      final ratio = maxVal > 0 ? (getValue(emp) / maxVal).clamp(0.0, 1.0) : 0.0;
      final barH = ratio * chartH;
      final color = getColor(emp);
      final name = _shortName(emp.empName);
      return pw.Expanded(child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(getLabel(emp), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 2),
          pw.Container(height: barH == 0 ? 2 : barH, margin: const pw.EdgeInsets.symmetric(horizontal: 2),
            decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(2))),
          pw.SizedBox(height: 4),
          pw.Text(name, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
        ],
      ));
    }).toList(),
  );
}

pw.Widget _table(List<EmployeeEfficiency> sorted) {
  const headerStyle = pw.TextStyle(fontSize: 9, color: PdfColors.white);
  const rowStyle = pw.TextStyle(fontSize: 9);
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    columnWidths: {0: const pw.FlexColumnWidth(2.5), 1: const pw.FlexColumnWidth(2), 2: const pw.FlexColumnWidth(1), 3: const pw.FlexColumnWidth(1), 4: const pw.FlexColumnWidth(1.2)},
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.indigo700),
        children: ['Operator', 'Operation', 'Pieces', 'Slots', 'Efficiency']
          .map((h) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(h, style: headerStyle))).toList(),
      ),
      ...sorted.asMap().entries.map((entry) {
        final emp = entry.value;
        final bg = entry.key.isEven ? PdfColors.grey50 : PdfColors.white;
        final effColor = _effPdfColor(emp.efficiencyPct);
        return pw.TableRow(
          decoration: pw.BoxDecoration(color: bg),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(emp.empName, style: rowStyle)),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(emp.operations.join(', '), style: rowStyle)),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${emp.totalPieces}', style: rowStyle)),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${emp.productiveSlots}', style: rowStyle)),
            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${emp.efficiencyPct.toStringAsFixed(1)}%',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: effColor))),
          ],
        );
      }),
    ],
  );
}

pw.Widget _insightsSection(Map<String, String> sections) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(color: PdfColors.indigo100, borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Text('Powered by Gemini AI (gemini-3-flash-preview)',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.indigo700, fontStyle: pw.FontStyle.italic)),
    ),
    pw.SizedBox(height: 10),
    ...sections.entries.map((e) => pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.indigo200),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(e.key, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800)),
        pw.SizedBox(height: 5),
        pw.Text(e.value, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
      ]),
    )),
  ],
);
