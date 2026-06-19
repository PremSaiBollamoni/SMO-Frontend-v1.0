class ShiftBreakModel {
  final int breakId;
  final String breakName;
  final String startTime;
  final String endTime;

  const ShiftBreakModel({
    required this.breakId,
    required this.breakName,
    required this.startTime,
    required this.endTime,
  });

  factory ShiftBreakModel.fromJson(Map<String, dynamic> j) => ShiftBreakModel(
        breakId: j['breakId'] as int,
        breakName: j['breakName'] as String,
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
      );
}

class ShiftTemplateModel {
  final int templateId;
  final String shiftName;
  final String startTime;
  final String endTime;
  final String status;
  final List<ShiftBreakModel> breaks;

  const ShiftTemplateModel({
    required this.templateId,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.breaks,
  });

  bool get isActive => status == 'ACTIVE';

  factory ShiftTemplateModel.fromJson(Map<String, dynamic> j) =>
      ShiftTemplateModel(
        templateId: j['templateId'] as int,
        shiftName: j['shiftName'] as String,
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        status: j['status'] as String,
        breaks: (j['breaks'] as List<dynamic>? ?? [])
            .map((b) => ShiftBreakModel.fromJson(b as Map<String, dynamic>))
            .toList(),
      );
}
