class QrScanHistory {
  final int id;
  final String qrId;
  final int? employeeId;
  final String scanType;
  final DateTime scanTime;
  final String scannedBy;
  final int? tempQrMappingId;

  QrScanHistory({
    required this.id,
    required this.qrId,
    this.employeeId,
    required this.scanType,
    required this.scanTime,
    required this.scannedBy,
    this.tempQrMappingId,
  });

  factory QrScanHistory.fromJson(Map<String, dynamic> json) {
    return QrScanHistory(
      id: json['id'] as int,
      qrId: json['qrId'] as String,
      employeeId: json['employeeId'] as int?,
      scanType: json['scanType'] as String,
      scanTime: DateTime.parse(json['scanTime'] as String),
      scannedBy: json['scannedBy'] as String,
      tempQrMappingId: json['tempQrMappingId'] as int?,
    );
  }
}
