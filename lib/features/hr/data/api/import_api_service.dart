import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class ImportResult {
  final int opsCreated;
  final int opsUpdated;
  final int stationsCreated;
  final int stationsLinked;

  ImportResult.fromJson(Map<String, dynamic> j)
      : opsCreated = j['opsCreated'] ?? 0,
        opsUpdated = j['opsUpdated'] ?? 0,
        stationsCreated = j['stationsCreated'] ?? 0,
        stationsLinked = j['stationsLinked'] ?? 0;
}

class ImportApiService {
  final _dio = ApiClient().dio;

  Future<ImportResult> uploadExcel(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
    });
    final res = await _dio.post('/api/hr/import/upload', data: formData);
    return ImportResult.fromJson(res.data);
  }

  Future<ImportResult> uploadExcelBytes(List<int> bytes, String filename) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _dio.post('/api/hr/import/upload', data: formData);
    return ImportResult.fromJson(res.data);
  }
}
