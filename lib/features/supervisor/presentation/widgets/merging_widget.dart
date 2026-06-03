import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/merging_controller.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget version of Merging
/// Used in operation details dialog when clicking a process plan node
class MergingWidget extends StatelessWidget {
  final int? operationId;
  final String? operationName;

  const MergingWidget({
    super.key,
    this.operationId,
    this.operationName,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MergingController());

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
                icon: Icons.merge_type_outlined,
                color: AppTheme.primary,
                label: 'Merge Operation',
                value: operationName!,
              ),
              const SizedBox(height: 20),
            ],

            // Tub 1 Section
            _buildTubSection(
              context,
              title: 'Source Tub 1',
              color: AppTheme.primary,
              icon: Icons.inbox_outlined,
              qrCtrl: controller.tub1QrController,
              descCtrl: controller.tub1DescriptionController,
              onScan: () => _showQrScanner(context, 'Scan Tub 1 QR', controller.setTub1Qr),
            ),
            const SizedBox(height: 16),

            // Merge arrow indicator
            Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.merge, color: AppTheme.secondary, size: 24),
              ),
            ),
            const SizedBox(height: 16),

            // Tub 2 Section
            _buildTubSection(
              context,
              title: 'Source Tub 2',
              color: AppTheme.tertiary,
              icon: Icons.inbox_outlined,
              qrCtrl: controller.tub2QrController,
              descCtrl: controller.tub2DescriptionController,
              onScan: () => _showQrScanner(context, 'Scan Tub 2 QR', controller.setTub2Qr),
            ),
            const SizedBox(height: 20),

            // Notes
            Text('Notes (Optional)', style: AppTheme.titleSmall.copyWith(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.notesController,
              maxLines: 3,
              decoration: AppTheme.inputDecoration('Additional notes about this merge...'),
            ),
            const SizedBox(height: 24),

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
                          : const Text('Merge Tubs'),
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

  Widget _buildTubSection(
    BuildContext context, {
    required String title,
    required Color color,
    required IconData icon,
    required TextEditingController qrCtrl,
    required TextEditingController descCtrl,
    required VoidCallback onScan,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: AppTheme.titleMedium.copyWith(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          // QR Field
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: qrCtrl,
                  decoration: AppTheme.inputDecoration('QR Code *').copyWith(hintText: 'Scan or enter QR'),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          TextFormField(
            controller: descCtrl,
            decoration: AppTheme.inputDecoration('Description *'),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
          ),
        ],
      ),
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
