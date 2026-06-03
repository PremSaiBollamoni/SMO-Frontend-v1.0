import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smo_flutter/features/gm/presentation/controllers/machine_controller.dart';
import 'package:smo_flutter/features/gm/data/models/machine_model.dart';
import 'package:smo_flutter/core/theme/app_theme.dart';

class MachineManagementScreen extends StatelessWidget {
  final String empId;

  const MachineManagementScreen({super.key, required this.empId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MachineController());
    controller.setContext(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Machine Management'),
        actions: [
          IconButton(
            onPressed: controller.fetchMachines,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.machines.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.machines.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.precision_manufacturing_outlined,
                    size: 64, color: AppTheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text('No machines found', style: AppTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Tap + to create a new machine',
                    style: AppTheme.bodyMedium
                        .copyWith(color: AppTheme.onSurfaceVariant)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchMachines,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.machines.length,
            itemBuilder: (context, index) {
              final machine = controller.machines[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: machine.status == 'ACTIVE'
                        ? AppTheme.success.withOpacity(0.2)
                        : AppTheme.error.withOpacity(0.2),
                    child: Icon(
                      Icons.precision_manufacturing_outlined,
                      color: machine.status == 'ACTIVE'
                          ? AppTheme.success
                          : AppTheme.error,
                    ),
                  ),
                  title: Text(machine.machineName, style: AppTheme.titleMedium),
                  subtitle: Text(
                    '${machine.machineType} • ${machine.status}',
                    style: AppTheme.bodySmall
                        .copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showMachineDialog(
                          context,
                          controller,
                          machine: machine,
                        ),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: AppTheme.error,
                        onPressed: () => _confirmDelete(context, controller, machine),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMachineDialog(context, controller),
        icon: const Icon(Icons.add),
        label: const Text('Add Machine'),
      ),
    );
  }

  void _showMachineDialog(
    BuildContext context,
    MachineController controller, {
    MachineModel? machine,
  }) {
    final isEdit = machine != null;
    if (isEdit) {
      controller.loadMachineForEdit(machine);
    } else {
      controller.clearForm();
    }

    showDialog(
      context: context,
      builder: (ctx) => _MachineDialog(
        controller: controller,
        isEdit: isEdit,
        machine: machine,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    MachineController controller,
    MachineModel machine,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Machine'),
        content: Text(
          'Are you sure you want to delete "${machine.machineName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteMachine(machine.machineId!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Machine create/edit dialog with QR scan for machine ID
class _MachineDialog extends StatefulWidget {
  final MachineController controller;
  final bool isEdit;
  final MachineModel? machine;

  const _MachineDialog({
    required this.controller,
    required this.isEdit,
    this.machine,
  });

  @override
  State<_MachineDialog> createState() => _MachineDialogState();
}

class _MachineDialogState extends State<_MachineDialog> {
  String? _scannedQrId;

  void _showQrScanner() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Scan Machine QR', style: AppTheme.titleLarge),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
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
                      final barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final code = barcodes.first.rawValue;
                        if (code != null && code.trim().isNotEmpty) {
                          Navigator.pop(ctx);
                          setState(() => _scannedQrId = code.trim());
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

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.isEdit ? 'Edit Machine' : 'Add Machine', style: AppTheme.titleLarge),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Scan (only for create)
            if (!widget.isEdit) ...[
              Text('Machine QR *', style: AppTheme.titleSmall.copyWith(color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: _scannedQrId != null
                            ? AppTheme.success.withValues(alpha: 0.08)
                            : AppTheme.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _scannedQrId != null ? AppTheme.success : AppTheme.surfaceVariant,
                          width: _scannedQrId != null ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _scannedQrId != null ? Icons.check_circle : Icons.qr_code_2_outlined,
                            color: _scannedQrId != null ? AppTheme.success : AppTheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _scannedQrId ?? 'Scan machine QR code',
                              style: AppTheme.bodyMedium.copyWith(
                                color: _scannedQrId != null ? AppTheme.success : AppTheme.onSurfaceVariant,
                                fontWeight: _scannedQrId != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _showQrScanner,
                      icon: const Icon(Icons.qr_code_scanner, size: 20),
                      label: const Text('Scan'),
                      style: AppTheme.primaryButtonStyle.copyWith(
                        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // Machine Name
            TextField(
              controller: c.machineNameController,
              decoration: AppTheme.inputDecoration('Machine Name *').copyWith(
                hintText: 'e.g., Juki DDL-8700',
              ),
            ),
            const SizedBox(height: 14),
            // Machine Type (free text)
            TextField(
              controller: c.machineTypeController,
              decoration: AppTheme.inputDecoration('Machine Type *').copyWith(
                hintText: 'e.g., Single Needle, Overlock, Kansai...',
              ),
            ),
            const SizedBox(height: 14),
            // Status
            Obx(() => DropdownButtonFormField<String>(
              value: c.selectedStatus.value,
              decoration: AppTheme.inputDecoration('Status *'),
              isExpanded: true,
              items: ['ACTIVE', 'INACTIVE']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) { if (v != null) c.selectedStatus.value = v; },
            )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () { c.clearForm(); Navigator.pop(context); },
          child: const Text('Cancel'),
        ),
        Obx(() => ElevatedButton(
          onPressed: c.isLoading.value
              ? null
              : () async {
                  if (!widget.isEdit && _scannedQrId == null) {
                    CustomSnackbar.showError(context, 'Please scan the machine QR first');
                    return;
                  }
                  if (widget.isEdit) {
                    await c.updateMachine(widget.machine!.machineId!);
                  } else {
                    await c.createMachineWithQr(_scannedQrId!);
                  }
                  if (!c.isLoading.value && context.mounted) {
                    Navigator.pop(context);
                  }
                },
          style: AppTheme.primaryButtonStyle,
          child: c.isLoading.value
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(widget.isEdit ? 'Update' : 'Create'),
        )),
      ],
    );
  }
}
