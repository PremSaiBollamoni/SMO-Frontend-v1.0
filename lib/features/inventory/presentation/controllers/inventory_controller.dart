import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:smo_flutter/features/inventory/data/inventory_api.dart';
import 'package:smo_flutter/features/inventory/domain/models/operation_stock_view.dart';

class InventoryController extends GetxController {
  var isLoading = false.obs;
  var operations = <OperationStockView>[].obs;
  var summary = <String, dynamic>{}.obs;
  var selectedFilter = 'ALL'.obs;
  var selectedRoutingId = Rx<int?>(null);
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Build URL with optional routing parameter
      String url = '/api/inventory/dashboard';
      if (selectedRoutingId.value != null) {
        url += '?routingId=${selectedRoutingId.value}';
      }
      
      final data = await InventoryApi.getDashboardWithUrl(url);
      
      final List<dynamic> opsData = data['operations'] ?? [];
      operations.value = opsData.map((json) => OperationStockView.fromJson(json)).toList();
      
      summary.value = data['summary'] ?? {};
      
    } catch (e) {
      debugPrint('Failed to load inventory dashboard: $e');
      errorMessage.value = 'Failed to load dashboard: $e';
      // Don't use snackbar in controller - let UI handle it
    } finally {
      isLoading.value = false;
    }
  }

  void setRoutingFilter(int? routingId) {
    selectedRoutingId.value = routingId;
    loadDashboard();
  }

  List<OperationStockView> get filteredOperations {
    if (selectedFilter.value == 'ALL') {
      return operations;
    } else if (selectedFilter.value == 'LOW') {
      return operations.where((op) => op.stockStatus == 'LOW').toList();
    } else if (selectedFilter.value == 'HIGH') {
      return operations.where((op) => op.stockStatus == 'HIGH').toList();
    } else if (selectedFilter.value == 'NOT_SET') {
      return operations.where((op) => op.stockStatus == 'NOT_SET').toList();
    } else {
      return operations.where((op) => op.stockStatus == 'NORMAL').toList();
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }
}
