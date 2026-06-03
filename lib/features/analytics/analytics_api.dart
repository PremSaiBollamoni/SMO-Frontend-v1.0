import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class AnalyticsApi {
  final Dio _dio = ApiClient().dio;

  Future<List<Map<String, dynamic>>> getApprovedRoutings() async {
    final res = await _dio.get('/api/analytics/routings');
    return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getOperationsForRouting(int routingId, String date) async {
    final res = await _dio.get('/api/analytics/routing/$routingId/operations', queryParameters: {'date': date});
    return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getEmployeesAtOperation(int operationId, String date) async {
    final res = await _dio.get('/api/analytics/operation/$operationId/employees', queryParameters: {'date': date});
    return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllEmployeesWithStats(String date) async {
    final res = await _dio.get('/api/analytics/employees', queryParameters: {'date': date});
    return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getEmployeeStats(int employeeId, String date) async {
    final res = await _dio.get('/api/analytics/employee/$employeeId/stats', queryParameters: {'date': date});
    return Map<String, dynamic>.from(res.data);
  }

  Future<List<Map<String, dynamic>>> getAllMachinesWithStats(String date) async {
    final res = await _dio.get('/api/analytics/machines', queryParameters: {'date': date});
    return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getMachineStats(int machineId, String date) async {
    final res = await _dio.get('/api/analytics/machine/$machineId/stats', queryParameters: {'date': date});
    return Map<String, dynamic>.from(res.data);
  }
}
