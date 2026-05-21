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
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temporary QR Code Management'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              switch (controller.selectedView.value) {
                case 'active':
                  controller.loadActiveMappings();
                  break;
                case 'all':
                  controller.loadAllMappings();
                  break;
                case 'history':
                  controller.loadScanHistory();
                  break;
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // View selector tabs
          Obx(() => Container(
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    context,
                    'Active',
                    'active',
                    controller.selectedView.value == 'active',
                    () => controller.changeView('active'),
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    context,
                    'All',
                    'all',
                    controller.selectedView.value == 'all',
                    () => controller.changeView('all'),
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    context,
                    'History',
                    'history',
                    controller.selectedView.value == 'history',
                    () => controller.changeView('history'),
                  ),
                ),
              ],
            ),
          )),
          
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQrScanDialog(context, controller, hrController),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
      ),
    );
  }
  
  Widget _buildTabButton(
    BuildContext context,
    String label,
    String value,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.primary : Colors.grey[300]!,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
