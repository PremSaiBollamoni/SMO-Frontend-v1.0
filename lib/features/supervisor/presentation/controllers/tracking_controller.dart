import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/api/tracking_api_service.dart';
import '../../domain/models/tracking_model.dart';

class TrackingController extends GetxController {
  final TrackingApiService _apiService = TrackingApiService();
  final formKey = GlobalKey<FormState>();

  // Form fields
  final machineQrController = TextEditingController();
  final employeeQrController = TextEditingController();
  final trayQrController = TextEditingController();

  // Status dropdown
  var selectedStatus = Rx<String?>(null);
  final List<String> statusOptions = ['Completed', 'Pending'];

  // Loading states
  var isSubmitting = false.obs;
  var isLoadingBinInfo = false.obs;

  // Flow type tracking
  var lastFlowType = ''.obs;
  var lastResponse = Rx<Map<String, dynamic>?>(null);

  // Current operation tracking
  var currentOperationId = Rx<int?>(null);
  var currentOperationName = Rx<String?>(null);
  var binInfo = Rx<Map<String, dynamic>?>(null);

  @override
  void onClose() {
    machineQrController.dispose();
    employeeQrController.dispose();
    trayQrController.dispose();
    super.onClose();
  }

  // Set Machine QR from scanner
  void setMachineQr(String code) {
    if (code.trim().isNotEmpty) {
      machineQrController.text = code.trim();
    }
  }

  // Set Employee QR from scanner
  void setEmployeeQr(String code) {
    if (code.trim().isNotEmpty) {
      employeeQrController.text = code.trim();
    }
  }

  // Set Tray QR from scanner and fetch bin info
  void setTrayQr(String code) async {
    if (code.trim().isNotEmpty) {
      trayQrController.text = code.trim();
      // Auto-fetch bin current operation
      await fetchBinCurrentOperation(code.trim());
    }
  }

  // Fetch bin current operation from backend
  Future<void> fetchBinCurrentOperation(String trayQr) async {
    try {
      isLoadingBinInfo.value = true;
      currentOperationId.value = null;
      currentOperationName.value = null;
      binInfo.value = null;

      final result = await _apiService.getBinCurrentOperation(trayQr);

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        binInfo.value = data;

        if (data['currentOperationId'] != null) {
          currentOperationId.value = data['currentOperationId'] as int;
          currentOperationName.value = data['currentOperationName'] as String?;
        }
      } else {
        // Bin not found or no current operation - this is OK for new assignments
        print('[TRACKING] Bin info: ${result['message']}');
      }
    } catch (e) {
      print('[TRACKING] Error fetching bin info: $e');
    } finally {
      isLoadingBinInfo.value = false;
    }
  }

  // Validate form
  bool validateForm() {
    if (formKey.currentState?.validate() != true) {
      return false;
    }

    if (machineQrController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please scan Machine QR',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (employeeQrController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please scan Employee QR',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (trayQrController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please scan Tray QR',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (selectedStatus.value == null || selectedStatus.value!.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please select a status',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  // Submit form with enhanced two-phase workflow
  Future<void> submitForm() async {
    if (!validateForm()) return;

    try {
      isSubmitting.value = true;

      final tracking = TrackingModel(
        machineQr: machineQrController.text.trim(),
        employeeQr: employeeQrController.text.trim(),
        trayQr: trayQrController.text.trim(),
        status: selectedStatus.value!,
        supervisorId: 1004, // Default supervisor ID
        operationId: currentOperationId.value, // Include current operation ID
      );

      print('[TRACKING_SUBMIT] ═══ TRACKING SUBMISSION START ═══');
      print('[TRACKING_SUBMIT] Machine QR: ${tracking.machineQr}');
      print('[TRACKING_SUBMIT] Employee QR: ${tracking.employeeQr}');
      print('[TRACKING_SUBMIT] Tray QR: ${tracking.trayQr}');
      print('[TRACKING_SUBMIT] Status: ${tracking.status}');
      print('[TRACKING_SUBMIT] Operation ID: ${tracking.operationId}');
      print('[TRACKING_SUBMIT] Supervisor ID: ${tracking.supervisorId}');

      final result = await _apiService.submitTracking(tracking);

      print('[TRACKING_SUBMIT] Response received: $result');

      if (result['success'] == true) {
        final responseData = result['data'] as Map<String, dynamic>;
        lastResponse.value = responseData;
        lastFlowType.value = responseData['flowType'] ?? '';

        print('[TRACKING_SUBMIT] Flow Type: ${responseData['flowType']}');
        print('[TRACKING_SUBMIT] Message: ${responseData['message']}');
        print('[TRACKING_SUBMIT] Current Operation: ${responseData['currentOperationId']}');
        print('[TRACKING_SUBMIT] Next Operation: ${responseData['nextOperationId']}');
        print('[TRACKING_SUBMIT] Workflow Complete: ${responseData['workflowComplete']}');

        // Show success message with flow type information
        String message =
            responseData['message'] ?? 'Tracking submitted successfully';
        String flowType = responseData['flowType'] ?? '';

        Color backgroundColor = Colors.green;
        String title = 'Success';

        if (flowType == 'ASSIGNMENT') {
          backgroundColor = Colors.blue;
          title = 'Assignment Created';
          print('[TRACKING_SUBMIT] ✓ ASSIGNMENT FLOW - Worker assigned to machine & tray');
        } else if (flowType == 'COMPLETION') {
          backgroundColor = Colors.green;
          title = 'Job Completed';
          print('[TRACKING_SUBMIT] ✓ COMPLETION FLOW - Job completed');
          
          // Check if workflow is complete
          if (responseData['workflowComplete'] == true) {
            title = 'Workflow Complete!';
            message = 'All operations finished!\n\n$message';
            print('[TRACKING_SUBMIT] ✓ WORKFLOW COMPLETE - All operations done');
          } else if (responseData['nextOperationId'] != null) {
            // Tray moved to next operation
            String nextOpName = responseData['nextOperationName'] ?? 'Next Operation';
            message += '\n\nTray moved to: $nextOpName';
            print('[TRACKING_SUBMIT] ✓ TRAY ADVANCED - Next operation: ${responseData['nextOperationId']}');
          }
        }

        print('[TRACKING_SUBMIT] ═══ TRACKING SUBMISSION END (SUCCESS) ═══');

        // Show snackbar message
        Get.snackbar(
          title,
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: backgroundColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );

        resetForm();
      } else {
        print('[TRACKING_SUBMIT] ✗ SUBMISSION FAILED: ${result['message']}');
        throw Exception(result['message'] ?? 'Submission failed');
      }
    } catch (e) {
      print('[TRACKING_SUBMIT] ✗ EXCEPTION: $e');
      print('[TRACKING_SUBMIT] ═══ TRACKING SUBMISSION END (ERROR) ═══');
      Get.snackbar(
        'Error',
        'Failed to submit tracking:\n$e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  // Reset form
  void resetForm() {
    formKey.currentState?.reset();
    machineQrController.clear();
    employeeQrController.clear();
    trayQrController.clear();
    selectedStatus.value = null;
    currentOperationId.value = null;
    currentOperationName.value = null;
    binInfo.value = null;
  }

  // Cancel form
  void cancelForm() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Tracking'),
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
