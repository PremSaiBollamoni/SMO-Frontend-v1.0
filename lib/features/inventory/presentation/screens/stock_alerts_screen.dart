import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smo_flutter/features/inventory/presentation/controllers/inventory_controller.dart';

class StockAlertsScreen extends StatelessWidget {
  const StockAlertsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InventoryController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final lowStockOps = controller.operations.where((op) => op.stockStatus == 'LOW').toList();
        final highStockOps = controller.operations.where((op) => op.stockStatus == 'HIGH').toList();
        final notSetOps = controller.operations.where((op) => op.stockStatus == 'NOT_SET').toList();

        if (lowStockOps.isEmpty && highStockOps.isEmpty && notSetOps.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.loadDashboard,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Critical Alerts
              if (lowStockOps.isNotEmpty) ...[
                _buildSectionHeader('Critical - Low Stock', Icons.warning, Colors.red),
                const SizedBox(height: 12),
                ...lowStockOps.map((op) => _buildAlertCard(
                  operation: op.operationName,
                  message: 'Stock below minimum threshold',
                  actual: op.actualQty,
                  target: op.minTarget,
                  variance: op.varianceFromMin,
                  severity: 'CRITICAL',
                  color: Colors.red,
                )),
                const SizedBox(height: 24),
              ],

              // Warning Alerts
              if (highStockOps.isNotEmpty) ...[
                _buildSectionHeader('Warning - High Stock', Icons.trending_up, Colors.orange),
                const SizedBox(height: 12),
                ...highStockOps.map((op) => _buildAlertCard(
                  operation: op.operationName,
                  message: 'Stock above maximum threshold - Bottleneck detected',
                  actual: op.actualQty,
                  target: op.maxTarget,
                  variance: op.actualQty - op.maxTarget,
                  severity: 'WARNING',
                  color: Colors.orange,
                )),
                const SizedBox(height: 24),
              ],

              // Info Alerts
              if (notSetOps.isNotEmpty) ...[
                _buildSectionHeader('Info - Not Configured', Icons.info_outline, Colors.grey),
                const SizedBox(height: 12),
                ...notSetOps.map((op) => _buildAlertCard(
                  operation: op.operationName,
                  message: 'Stock limits not configured',
                  actual: op.actualQty,
                  target: 0,
                  variance: 0,
                  severity: 'INFO',
                  color: Colors.grey,
                )),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard({
    required String operation,
    required String message,
    required int actual,
    required int target,
    required int variance,
    required String severity,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    severity,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    operation,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  DateTime.now().toString().substring(11, 16),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip('Actual', actual.toString(), color),
                const SizedBox(width: 12),
                if (target > 0) _buildInfoChip('Target', target.toString(), Colors.grey),
                if (variance != 0) ...[
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    'Variance',
                    '${variance > 0 ? '+' : ''}$variance',
                    variance > 0 ? Colors.red : Colors.orange,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green[300]),
          const SizedBox(height: 16),
          Text(
            'All Clear!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No stock alerts at this time',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
