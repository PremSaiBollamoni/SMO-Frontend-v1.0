import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/app_config.dart';
import '../models/create_employee_request.dart';
import '../models/create_login_request.dart';
import '../../domain/models/employee_model.dart';
import '../../domain/models/employee_profile_model.dart';

class EmployeeApiService {
  final Dio _dio;

  EmployeeApiService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<List<EmployeeModel>> fetchEmployees(String actorEmpId) async {
    final res = await _dio.get(ApiEndpoints.hrEmployees,
        queryParameters: {QueryParams.actorEmpId: actorEmpId});
    return (res.data as List).map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<EmployeeProfileModel> fetchEmployeeProfile(String empId, String actorEmpId) async {
    final res = await _dio.get('${ApiEndpoints.hrEmployeeDetail}/$empId',
        queryParameters: {QueryParams.actorEmpId: actorEmpId});
    return EmployeeProfileModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createEmployee(CreateEmployeeRequest request) async {
    final actorEmpId = ApiClient().getEmpId() ?? '1001';
    final res = await _dio.post(ApiEndpoints.hrEmployees,
        data: request.toJson(),
        queryParameters: {QueryParams.actorEmpId: actorEmpId});
    return res.data as Map<String, dynamic>;
  }

  Future<void> createEmployeeLogin(CreateLoginRequest request) async {
    await _dio.post(ApiEndpoints.hrLogin, data: request.toJson());
  }

  Future<void> updateEmployee(String empId, CreateEmployeeRequest request) async {
    await _dio.put('${ApiEndpoints.hrEmployeeDetail}/$empId', data: request.toJson());
  }

  Future<void> updateEmployeeLogin(String empId, CreateLoginRequest request) async {
    await _dio.put('${ApiEndpoints.hrLoginUpdate}/$empId', data: request.toJson());
  }

  Future<void> deleteEmployee(String empId) async {
    await _dio.delete('${ApiEndpoints.hrEmployeeDetail}/$empId');
  }

  Future<void> deleteEmployees(List<String> empIds) async {
    try {
      await _dio.delete(ApiEndpoints.hrEmployees, data: {'empIds': empIds});
    } on DioException catch (e) {
      if (e.response?.statusCode == 500 || e.response?.statusCode == 404) {
        int failed = 0;
        for (final id in empIds) {
          try { await deleteEmployee(id); } catch (_) { failed++; }
        }
        if (failed == empIds.length) throw Exception('Failed to delete all employees');
        return;
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> exportEmployees(String actorEmpId) async {
    final res = await _dio.get('${ApiEndpoints.hrEmployees}/export/data',
        queryParameters: {QueryParams.actorEmpId: actorEmpId});
    return (res.data as List).map((e) => e as Map<String, dynamic>).toList();
  }
}
