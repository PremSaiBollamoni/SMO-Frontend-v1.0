import '../api/temp_qr_api_service.dart';
import '../../domain/models/temp_qr_mapping.dart';
import '../../domain/models/qr_scan_history.dart';
import '../../domain/models/temp_qr_scan_response.dart';

class TempQrRepository {
  final TempQrApiService _apiService = TempQrApiService();
  
  Future<TempQrScanResponse> scanQrCode({
    required String qrId,
    int? employeeId,
    required String scannedBy,
  }) async {
    return await _apiService.scanQrCode(
      qrId: qrId,
      employeeId: employeeId,
      scannedBy: scannedBy,
    );
  }
  
  Future<List<TempQrMapping>> getActiveMappings() async {
    return await _apiService.getActiveMappings();
  }
  
  Future<List<TempQrMapping>> getAllMappings() async {
    return await _apiService.getAllMappings();
  }
  
  Future<List<QrScanHistory>> getScanHistory() async {
    return await _apiService.getScanHistory();
  }
  
  Future<List<QrScanHistory>> getScanHistoryByQrId(String qrId) async {
    return await _apiService.getScanHistoryByQrId(qrId);
  }
  
  Future<bool> unmapQrCode(int mappingId, String unmappedBy) async {
    return await _apiService.unmapQrCode(mappingId, unmappedBy);
  }
}
