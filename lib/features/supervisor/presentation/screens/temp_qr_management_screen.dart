import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../hr/presentation/controller/hr_controller.dart';
import '../controller/temp_qr_controller.dart';
import '../widgets/qr_scan_dialog.dart';
import '../widgets/active_mappings_view.dart';
import '../widgets/all_mappings_view.dart';
import '../widgets/scan_history_view.dart';

class TempQrManagementScreen extends StatelessWidget {
  final String empId;
  
  const TempQrManagementScreen({super.key, required this.empId});
  
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TempQrController(empId: empId));
    
    // Ensure HrController is initialized for employee list
    final hrController = Get.put(HrController());
    
    return Stack(
      children: [
        Obx(() => Column(
          children: [
            // View selector tabs
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      'Active (${controller.activeMappings.length})',
                      controller.selectedView.value == 'active',
                      () => controller.changeView('active'),
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      'All',
                      controller.selectedView.value == 'all',
                      () => controller.changeView('all'),
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      'History',
                      controller.selectedView.value == 'history',
                      () => controller.changeView('history'),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content area
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                switch (controller.selectedView.value) {
                  case 'active':
                    return ActiveMappingsView(controller: controller);
                  case 'all':
                    return AllMappingsView(controller: controller);
                  case 'history':
                    return ScanHistoryView(controller: controller);
                  default:
                    return const Center(child: Text('Unknown view'));
                }
              }),
            ),
          ],
        )),
        // FAB
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showQrScanDialog(context, controller, hrController),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTabButton(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
  
  void _showQrScanDialog(
    BuildContext context,
    TempQrController controller,
    HrController hrController,
  ) {
    showDialog(
      context: context,
      builder: (context) => QrScanDialog(
        controller: controller,
        employees: hrController.employees,
      ),
    );
  }
}
