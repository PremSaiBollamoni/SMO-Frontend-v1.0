class OperationStockView {
  final int operationId;
  final String operationName;
  final int sequence;
  final int binCount;
  final int actualQty;
  final int minTarget;
  final int maxTarget;
  final int varianceFromMin;
  final int spaceRemaining;
  final String stockStatus;

  OperationStockView({
    required this.operationId,
    required this.operationName,
    required this.sequence,
    required this.binCount,
    required this.actualQty,
    required this.minTarget,
    required this.maxTarget,
    required this.varianceFromMin,
    required this.spaceRemaining,
    required this.stockStatus,
  });

  factory OperationStockView.fromJson(Map<String, dynamic> json) {
    return OperationStockView(
      operationId: json['operationId'] ?? 0,
      operationName: json['operationName'] ?? '',
      sequence: json['sequence'] ?? 0,
      binCount: json['binCount'] ?? 0,
      actualQty: json['actualQty'] ?? 0,
      minTarget: json['minTarget'] ?? 0,
      maxTarget: json['maxTarget'] ?? 0,
      varianceFromMin: json['varianceFromMin'] ?? 0,
      spaceRemaining: json['spaceRemaining'] ?? 0,
      stockStatus: json['stockStatus'] ?? 'NOT_SET',
    );
  }
}
