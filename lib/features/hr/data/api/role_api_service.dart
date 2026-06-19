import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/app_config.dart';
import '../models/create_role_request.dart';
import '../../domain/models/role_model.dart';

class RoleApiService {
  final Dio _dio;

  RoleApiService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<List<RoleModel>> fetchRoles(String actorEmpId) async {
    final res = await _dio.get(ApiEndpoints.hrRoles,
        queryParameters: {QueryParams.actorEmpId: actorEmpId});
    return (res.data as List).map((e) => RoleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createRole(CreateRoleRequest request) async {
    await _dio.post(ApiEndpoints.hrRoles, data: request.toJson());
  }

  Future<void> deleteRole(int roleId) async {
    await _dio.delete('${ApiEndpoints.hrRoles}/$roleId');
  }

  Future<void> deleteRoles(List<int> roleIds) async {
    try {
      await _dio.delete(ApiEndpoints.hrRoles, data: {'roleIds': roleIds});
    } on DioException catch (e) {
      if (e.response?.statusCode == 500 || e.response?.statusCode == 404) {
        int failed = 0;
        for (final id in roleIds) {
          try { await deleteRole(id); } catch (_) { failed++; }
        }
        if (failed == roleIds.length) throw Exception('Failed to delete all roles');
        return;
      }
      rethrow;
    }
  }
}
