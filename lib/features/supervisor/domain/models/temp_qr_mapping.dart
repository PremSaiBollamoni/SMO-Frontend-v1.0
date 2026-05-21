class TempQrMapping {
  final int id;
  final String qrId;
  final int employeeId;
  final String? employeeName;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final DateTime? createdAt;
  final String? createdBy;

  TempQrMapping({
    required this.id,
    required this.qrId,
    required this.employeeId,
    this.employeeName,
    required this.startTime,
    this.endTime,
    required this.status,
    this.createdAt,
    this.createdBy,
  });

  factory TempQrMapping.fromJson(Map<String, dynamic> json) {
    return TempQrMapping(
      id: json['id'] as int,
      qrId: json['qrId'] as String,
      employeeId: json['employeeId'] as int,
      employeeName: json['employeeName'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      status: json['status'] as String,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      createdBy: json['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'qrId': qrId,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}
