import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repository/temp_qr_repository.dart';
import '../../domain/models/temp_qr_mapping.dart';
import '../../domain/models/qr_scan_history.dart';
import '../../domain/models/temp_qr_scan_response.dart';

class TempQrController extends GetxController {
  final TempQrRepository _repository = TempQrRepository();
  
  final RxList<TempQrMapping> activeMappings = <TempQrMapping>[].obs;
  final RxList<TempQrMapping> allMappings = <TempQrMapping>[].obs;
  final RxList<QrScanHistory> scanHistory = <QrScanHistory>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedView = 'active'.obs; // active, all, history
  
  final String empId;
  
  TempQrController({required this.empId});
  
  @override
  void onInit() {
    super.onInit();
    loadActiveMappings();
  }
  
  Future<void> loadActiveMappings() async {
    try {
      isLoading.value = true;
      activeMappings.value = await _repository.getActiveMappings();
    } catch (e) {
      debugPrint('Error loading active mappings: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> loadAllMappings() async {
    try {
      isLoading.value = true;
      allMappings.value = await _repository.getAllMappings();
    } catch (e) {
      debugPrint('Error loading all mappings: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> loadScanHistory() async {
    try {
      isLoading.value = true;
      scanHistory.value = await _repository.getScanHistory();
    } catch (e) {
      debugPrint('Error loading scan history: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<TempQrScanResponse?> scanQrCode({
    required String qrId,
    int? employeeId,
  }) async {
    try {
      isLoading.value = true;
      final response = await _repository.scanQrCode(
        qrId: qrId,
        employeeId: employeeId,
        scannedBy: empId,
      );
      
      // Refresh active mappings after scan
      await loadActiveMappings();
      
      return response;
    } catch (e) {
      debugPrint('Error scanning QR code: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<bool> unmapQrCode(int mappingId) async {
    try {
      isLoading.value = true;
      final success = await _repository.unmapQrCode(mappingId, empId);
      
      if (success) {
        await loadActiveMappings();
      }
      
      return success;
    } catch (e) {
      debugPrint('Error unmapping QR code: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  void changeView(String view) {
    selectedView.value = view;
    
    switch (view) {
      case 'active':
        loadActiveMappings();
        break;
      case 'all':
        loadAllMappings();
        break;
      case 'history':
        loadScanHistory();
        break;
    }
  }
}
