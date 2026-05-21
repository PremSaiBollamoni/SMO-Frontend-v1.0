import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/temp_qr_mapping.dart';
import '../../domain/models/qr_scan_history.dart';
import '../../domain/models/temp_qr_scan_response.dart';

class TempQrApiService {
  Future<TempQrScanResponse> scanQrCode({
    required String qrId,
    int? employeeId,
    required String scannedBy,
  }) async {
    try {
      final body = {
        'qrId': qrId,
        if (employeeId != null) 'employeeId': employeeId,
        'scannedBy': scannedBy,
      };
      
      final response = await ApiClient().dio.post(
        '/api/temp-qr/scan',
        data: body,
      );
      
      return TempQrScanResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to scan QR code: $e');
    }
  }
  
  Future<List<TempQrMapping>> getActiveMappings() async {
    try {
      final response = await ApiClient().dio.get('/api/temp-qr/active');
      final List<dynamic> data = response.data;
      return data.map((json) => TempQrMapping.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load active mappings: $e');
    }
  }
  
  Future<List<TempQrMapping>> getAllMappings() async {
    try {
      final response = await ApiClient().dio.get('/api/temp-qr/all');
      final List<dynamic> data = response.data;
      return data.map((json) => TempQrMapping.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load mappings: $e');
    }
  }
  
  Future<List<QrScanHistory>> getScanHistory() async {
    try {
      final response = await ApiClient().dio.get('/api/temp-qr/history');
      final List<dynamic> data = response.data;
      return data.map((json) => QrScanHistory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load scan history: $e');
    }
  }
  
  Future<List<QrScanHistory>> getScanHistoryByQrId(String qrId) async {
    try {
      final response = await ApiClient().dio.get('/api/temp-qr/history/$qrId');
      final List<dynamic> data = response.data;
      return data.map((json) => QrScanHistory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load scan history: $e');
    }
  }
  
  Future<bool> unmapQrCode(int mappingId, String unmappedBy) async {
    try {
      final response = await ApiClient().dio.post(
        '/api/temp-qr/unmap/$mappingId',
        queryParameters: {'unmappedBy': unmappedBy},
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to unmap QR code: $e');
    }
  }
}
