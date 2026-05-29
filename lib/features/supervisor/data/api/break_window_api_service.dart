import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class BreakWindowApiService {
  final Dio _dio = ApiClient().dio;

  Future<List<Map<String, dynamic>>> getAllBreakWindows() async {
    final response = await _dio.get('/api/supervisor/break-windows');
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(response.data);
    }
    throw Exception('Failed to fetch break windows');
  }

  Future<Map<String, dynamic>> createBreakWindow({
    required String breakName,
    required String breakStart, // HH:mm
    required String breakEnd,   // HH:mm
    int? createdBy,
  }) async {
    final response = await _dio.post(
      '/api/supervisor/break-windows',
      data: {
        'breakName': breakName,
        'breakStart': breakStart,
        'breakEnd': breakEnd,
        if (createdBy != null) 'createdBy': createdBy,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(response.data);
    }
    throw Exception('Failed to create break window');
  }

  Future<void> deleteBreakWindow(int id) async {
    await _dio.delete('/api/supervisor/break-windows/$id');
  }

  Future<void> deactivateBreakWindow(int id) async {
    await _dio.patch('/api/supervisor/break-windows/$id/deactivate');
  }
}
