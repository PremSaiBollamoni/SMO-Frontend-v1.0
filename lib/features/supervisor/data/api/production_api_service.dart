import '../../../../core/network/api_client.dart';
import '../models/production_models.dart';

class ProductionApiService {
  final _dio = ApiClient().dio;

  Future<List<EmployeeEfficiency>> getEfficiencyByDate(DateTime date) async {
    final d = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
    final res = await _dio.get('/api/production/efficiency/date', queryParameters: {'date': d});
    return (res.data as List).map((j) => EmployeeEfficiency.fromJson(j)).toList();
  }

  Future<List<EmployeeEfficiency>> getEfficiencyToday() => getEfficiencyByDate(DateTime.now());

  Future<List<WorkerProduction>> getEmployeeSlots(int empId, DateTime date) async {
    final d = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final res = await _dio.get('/api/production/employee/$empId/slots', queryParameters: {'date': d});
    return (res.data as List).map((j) => WorkerProduction.fromJson(j)).toList();
  }

  Future<List<WorkerProduction>> getStationProductionToday(int wsId) async {
    final res = await _dio.get('/api/production/station/$wsId/today');
    return (res.data as List).map((j) => WorkerProduction.fromJson(j)).toList();
  }
}
