class OperationModel {
  final int opId;
  final String opCode;
  final String opName;
  final String stage;
  final int sequenceNo;
  final double? sam;
  final String? skillGrade;
  final int? targetPcs;

  const OperationModel({
    required this.opId,
    required this.opCode,
    required this.opName,
    required this.stage,
    required this.sequenceNo,
    this.sam,
    this.skillGrade,
    this.targetPcs,
  });

  factory OperationModel.fromJson(Map<String, dynamic> j) => OperationModel(
        opId: j['opId'],
        opCode: j['opCode'] ?? '',
        opName: j['opName'] ?? '',
        stage: j['stage'] ?? '',
        sequenceNo: j['sequenceNo'] ?? 0,
        sam: j['sam'] != null ? (j['sam'] as num).toDouble() : null,
        skillGrade: j['skillGrade'],
        targetPcs: j['targetPcs'],
      );
}

class StationModel {
  final int wsId;
  final String wsCode;
  final String? machineCode;
  final String status;
  final OperationModel? operation;

  const StationModel({
    required this.wsId,
    required this.wsCode,
    this.machineCode,
    required this.status,
    this.operation,
  });

  factory StationModel.fromJson(Map<String, dynamic> j) => StationModel(
        wsId: j['wsId'],
        wsCode: j['wsCode'] ?? '',
        machineCode: j['machineCode'],
        status: j['status'] ?? 'ACTIVE',
        operation: j['operation'] != null ? OperationModel.fromJson(j['operation']) : null,
      );
}
