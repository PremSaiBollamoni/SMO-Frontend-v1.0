import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/api/merging_api_service.dart';
import '../../domain/models/merging_model.dart';

class MergingController extends GetxController {
  final MergingApiService _apiService = MergingApiService();
  final formKey = GlobalKey<FormState>();

  // Form fields
  final tub1QrController = TextEditingController();
  final tub1DescriptionController = TextEditingController();
  final tub2QrController = TextEditingController();
  final tub2DescriptionController = TextEditingController();
  final notesController =
      TextEditingController(); // Added for enhanced workflow

  // Loading states
  var isSubmitting = false.obs;

  @override
  void onClose() {
    tub1QrController.dispose();
    tub1DescriptionController.dispose();
    tub2QrController.dispose();
    tub2DescriptionController.dispose();
    notesController.dispose();
    super.onClose();
  }

  // Set Tub 1 QR from scanner
  void setTub1Qr(String code) {
    if (code.trim().isNotEmpty) {
      tub1QrController.text = code.trim();
    }
  }

  // Set Tub 2 QR from scanner
  void setTub2Qr(String code) {
    if (code.trim().isNotEmpty) {
      tub2QrController.text = code.trim();
    }
  }

  // Validate form
  bool validateForm() {
    if (formKey.currentState?.validate() != true) {
      return false;
    }

    if (tub1QrController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please scan Tub 1 QR',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (tub1DescriptionController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter Tub 1 Description',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (tub2QrController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please scan Tub 2 QR',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (tub2DescriptionController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please enter Tub 2 Description',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    // Check if both tubs are the same
    if (tub1QrController.text.trim() == tub2QrController.text.trim()) {
      Get.snackbar(
        'Validation Error',
        'Cannot merge the same tub. Please scan different tubs.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  // Submit form
  Future<void> submitForm() async {
    if (!validateForm()) return;

    try {
      isSubmitting.value = true;

      final merging = MergingModel(
        tub1Qr: tub1QrController.text.trim(),
        tub1Description: tub1DescriptionController.text.trim(),
        tub2Qr: tub2QrController.text.trim(),
        tub2Description: tub2DescriptionController.text.trim(),
        supervisorId: 1004, // Default supervisor ID
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      print('[MERGING_SUBMIT] ═══ MERGING SUBMISSION START ═══');
      print('[MERGING_SUBMIT] Tub 1 QR: ${merging.tub1Qr}');
      print('[MERGING_SUBMIT] Tub 1 Description: ${merging.tub1Description}');
      print('[MERGING_SUBMIT] Tub 2 QR: ${merging.tub2Qr}');
      print('[MERGING_SUBMIT] Tub 2 Description: ${merging.tub2Description}');
      print('[MERGING_SUBMIT] Supervisor ID: ${merging.supervisorId}');
      print('[MERGING_SUBMIT] Notes: ${merging.notes}');

      final response = await _apiService.submitMerging(merging);

      print('[MERGING_SUBMIT] Response received: $response');

      if (response['success'] == true) {
        print('[MERGING_SUBMIT] ✓ MERGE SUCCESSFUL');
        print('[MERGING_SUBMIT] Consolidated Bin: ${response['consolidatedBinId']}');
        print('[MERGING_SUBMIT] Freed Bin: ${response['freedBinId']}');
        print('[MERGING_SUBMIT] Total Quantity: ${response['totalQuantity']}');
        print('[MERGING_SUBMIT] Qty Transferred: ${response['qtyTransferred']}');

        // Enhanced success message with details
        String message = 'Tubs Merged Successfully!';
        if (response['totalQuantity'] != null) {
          message += '\n\nTotal Quantity: ${response['totalQuantity']}';
        }
        if (response['qtyTransferred'] != null) {
          message += '\nQty Transferred: ${response['qtyTransferred']}';
        }
        if (response['freedBinId'] != null) {
          message += '\n\nSource bin freed for reuse';
        }
        
        // Show consolidation info
        if (response['consolidatedBinId'] != null) {
          message += '\nConsolidated Bin: ${response['consolidatedBinId']}';
        }

        print('[MERGING_SUBMIT] ═══ MERGING SUBMISSION END (SUCCESS) ═══');

        Get.snackbar(
          'Success',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        
        resetForm();
      } else {
        print('[MERGING_SUBMIT] ✗ MERGE FAILED: ${response['message']}');
        print('[MERGING_SUBMIT] Error Type: ${response['errorType']}');

        // Enhanced error handling based on error type
        String errorType = response['errorType'] ?? 'UNKNOWN_ERROR';
        String message = response['message'] ?? 'Merging failed';

        Color backgroundColor = Colors.red;

        // Different colors for different error types
        switch (errorType) {
          case 'VALIDATION_ERROR':
            backgroundColor = Colors.orange;
            break;
          case 'COMPATIBILITY_ERROR':
            backgroundColor = Colors.purple;
            message +=
                '\n\nTip: Only bins with same style/size/color can be merged';
            break;
          case 'STATUS_ERROR':
            backgroundColor = Colors.amber;
            message += '\n\nTip: Only ACTIVE bins can be merged';
            break;
          case 'BIN_NOT_FOUND':
            backgroundColor = Colors.red.shade700;
            break;
          case 'QUANTITY_ERROR':
            backgroundColor = Colors.orange.shade700;
            break;
        }

        print('[MERGING_SUBMIT] ═══ MERGING SUBMISSION END (ERROR) ═══');

        Get.snackbar(
          'Error',
          'Merge Failed\n\n$message',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: backgroundColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      print('[MERGING_SUBMIT] ✗ EXCEPTION: $e');
      print('[MERGING_SUBMIT] ═══ MERGING SUBMISSION END (ERROR) ═══');
      Get.snackbar(
        'Error',
        'Failed to merge tubs:\n$e',
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
    tub1QrController.clear();
    tub1DescriptionController.clear();
    tub2QrController.clear();
    tub2DescriptionController.clear();
    notesController.clear();
  }

  // Cancel form
  void cancelForm() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Merging'),
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
