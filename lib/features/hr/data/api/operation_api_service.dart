import '../../../../core/network/api_client.dart';

class OperationModel {
  final int opId;
  final String opCode;
  final String opName;
  final String stage;
  final int sequenceNo;
  final double? sam;
  final String? skillGrade;
  final int? targetPcs;

  OperationModel({
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
        opCode: j['opCode'],
        opName: j['opName'],
        stage: j['stage'] ?? j['zone'] ?? '',
        sequenceNo: j['sequenceNo'],
        sam: j['sam'] != null ? (j['sam'] as num).toDouble() : null,
        skillGrade: j['skillGrade'],
        targetPcs: j['targetPcs'],
      );
}

class OperationApiService {
  final _dio = ApiClient().dio;

  Future<List<OperationModel>> getOperations() async {
    final res = await _dio.get('/api/hr/operations');
    return (res.data as List).map((j) => OperationModel.fromJson(j)).toList();
  }

  Future<OperationModel> createOperation({
    required String opCode,
    required String opName,
    required String stage,
    required int sequenceNo,
    double? sam,
    String? skillGrade,
    int? targetPcs,
  }) async {
    final res = await _dio.post('/api/hr/operations', data: {
      'opCode': opCode,
      'opName': opName,
      'stage': stage,
      'sequenceNo': sequenceNo,
      if (sam != null) 'sam': sam,
      if (skillGrade != null) 'skillGrade': skillGrade,
      if (targetPcs != null) 'targetPcs': targetPcs,
    });
    return OperationModel.fromJson(res.data);
  }

  Future<void> deleteOperation(int opId) async {
    await _dio.delete('/api/hr/operations/$opId');
  }

  Future<OperationModel> updateOperation({
    required int opId,
    String? opName,
    String? stage,
    int? sequenceNo,
    double? sam,
    String? skillGrade,
    int? targetPcs,
  }) async {
    final res = await _dio.patch('/api/hr/operations/$opId/sam', data: {
      if (opName != null) 'opName': opName,
      if (stage != null) 'stage': stage,
      if (sequenceNo != null) 'sequenceNo': sequenceNo,
      if (sam != null) 'sam': sam,
      if (skillGrade != null) 'skillGrade': skillGrade,
      if (targetPcs != null) 'targetPcs': targetPcs,
    });
    return OperationModel.fromJson(res.data);
  }
}
