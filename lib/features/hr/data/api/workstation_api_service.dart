import '../../../../core/network/api_client.dart';
import '../models/station_models.dart';

class WorkstationApiService {
  final _dio = ApiClient().dio;

  Future<List<StationModel>> getAll() async {
    final res = await _dio.get('/api/hr/workstations');
    return (res.data as List).map((j) => StationModel.fromJson(j)).toList();
  }

  Future<List<OperationModel>> getOperations() async {
    final res = await _dio.get('/api/hr/operations');
    return (res.data as List).map((j) => OperationModel.fromJson(j)).toList();
  }

  Future<void> create(String wsCode, String? machineCode) async {
    await _dio.post('/api/hr/workstations', data: {
      'wsCode': wsCode,
      'machineCode': machineCode,
    });
  }

  Future<void> assignOperation(int wsId, int opId) async {
    await _dio.patch('/api/hr/workstations/$wsId/assign-operation', data: {'opId': opId});
  }

  Future<void> updateMachineCode(int wsId, String machineCode) async {
    await _dio.patch('/api/hr/workstations/$wsId/machine-code', data: {'machineCode': machineCode});
  }

  Future<void> update(int wsId, {String? wsCode, String? machineCode}) async {
    await _dio.patch('/api/hr/workstations/$wsId', data: {
      if (wsCode != null) 'wsCode': wsCode,
      if (machineCode != null) 'machineCode': machineCode,
    });
  }

  Future<void> delete(int wsId) async {
    await _dio.delete('/api/hr/workstations/$wsId');
  }
}
