import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dio/dio.dart';
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
              // Operation Info (if provided)
              if (operationName != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    border: Border.all(color: AppTheme.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Operation:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              operationName!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (operationName != null) const SizedBox(height: 16),

              // Next Operation Info (Auto-determined from edges)
              if (nextOperationName != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_forward, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Next Operation (Auto-detected):',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              nextOperationName!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (nextOperationName != null) const SizedBox(height: 16),

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
              const SizedBox(height: 16),

              // Order Number (Optional)
              Obx(() {
                if (controller.activeOrders.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: controller.selectedOrderNumber.value,
                      decoration: const InputDecoration(
                        labelText: 'Order Number (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.assignment),
                        hintText: 'Select order to link bin',
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No Order (Unassigned)',
                              overflow: TextOverflow.ellipsis),
                        ),
                        ...controller.activeOrders.map((order) {
                          return DropdownMenuItem<String>(
                            value: order['order_number'] ??
                                order['order_id']?.toString(),
                            child: Text(
                              '${order['order_number'] ?? order['order_id']} - Product #${order['product_id']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        controller.selectedOrderNumber.value = value;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),

              // QR Code Field with Scan Button
              _buildQrCodeField(context, controller),
              const SizedBox(height: 16),

              // Style
              _buildDropdownField(
                label: 'Style',
                value: controller.selectedStyle.value,
                items: controller.styles,
                onChanged: (value) => controller.selectedStyle.value = value,
              ),
              const SizedBox(height: 16),

              // Size
              _buildDropdownField(
                label: 'Size',
                value: controller.selectedSize.value,
                items: controller.sizes,
                onChanged: (value) => controller.selectedSize.value = value,
              ),
              const SizedBox(height: 16),

              // GTG Number
              _buildDropdownField(
                label: 'GTG Number',
                value: controller.selectedGtg.value,
                items: controller.gtgNumbers,
                onChanged: (value) => controller.selectedGtg.value = value,
              ),
              const SizedBox(height: 16),

              // Button Number (BTN)
              _buildDropdownField(
                label: 'Button Number (BTN)',
                value: controller.selectedBtn.value,
                items: controller.btnNumbers,
                onChanged: (value) => controller.selectedBtn.value = value,
              ),
              const SizedBox(height: 16),

              // Label
              _buildDropdownField(
                label: 'Label',
                value: controller.selectedLabel.value,
                items: controller.labels,
                onChanged: (value) => controller.selectedLabel.value = value,
              ),
              const SizedBox(height: 16),

              // Next Operation (Display only - auto-determined from edges)
              // NO DROPDOWN - just show the next operation
              const SizedBox(height: 0),

              // Tray Quantity
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tray Quantity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TrayQuantityStepper(
                    value: controller.trayQuantity.value,
                    onIncrement: controller.incrementTrayQuantity,
                    onDecrement: controller.decrementTrayQuantity,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Optional Notes Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note_add, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Additional Notes (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText:
                            'Enter any additional notes about this assignment...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : controller.cancelForm,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : () => controller.submitForm(
                              nextOperationName: nextOperationName,
                              nextOperationId: nextOperationId,
                              operationId: operationId,
                            ),
                    style: AppTheme.primaryButtonStyle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: controller.isSubmitting.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: Text('Select $label'),
          items: items.map((item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select $label';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildQrCodeField(
    BuildContext context,
    QrAssignmentController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'QR Code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.qrCodeController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Scan or enter QR Code manually',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please scan or enter a QR code';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value.trim().isNotEmpty) {
                    controller.qrCodeController.text = value.trim();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showQrScanner(context, controller),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showQrScanner(BuildContext context, QrAssignmentController controller) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scan QR Code',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
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
                          'QR Code scanned successfully',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
