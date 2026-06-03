import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/tracking_controller.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget version of Tracking
/// Used in operation details dialog when clicking a process plan node
/// Now supports multi-employee team tracking
class TrackingWidget extends StatelessWidget {
  final int? operationId;
  final String? operationName;

  const TrackingWidget({
    super.key,
    this.operationId,
    this.operationName,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TrackingController());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Operation Info
            if (operationName != null) ...[
              _buildInfoCard(
                icon: Icons.settings_outlined,
                color: AppTheme.primary,
                label: 'Operation',
                value: operationName!,
              ),
              const SizedBox(height: 16),
            ],

            // Flow Status Display
            Obx(
              () => controller.lastResponse.value != null
                  ? _buildFlowStatus(controller)
                  : const SizedBox.shrink(),
            ),

            // QR Fields Section
            Text('Scan QR Codes', style: AppTheme.titleSmall.copyWith(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            _buildQrField(context, label: 'Machine QR', ctrl: controller.machineQrController, onScan: () => _showQrScanner(context, 'Scan Machine QR', controller.setMachineQr)),
            const SizedBox(height: 14),

            // Multi-Employee Support (NEW)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Employees', style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    Obx(
                      () => Badge(
                        label: Text(controller.scannedEmployees.length.toString()),
                        backgroundColor: AppTheme.primary,
                        child: const Icon(Icons.people, size: 20, color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Employee list
                Obx(
                  () => controller.scannedEmployees.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...List.generate(controller.scannedEmployees.length, (index) {
                                final emp = controller.scannedEmployees[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: AppTheme.success.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Center(
                                          child: Text('${index + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.success)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(emp['name'] ?? 'Employee', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                            Text('ID: ${emp['id']}', style: TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, size: 14),
                                          onPressed: () => controller.removeEmployee(index),
                                          padding: EdgeInsets.zero,
                                          style: IconButton.styleFrom(
                                            backgroundColor: AppTheme.error.withValues(alpha: 0.1),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 10),
                // Scan + Add Employee button
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller.employeeQrController,
                        decoration: AppTheme.inputDecoration('Employee QR *').copyWith(hintText: 'Scan or enter employee QR'),
                        validator: (value) {
                          if (controller.scannedEmployees.isEmpty && (value == null || value.trim().isEmpty)) {
                            return 'At least one employee required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: controller.addScannedEmployee,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                        style: AppTheme.primaryButtonStyle.copyWith(
                          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _showQrScanner(context, 'Scan Employee QR', controller.addScannedEmployeeFromQr),
                        icon: const Icon(Icons.qr_code_scanner, size: 20),
                        label: const Text('Scan'),
                        style: AppTheme.primaryButtonStyle.copyWith(
                          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Show resolved employees from temp QR
            Obx(
              () => controller.scannedEmployees.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 18, color: AppTheme.success),
                          const SizedBox(width: 8),
                          Text('${controller.scannedEmployees.length} employee(s) ready', style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),

            _buildQrField(context, label: 'Tray QR', ctrl: controller.trayQrController, onScan: () => _showQrScanner(context, 'Scan Tray QR', controller.setTrayQr)),
            const SizedBox(height: 8),

            // Current Operation Display (from bin lookup)
            Obx(
              () => controller.isLoadingBinInfo.value
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 8),
                          Text('Loading bin info...', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : controller.currentOperationName.value != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _buildInfoCard(
                            icon: Icons.info_outline,
                            color: AppTheme.info,
                            label: 'Current Operation',
                            value: controller.currentOperationName.value!,
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Status Dropdown - REMOVED: Auto-detect from scan count
            // Backend automatically determines:
            // - 1st scan (no active assignment) = START (PENDING)
            // - 2nd scan (active assignment exists) = COMPLETE (COMPLETED)

            // Action Buttons
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.isSubmitting.value ? null : controller.cancelForm,
                      style: AppTheme.outlinedButtonStyle.copyWith(
                        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 14)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: controller.isSubmitting.value ? null : controller.submitForm,
                      style: AppTheme.primaryButtonStyle.copyWith(
                        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 14)),
                      ),
                      child: controller.isSubmitting.value
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required Color color, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
                Text(value, style: AppTheme.titleMedium.copyWith(color: color, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowStatus(TrackingController controller) {
    final isAssignment = controller.lastFlowType.value == 'ASSIGNMENT';
    final color = isAssignment ? AppTheme.info : AppTheme.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(isAssignment ? Icons.assignment : Icons.check_circle, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Last: ${controller.lastFlowType.value}', style: AppTheme.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                Text(controller.lastResponse.value!['message'] ?? '', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrField(BuildContext context, {required String label, required TextEditingController ctrl, required VoidCallback onScan}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: ctrl,
            decoration: AppTheme.inputDecoration('$label *').copyWith(hintText: 'Scan or enter $label'),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.qr_code_scanner, size: 20),
            label: const Text('Scan'),
            style: AppTheme.primaryButtonStyle.copyWith(
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 14)),
            ),
          ),
        ),
      ],
    );
  }

  void _showQrScanner(BuildContext context, String title, Function(String) onCodeScanned) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: AppTheme.titleLarge),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MobileScanner(
                    onDetect: (capture) {
                      final barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final code = barcodes.first.rawValue;
                        if (code != null && code.trim().isNotEmpty) {
                          onCodeScanned(code.trim());
                          Navigator.pop(context);
                          Get.snackbar('Success', 'QR Code scanned', snackPosition: SnackPosition.BOTTOM, backgroundColor: AppTheme.success, colorText: Colors.white);
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
