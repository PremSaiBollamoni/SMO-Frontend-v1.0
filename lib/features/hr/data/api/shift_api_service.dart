import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/shift_models.dart';

class ShiftApiService {
  final Dio _dio = ApiClient().dio;

  Future<List<ShiftTemplateModel>> getAllShifts() async {
    final res = await _dio.get('/api/hr/shifts');
    return (res.data as List)
        .map((j) => ShiftTemplateModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<ShiftTemplateModel>> getActiveShifts() async {
    final res = await _dio.get('/api/hr/shifts/active');
    return (res.data as List)
        .map((j) => ShiftTemplateModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<ShiftTemplateModel> createShift({
    required String shiftName,
    required String startTime,
    required String endTime,
    required int createdBy,
  }) async {
    final res = await _dio.post(
      '/api/hr/shifts',
      queryParameters: {'createdBy': createdBy},
      data: {'shiftName': shiftName, 'startTime': startTime, 'endTime': endTime},
    );
    return ShiftTemplateModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ShiftTemplateModel> addBreak({
    required int templateId,
    required String breakName,
    required String startTime,
    required String endTime,
  }) async {
    final res = await _dio.post(
      '/api/hr/shifts/$templateId/breaks',
      data: {'breakName': breakName, 'startTime': startTime, 'endTime': endTime},
    );
    return ShiftTemplateModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteBreak(int breakId) async {
    await _dio.delete('/api/hr/shifts/breaks/$breakId');
  }

  Future<ShiftTemplateModel> toggleStatus(int templateId) async {
    final res = await _dio.patch('/api/hr/shifts/$templateId/toggle');
    return ShiftTemplateModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteShift(int templateId) async {
    await _dio.delete('/api/hr/shifts/$templateId');
  }
}
