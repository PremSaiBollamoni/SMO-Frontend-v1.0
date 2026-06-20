class ReportResult {
  final String insights;
  final String generatedAt;
  final double overallEfficiency;
  final int totalOperators;
  final int totalPieces;

  const ReportResult({
    required this.insights,
    required this.generatedAt,
    required this.overallEfficiency,
    required this.totalOperators,
    required this.totalPieces,
  });

  factory ReportResult.fromJson(Map<String, dynamic> j) => ReportResult(
    insights: j['insights'] ?? '',
    generatedAt: j['generatedAt'] ?? '',
    overallEfficiency: (j['overallEfficiency'] ?? 0).toDouble(),
    totalOperators: j['totalOperators'] ?? 0,
    totalPieces: j['totalPieces'] ?? 0,
  );
}
