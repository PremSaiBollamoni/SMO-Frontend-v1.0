class RawMaterialStock {
  final int rawMaterialId;
  final String materialType;
  final String materialName;
  final String? materialCode;
  final double currentStock;
  final String unit;
  final String? warehouseLocation;
  final double minStockLevel;
  final double maxStockLevel;
  final double reorderLevel;
  final String stockStatus; // LOW, NORMAL, HIGH, CRITICAL
  final DateTime? lastUpdated;

  RawMaterialStock({
    required this.rawMaterialId,
    required this.materialType,
    required this.materialName,
    this.materialCode,
    required this.currentStock,
    required this.unit,
    this.warehouseLocation,
    required this.minStockLevel,
    required this.maxStockLevel,
    required this.reorderLevel,
    required this.stockStatus,
    this.lastUpdated,
  });

  factory RawMaterialStock.fromJson(Map<String, dynamic> json) {
    return RawMaterialStock(
      rawMaterialId: json['rawMaterialId'] ?? 0,
      materialType: json['materialType'] ?? '',
      materialName: json['materialName'] ?? '',
      materialCode: json['materialCode'],
      currentStock: (json['currentStock'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      warehouseLocation: json['warehouseLocation'],
      minStockLevel: (json['minStockLevel'] ?? 0).toDouble(),
      maxStockLevel: (json['maxStockLevel'] ?? 0).toDouble(),
      reorderLevel: (json['reorderLevel'] ?? 0).toDouble(),
      stockStatus: json['stockStatus'] ?? 'NORMAL',
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : null,
    );
  }
}
