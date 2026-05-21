class TempQrScanResponse {
  final String scanType;
  final String qrId;
  final int? employeeId;
  final String? employeeName;
  final DateTime scanTime;
  final String message;
  final int? mappingId;

  TempQrScanResponse({
    required this.scanType,
    required this.qrId,
    this.employeeId,
    this.employeeName,
    required this.scanTime,
    required this.message,
    this.mappingId,
  });

  factory TempQrScanResponse.fromJson(Map<String, dynamic> json) {
    return TempQrScanResponse(
      scanType: json['scanType'] as String,
      qrId: json['qrId'] as String,
      employeeId: json['employeeId'] as int?,
      employeeName: json['employeeName'] as String?,
      scanTime: DateTime.parse(json['scanTime'] as String),
      message: json['message'] as String,
      mappingId: json['mappingId'] as int?,
    );
  }
}
