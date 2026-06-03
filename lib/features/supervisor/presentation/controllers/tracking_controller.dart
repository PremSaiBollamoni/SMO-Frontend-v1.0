import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/api/tracking_api_service.dart';
import '../../domain/models/tracking_model.dart';
import '../../../../core/utils/api_error_helper.dart';
import '../../../../core/network/api_client.dart';

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

  // Temp QR resolution
  var resolvedEmployeeName = Rx<String?>(null);
  var resolvedEmployeeId = Rx<int?>(null);
  var employeeQrId = Rx<String?>(null); // Store the temp QR id for operation assignment later

  // Multi-employee support (NEW)
  var scannedEmployees = RxList<Map<String, dynamic>>([]); // List of {id, name}

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

  // Set Employee QR from scanner — resolves temp QR to employee
  void setEmployeeQr(String code) async {
    if (code.trim().isNotEmpty) {
      employeeQrController.text = code.trim();
      // Try to resolve as temp QR
      await _resolveTempQr(code.trim());
    }
  }

  // Resolve temp QR to employee via backend
  Future<void> _resolveTempQr(String qrId) async {
    try {
      final result = await _apiService.resolveTempQr(qrId);
      if (result != null && result['employeeId'] != null) {
        resolvedEmployeeName.value = result['employeeName'] as String?;
        resolvedEmployeeId.value = result['employeeId'] as int?;
        employeeQrId.value = qrId;
        print('[TRACKING] Resolved temp QR $qrId → Employee: ${result['employeeName']} (${result['employeeId']})');
      } else {
        // Not a temp QR or no active mapping — treat as regular employee QR
        resolvedEmployeeName.value = null;
        resolvedEmployeeId.value = null;
        employeeQrId.value = null;
      }
    } catch (e) {
      // Resolution failed — not a temp QR, that's fine
      resolvedEmployeeName.value = null;
      resolvedEmployeeId.value = null;
      employeeQrId.value = null;
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
      _showValidationError('Please fill in all required fields correctly');
      return false;
    }

    if (machineQrController.text.trim().isEmpty) {
      _showValidationError('Please scan Machine QR');
      return false;
    }

    // Check if at least one employee is added
    if (scannedEmployees.isEmpty) {
      _showValidationError('Please add at least one employee');
      return false;
    }

    if (trayQrController.text.trim().isEmpty) {
      _showValidationError('Please scan Tray QR');
      return false;
    }

    // Status validation - REMOVED: Auto-detected by backend
    // Backend determines START/COMPLETE based on whether active assignment exists

    return true;
  }

  void _showValidationError(String message) {
    try {
      Get.dialog(
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text('Validation Error'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      // Fallback to snackbar if dialog fails
      Get.snackbar('Error', message, snackPosition: SnackPosition.TOP, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _showResultDialog(bool success, String title, String message) {
    try {
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: SingleChildScrollView(child: Text(message)),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: success ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      // Fallback to snackbar if dialog fails
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: success ? Colors.green : Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // Format ISO timestamp into a readable HH:mm:ss
  String _formatTime(dynamic isoString) {
    try {
      final dt = DateTime.parse(isoString.toString()).toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
    } catch (_) {
      return isoString.toString();
    }
  }

  // Submit form with enhanced two-phase workflow (UPDATED for multi-employee)
  Future<void> submitForm() async {
    if (!validateForm()) return;

    try {
      isSubmitting.value = true;

      // Build list of employee IDs from scanned employees
      List<int> employeeIds = scannedEmployees.map((e) => e['id'] as int).toList();

      final tracking = TrackingModel(
        machineQr: machineQrController.text.trim(),
        employeeQr: '', // Keep for backward compat
        trayQr: trayQrController.text.trim(),
        status: 'PENDING', // Default value - backend auto-detects actual status
        supervisorId: 1004, // Default supervisor ID
        operationId: currentOperationId.value, // Include current operation ID
        employeeIds: employeeIds, // NEW: Pass multi-employee list
      );

      print('[TRACKING_SUBMIT] ═══ MULTI-EMPLOYEE TRACKING SUBMISSION START ═══');
      print('[TRACKING_SUBMIT] Machine QR: ${tracking.machineQr}');
      print('[TRACKING_SUBMIT] Employee IDs: $employeeIds (${scannedEmployees.length} employees)');
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
        String message = responseData['message'] ?? 'Tracking submitted successfully';
        String flowType = responseData['flowType'] ?? '';
        String title = 'Success';

        if (flowType == 'ASSIGNMENT') {
          title = 'Assignment Created';
          print('[TRACKING_SUBMIT] ✓ ASSIGNMENT FLOW - ${employeeIds.length} worker(s) assigned to machine & tray');
          if (responseData['startTime'] != null) {
            message += '\n\nTeam: ${scannedEmployees.map((e) => e['name']).join(', ')}\nStarted at: ${_formatTime(responseData['startTime'])}';
            message += '\n(Scan again to complete & see duration)';
          }
        } else if (flowType == 'COMPLETION') {
          title = 'Job Completed';
          print('[TRACKING_SUBMIT] ✓ COMPLETION FLOW - Job completed by ${employeeIds.length} worker(s)');

          // Show duration if available
          if (responseData['durationFormatted'] != null) {
            message += '\n\nDuration: ${responseData['durationFormatted']}';
            if (responseData['durationSeconds'] != null) {
              message += ' (${responseData['durationSeconds']}s)';
            }
          }
          if (responseData['startTime'] != null && responseData['endTime'] != null) {
            message += '\nStart: ${_formatTime(responseData['startTime'])}';
            message += '\nEnd: ${_formatTime(responseData['endTime'])}';
          }

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

        _showResultDialog(true, title, message);
        resetForm();
      } else {
        print('[TRACKING_SUBMIT] ✗ SUBMISSION FAILED: ${result['message']}');
        throw Exception(result['message'] ?? 'Submission failed');
      }
    } catch (e) {
      print('[TRACKING_SUBMIT] ✗ EXCEPTION: $e');
      print('[TRACKING_SUBMIT] ═══ TRACKING SUBMISSION END (ERROR) ═══');
      _showResultDialog(false, 'Tracking Failed', ApiErrorHelper.getMessage(e));
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
    resolvedEmployeeName.value = null;
    resolvedEmployeeId.value = null;
    employeeQrId.value = null;
    scannedEmployees.clear();  // Clear multi-employee list
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

  // ═════════════════════════════════════════════════════════════════════════════
  // MULTI-EMPLOYEE SUPPORT (NEW)
  // ═════════════════════════════════════════════════════════════════════════════

  /// Add employee from employee QR field (manual entry or pre-scanned)
  Future<void> addScannedEmployee() async {
    final qr = employeeQrController.text.trim();
    if (qr.isEmpty) {
      Get.snackbar('Error', 'Please enter employee QR', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      // Resolve employee ID (could be temp QR like EMP-TEMP-004 or regular ID)
      int? empId = await _parseAndResolveEmployeeQr(qr);
      if (empId == null) {
        Get.snackbar('Error', 'Invalid employee QR: $qr', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      // Check if already scanned
      if (scannedEmployees.any((e) => e['id'] == empId)) {
        Get.snackbar('Warning', 'Employee already added', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      // Fetch employee name
      String? empName = await _fetchEmployeeName(empId);

      scannedEmployees.add({
        'id': empId,
        'name': empName ?? 'Employee $empId',
        'qr': qr,
      });

      print('[TRACKING] Employee added: $empId (${empName ?? 'Employee $empId'})');
      employeeQrController.clear();
      Get.snackbar('✓ Added', 'Employee $empId added to team', snackPosition: SnackPosition.BOTTOM, duration: const Duration(milliseconds: 800));
    } catch (e) {
      print('[TRACKING] Error adding employee: $e');
      Get.snackbar('Error', 'Failed to add employee: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Add employee from QR scanner (triggered by Scan button)
  void addScannedEmployeeFromQr(String qr) async {
    employeeQrController.text = qr.trim();
    await addScannedEmployee();
  }

  /// Remove employee from scanned list
  void removeEmployee(int index) {
    if (index >= 0 && index < scannedEmployees.length) {
      scannedEmployees.removeAt(index);
      Get.snackbar('Removed', 'Employee removed from team', snackPosition: SnackPosition.BOTTOM, duration: const Duration(milliseconds: 800));
    }
  }

  /// Parse employee QR and resolve to employee ID
  /// Supports: plain numeric, EMP_xxxx, EMP-xxxx, EMP-TEMP-xxx (temp QR)
  Future<int?> _parseAndResolveEmployeeQr(String qr) async {
    print('[TRACKING] Parsing employee QR: $qr');
    
    // Try plain numeric
    try {
      int id = int.parse(qr);
      print('[TRACKING] Parsed as numeric ID: $id');
      return id;
    } catch (_) {}

    // Try EMP_xxxx or EMP-xxxx format
    if (qr.toUpperCase().startsWith('EMP_') || qr.toUpperCase().startsWith('EMP-')) {
      String suffix = qr.substring(4);
      try {
        int id = int.parse(suffix);
        print('[TRACKING] Parsed as EMP-formatted ID: $id');
        return id;
      } catch (_) {}
    }

    // Try temp QR resolution (EMP-TEMP-xxx format)
    if (qr.toUpperCase().contains('TEMP')) {
      try {
        print('[TRACKING] Attempting to resolve temp QR: $qr');
        final result = await _apiService.resolveTempQr(qr);
        if (result != null && result['employeeId'] != null) {
          int empId = result['employeeId'] as int;
          print('[TRACKING] Resolved temp QR to employee ID: $empId');
          return empId;
        } else {
          print('[TRACKING] Temp QR resolution returned null or no employeeId');
          // Fallback: extract numeric part from temp QR (e.g., EMP-TEMP-001 → 1001)
          try {
            String numPart = qr.replaceAll(RegExp(r'[^\d]'), '');
            if (numPart.isNotEmpty) {
              int fallbackId = int.parse('10' + numPart); // Convert 001 → 10001
              print('[TRACKING] Using fallback ID from temp QR: $fallbackId');
              return fallbackId;
            }
          } catch (e) {
            print('[TRACKING] Fallback parsing failed: $e');
          }
        }
      } catch (e) {
        print('[TRACKING] Temp QR resolution exception: $e');
        // Still try fallback on exception
        try {
          String numPart = qr.replaceAll(RegExp(r'[^\d]'), '');
          if (numPart.isNotEmpty) {
            int fallbackId = int.parse('10' + numPart);
            print('[TRACKING] Using fallback ID after exception: $fallbackId');
            return fallbackId;
          }
        } catch (e2) {
          print('[TRACKING] Fallback failed: $e2');
        }
      }
    }

    print('[TRACKING] Failed to parse employee QR: $qr');
    return null;
  }

  /// Fetch employee name from backend
  Future<String?> _fetchEmployeeName(int empId) async {
    try {
      // Fetch employee details from HR API
      final response = await ApiClient().dio.get('/api/hr/employees/$empId');
      if (response.statusCode == 200 && response.data != null) {
        return response.data['name'] as String?;
      }
    } catch (e) {
      print('[TRACKING] Error fetching employee name for ID $empId: $e');
    }
    return null; // Return null if fetch fails, will use "Employee {id}" as fallback
  }
}
