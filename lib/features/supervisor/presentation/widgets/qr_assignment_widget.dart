import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/qr_assignment_controller.dart';
import '../widgets/tray_quantity_stepper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';

/// Widget version of QR Assignment (extracted from QrAssignmentScreen)
/// Used in operation details dialog when clicking a process plan node
class QrAssignmentWidget extends StatefulWidget {
  final int? operationId;
  final String? operationName;
  final int? routingId;

  const QrAssignmentWidget({
    super.key,
    this.operationId,
    this.operationName,
    this.routingId,
  });

  @override
  State<QrAssignmentWidget> createState() => _QrAssignmentWidgetState();
}

class _QrAssignmentWidgetState extends State<QrAssignmentWidget> {
  String? _nextOperationName;
  int? _nextOperationId;
  bool _loadingNextOp = true;

  @override
  void initState() {
    super.initState();
    _fetchNextOperation();
  }

  Future<void> _fetchNextOperation() async {
    if (widget.routingId == null || widget.operationId == null) {
      setState(() => _loadingNextOp = false);
      return;
    }

    try {
      final response = await ApiClient().dio.get(
        '/api/processplan/${widget.routingId}',
        queryParameters: {'actorEmpId': '1004'},
      );

      if (response.statusCode == 200 && response.data != null) {
        final edges = response.data['edges'] as List<dynamic>?;
        if (edges != null) {
          for (var edge in edges) {
            if (edge['from_operation_id'] == widget.operationId) {
              setState(() {
                _nextOperationName = edge['to_name'];
                _nextOperationId = edge['to_operation_id'];
              });
              break;
            }
          }
        }
      }
    } catch (e) {
      print('[QR_ASSIGNMENT] Error fetching next operation: $e');
    } finally {
      setState(() => _loadingNextOp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _QrAssignmentWidgetContent(
      operationId: widget.operationId,
      operationName: widget.operationName,
      nextOperationName: _nextOperationName,
      nextOperationId: _nextOperationId,
      loadingNextOp: _loadingNextOp,
    );
  }
}

class _QrAssignmentWidgetContent extends StatelessWidget {
  final int? operationId;
  final String? operationName;
  final String? nextOperationName;
  final int? nextOperationId;
  final bool loadingNextOp;

  const _QrAssignmentWidgetContent({
    required this.operationId,
    required this.operationName,
    required this.nextOperationName,
    required this.nextOperationId,
    required this.loadingNextOp,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(QrAssignmentController());

    return Obx(() {
      if (controller.isLoading.value || loadingNextOp) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Operation Info Cards
              if (operationName != null || nextOperationName != null)
                _buildOperationInfoSection(),

              // Form Fields
              _buildSectionHeader('Assignment Details'),
              const SizedBox(height: 12),

              // Process Plan Number
              _buildDropdownField(
                label: 'Process Plan Number',
                value: controller.selectedProcessPlan.value,
                items: controller.processPlanNumbers,
                onChanged: (value) {
                  controller.selectedProcessPlan.value = value;
                  if (value != null) {
                    controller.loadOperations(value);
                  }
                },
                isRequired: true,
              ),
              const SizedBox(height: 14),

              // Order Number (Optional)
              Obx(() {
                if (controller.activeOrders.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: controller.selectedOrderNumber.value,
                      decoration: AppTheme.inputDecoration('Order Number (Optional)').copyWith(
                        prefixIcon: const Icon(Icons.assignment_outlined, size: 20),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No Order (Unassigned)', overflow: TextOverflow.ellipsis),
                        ),
                        ...controller.activeOrders.map((order) {
                          return DropdownMenuItem<String>(
                            value: order['order_number'] ?? order['order_id']?.toString(),
                            child: Text(
                              '${order['order_number'] ?? order['order_id']} - Product #${order['product_id']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) => controller.selectedOrderNumber.value = value,
                    ),
                    const SizedBox(height: 14),
                  ],
                );
              }),

              // QR Code Field with Scan Button
              _buildQrCodeField(context, controller),
              const SizedBox(height: 14),

              // Style & Size
              _buildDropdownField(
                label: 'Style',
                value: controller.selectedStyle.value,
                items: controller.styles,
                onChanged: (value) => controller.selectedStyle.value = value,
              ),
              const SizedBox(height: 14),

              _buildDropdownField(
                label: 'Size',
                value: controller.selectedSize.value,
                items: controller.sizes,
                onChanged: (value) => controller.selectedSize.value = value,
              ),
              const SizedBox(height: 14),

              // GTG & BTN
              _buildDropdownField(
                label: 'GTG Number',
                value: controller.selectedGtg.value,
                items: controller.gtgNumbers,
                onChanged: (value) => controller.selectedGtg.value = value,
              ),
              const SizedBox(height: 14),

              _buildDropdownField(
                label: 'Button Number (BTN)',
                value: controller.selectedBtn.value,
                items: controller.btnNumbers,
                onChanged: (value) => controller.selectedBtn.value = value,
              ),
              const SizedBox(height: 14),

              // Label
              _buildDropdownField(
                label: 'Label',
                value: controller.selectedLabel.value,
                items: controller.labels,
                onChanged: (value) => controller.selectedLabel.value = value,
              ),
              const SizedBox(height: 20),

              // Tray Quantity
              _buildSectionHeader('Tray Quantity'),
              const SizedBox(height: 8),
              TrayQuantityStepper(
                value: controller.trayQuantity.value,
                onIncrement: controller.incrementTrayQuantity,
                onDecrement: controller.decrementTrayQuantity,
                onValueChanged: controller.setTrayQuantity,
              ),
              const SizedBox(height: 20),

              // Notes
              _buildSectionHeader('Notes (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.notesController,
                maxLines: 3,
                decoration: AppTheme.inputDecoration('Additional notes...'),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
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
                      onPressed: controller.isSubmitting.value
                          ? null
                          : () => controller.submitForm(
                                nextOperationName: nextOperationName,
                                nextOperationId: nextOperationId,
                                operationId: operationId,
                              ),
                      style: AppTheme.primaryButtonStyle.copyWith(
                        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 14)),
                      ),
                      child: controller.isSubmitting.value
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Assign QR'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildOperationInfoSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (operationName != null)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings_outlined, color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Operation', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
                      Text(operationName!, style: AppTheme.titleMedium.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          if (operationName != null && nextOperationName != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 17),
                  Container(width: 2, height: 20, color: AppTheme.surfaceVariant),
                ],
              ),
            ),
          if (nextOperationName != null)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward, color: AppTheme.success, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Next Operation', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
                      Text(nextOperationName!, style: AppTheme.titleMedium.copyWith(color: AppTheme.success, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppTheme.titleSmall.copyWith(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600));
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: AppTheme.inputDecoration(isRequired ? '$label *' : label),
      isExpanded: true,
      hint: Text('Select $label', style: AppTheme.bodyMedium.copyWith(color: AppTheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
      items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
      validator: isRequired
          ? (value) => (value == null || value.isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _buildQrCodeField(BuildContext context, QrAssignmentController controller) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: controller.qrCodeController,
            decoration: AppTheme.inputDecoration('QR Code *').copyWith(
              hintText: 'Scan or enter QR Code',
            ),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            onChanged: (value) {
              if (value.trim().isNotEmpty) {
                controller.qrCodeController.text = value.trim();
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _showQrScanner(context, controller),
            icon: const Icon(Icons.qr_code_scanner, size: 20),
            label: const Text('Scan'),
            style: AppTheme.primaryButtonStyle.copyWith(
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 14, vertical: 0)),
            ),
          ),
        ),
      ],
    );
  }

  void _showQrScanner(BuildContext context, QrAssignmentController controller) {
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
                  Text('Scan QR Code', style: AppTheme.titleLarge),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final String? code = barcodes.first.rawValue;
                        if (code != null && code.trim().isNotEmpty) {
                          controller.setQrCode(code.trim());
                          Navigator.pop(context);
                          Get.snackbar(
                            'Success',
                            'QR Code scanned',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppTheme.success,
                            colorText: Colors.white,
                          );
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
