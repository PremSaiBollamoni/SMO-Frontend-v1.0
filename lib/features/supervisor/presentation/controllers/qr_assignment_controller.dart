import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/api/qr_assignment_api_service.dart';
import '../../domain/models/qr_assignment_model.dart';

class QrAssignmentController extends GetxController {
  final QrAssignmentApiService _apiService = QrAssignmentApiService();
  final formKey = GlobalKey<FormState>();

  // Form fields
  final qrCodeController = TextEditingController();
  final nextOperationController = TextEditingController();
  final notesController = TextEditingController();

  // Dropdown values
  var selectedProcessPlan = Rx<String?>(null);
  var selectedStyle = Rx<String?>(null);
  var selectedSize = Rx<String?>(null);
  var selectedGtg = Rx<String?>(null);
  var selectedBtn = Rx<String?>(null);
  var selectedLabel = Rx<String?>(null);
  var selectedOrderNumber = Rx<String?>(null); // Added for order linkage
  var selectedNextOperation = Rx<String?>(null); // Changed from text field to dropdown

  // Tray quantity
  var trayQuantity = 1.obs;

  // Dropdown options
  var processPlanNumbers = <String>[].obs;
  var styles = <String>[].obs;
  var sizes = <String>[].obs;
  var gtgNumbers = <String>[].obs;
  var btnNumbers = <String>[].obs;
  var labels = <String>[].obs;
  var activeOrders = <Map<String, dynamic>>[].obs; // Added for order selection
  var operations = <Map<String, dynamic>>[].obs; // Added for next operation dropdown

  // Loading states
  var isLoading = false.obs;
  var isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDropdownData();
    loadActiveOrders();
  }

  @override
  void onClose() {
    qrCodeController.dispose();
    nextOperationController.dispose();
    notesController.dispose();
    super.onClose();
  }

  // Load all dropdown data
  Future<void> loadDropdownData() async {
    try {
      isLoading.value = true;

      final results = await Future.wait([
        _apiService.getProcessPlanNumbers(),
        _apiService.getStyles(),
        _apiService.getSizes(),
        _apiService.getGtgNumbers(),
        _apiService.getBtnNumbers(),
        _apiService.getLabels(),
      ]);

      processPlanNumbers.value = results[0];
      styles.value = results[1];
      sizes.value = results[2];
      gtgNumbers.value = results[3];
      btnNumbers.value = results[4];
      labels.value = results[5];
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load dropdown data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load active orders
  Future<void> loadActiveOrders() async {
    try {
      final orders = await _apiService.getActiveOrders();
      activeOrders.value = orders;
    } catch (e) {
      debugPrint('[QR_ASSIGNMENT] Failed to load active orders: $e');
    }
  }

  // Load operations for selected process plan
  Future<void> loadOperations(String routingId) async {
    try {
      operations.clear();
      selectedNextOperation.value = null;
      
      final ops = await _apiService.getOperationsForRouting(routingId);
      operations.value = ops;
    } catch (e) {
      debugPrint('[QR_ASSIGNMENT] Failed to load operations: $e');
    }
  }

  // Increment tray quantity
  void incrementTrayQuantity() {
    trayQuantity.value++;
  }

  // Decrement tray quantity
  void decrementTrayQuantity() {
    if (trayQuantity.value > 1) {
      trayQuantity.value--;
    }
  }

  // Set QR code from scanner
  void setQrCode(String code) {
    if (code.trim().isNotEmpty) {
      qrCodeController.text = code.trim();
    }
  }

  // Validate form
  bool validateForm() {
    if (formKey.currentState?.validate() != true) {
      return false;
    }

    if (selectedProcessPlan.value == null ||
        selectedProcessPlan.value!.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please select a Process Plan Number',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (qrCodeController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please scan or enter a QR Code',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (trayQuantity.value <= 0) {
      Get.snackbar(
        'Validation Error',
        'Tray quantity must be greater than 0',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  // Submit form with next operation passed from widget
  Future<void> submitForm({
    String? nextOperationName,
    int? nextOperationId,
    int? operationId, // Current operation user clicked on (starting op)
  }) async {
    if (!validateForm()) return;

    try {
      isSubmitting.value = true;

      final assignment = QrAssignmentModel(
        processPlanNumber: selectedProcessPlan.value!,
        qrCode: qrCodeController.text.trim(),
        style: selectedStyle.value?.trim() ?? '',
        size: selectedSize.value?.trim() ?? '',
        gtgNumber: selectedGtg.value?.trim() ?? '',
        btnNumber: selectedBtn.value?.trim() ?? '',
        label: selectedLabel.value?.trim() ?? '',
        nextOperation: nextOperationName?.trim() ?? '',
        trayQuantity: trayQuantity.value,
        supervisorId: 1004,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        orderNumber: selectedOrderNumber.value, // Include order number
        operationId: operationId, // Pass starting operation ID
      );

      print('[QR_ASSIGNMENT] ═══ QR ASSIGNMENT SUBMISSION START ═══');
      print('[QR_ASSIGNMENT] Process Plan: ${assignment.processPlanNumber}');
      print('[QR_ASSIGNMENT] QR Code: ${assignment.qrCode}');
      print('[QR_ASSIGNMENT] Style: ${assignment.style}');
      print('[QR_ASSIGNMENT] Size: ${assignment.size}');
      print('[QR_ASSIGNMENT] GTG: ${assignment.gtgNumber}');
      print('[QR_ASSIGNMENT] Operation ID (starting): ${assignment.operationId}');
      print('[QR_ASSIGNMENT] Next Operation: ${assignment.nextOperation}');
      print('[QR_ASSIGNMENT] Tray Quantity: ${assignment.trayQuantity}');
      print('[QR_ASSIGNMENT] Order Number: ${assignment.orderNumber}');
      print('[QR_ASSIGNMENT] Submitting assignment...');
      
      final response = await _apiService.submitQrAssignment(assignment);
      print('[QR_ASSIGNMENT] Response received: $response');

      if (response['success'] == true) {
        print('[QR_ASSIGNMENT] ✓ ASSIGNMENT SUCCESSFUL');
        print('[QR_ASSIGNMENT] Bin ID: ${response['binId']}');
        print('[QR_ASSIGNMENT] Current Operation ID: ${response['currentOperationId']}');
        print('[QR_ASSIGNMENT] First Operation ID: ${response['firstOperationId']}');
        print('[QR_ASSIGNMENT] Routing ID: ${response['routingId']}');
        
        String message =
            'QR Assignment Successful!\n\nBin ID: ${response['binId']}\nFirst Operation ID: ${response['currentOperationId']}';
        if (selectedOrderNumber.value != null) {
          message += '\nLinked to Order: ${selectedOrderNumber.value}';
        }
        
        // Show next operation info if available
        if (nextOperationName != null) {
          message += '\n\nNext Operation: $nextOperationName';
        }

        print('[QR_ASSIGNMENT] ═══ QR ASSIGNMENT SUBMISSION END (SUCCESS) ═══');

        // Reset form first
        resetForm();
        
        // Show success snackbar - use Future.delayed to ensure context is ready
        Future.delayed(const Duration(milliseconds: 100), () {
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Success',
              message,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 4),
            );
          }
        });
      } else {
        print('[QR_ASSIGNMENT] ✗ ASSIGNMENT FAILED: ${response['message']}');
        print('[QR_ASSIGNMENT] Error Type: ${response['errorType']}');
        print('[QR_ASSIGNMENT] ═══ QR ASSIGNMENT SUBMISSION END (ERROR) ═══');
        
        String message = response['message'] ?? 'Assignment failed';
        
        Color backgroundColor = Colors.red;
        String errorType = response['errorType'] ?? 'UNKNOWN_ERROR';

        switch (errorType) {
          case 'VALIDATION_ERROR':
            backgroundColor = Colors.orange;
            break;
          case 'STATUS_ERROR':
            backgroundColor = Colors.amber;
            message += '\n\nTip: Complete current assignment first';
            break;
        }

        // Show error snackbar - use Future.delayed to ensure context is ready
        Future.delayed(const Duration(milliseconds: 100), () {
          if (Get.isSnackbarOpen == false) {
            Get.snackbar(
              'Error',
              message,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: backgroundColor,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          }
        });
      }
    } catch (e) {
      print('[QR_ASSIGNMENT] ✗ EXCEPTION: $e');
      print('[QR_ASSIGNMENT] ═══ QR ASSIGNMENT SUBMISSION END (ERROR) ═══');
      Future.delayed(const Duration(milliseconds: 100), () {
        if (Get.isSnackbarOpen == false) {
          Get.snackbar(
            'Error',
            'Failed to submit QR assignment:\n$e',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
      });
    } finally {
      isSubmitting.value = false;
    }
  }

  // Reset form
  void resetForm() {
    formKey.currentState?.reset();
    qrCodeController.clear();
    nextOperationController.clear();
    notesController.clear();
    selectedProcessPlan.value = null;
    selectedStyle.value = null;
    selectedSize.value = null;
    selectedGtg.value = null;
    selectedBtn.value = null;
    selectedLabel.value = null;
    selectedOrderNumber.value = null;
    selectedNextOperation.value = null;
    trayQuantity.value = 1;
    operations.clear();
  }

  // Cancel form
  void cancelForm() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel QR Assignment'),
        content: const Text(
          'Are you sure you want to cancel? All data will be lost.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('No')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              resetForm();
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
