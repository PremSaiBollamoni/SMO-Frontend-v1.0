class StockLimit {
  final int? limitId;
  final int operationId;
  final int minQtyPerDay;
  final int maxQtyPerDay;
  final int minQtyPerMonth;
  final int maxQtyPerMonth;
  final int? lowStockThreshold;
  final int? highStockThreshold;
  final String unit;

  StockLimit({
    this.limitId,
    required this.operationId,
    required this.minQtyPerDay,
    required this.maxQtyPerDay,
    required this.minQtyPerMonth,
    required this.maxQtyPerMonth,
    this.lowStockThreshold,
    this.highStockThreshold,
    this.unit = 'PIECES',
  });

  Map<String, dynamic> toJson() {
    return {
      'operationId': operationId,
      'minQtyPerDay': minQtyPerDay,
      'maxQtyPerDay': maxQtyPerDay,
      'minQtyPerMonth': minQtyPerMonth,
      'maxQtyPerMonth': maxQtyPerMonth,
      'lowStockThreshold': lowStockThreshold,
      'highStockThreshold': highStockThreshold,
      'unit': unit,
    };
  }

  factory StockLimit.fromJson(Map<String, dynamic> json) {
    return StockLimit(
      limitId: json['limitId'],
      operationId: json['operationId'] ?? 0,
      minQtyPerDay: json['minQtyPerDay'] ?? 0,
      maxQtyPerDay: json['maxQtyPerDay'] ?? 0,
      minQtyPerMonth: json['minQtyPerMonth'] ?? 0,
      maxQtyPerMonth: json['maxQtyPerMonth'] ?? 0,
      lowStockThreshold: json['lowStockThreshold'],
      highStockThreshold: json['highStockThreshold'],
      unit: json['unit'] ?? 'PIECES',
    );
  }
}
