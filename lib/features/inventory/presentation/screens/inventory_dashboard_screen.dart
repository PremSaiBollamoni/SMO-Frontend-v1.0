import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smo_flutter/features/inventory/presentation/controllers/inventory_controller.dart';
import 'package:smo_flutter/features/inventory/domain/models/operation_stock_view.dart';
import 'package:smo_flutter/core/config/app_config.dart';
import 'package:smo_flutter/core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InventoryDashboardScreen extends StatefulWidget {
  const InventoryDashboardScreen({Key? key}) : super(key: key);

  @override
  State<InventoryDashboardScreen> createState() => _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState extends State<InventoryDashboardScreen> {
  List<Map<String, dynamic>> routings = [];
  int? selectedRoutingId;
  bool isLoadingRoutings = true;

  @override
  void initState() {
    super.initState();
    _loadRoutings();
  }

  Future<void> _loadRoutings() async {
    setState(() => isLoadingRoutings = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/inventory/routings'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          routings = data.map((item) {
            final routingId = item['routing_id'];
            final version = item['version'];
            final productName = item['product_name'];
            
            String name = 'Routing $routingId';
            if (version != null) {
              name += ' v$version';
            }
            if (productName != null && productName.toString().isNotEmpty) {
              name += ' - $productName';
            }
            
            return {
              'routing_id': routingId,
              'name': name,
            };
          }).cast<Map<String, dynamic>>().toList();
        });
      }
    } catch (e) {
      debugPrint('Failed to load routings: $e');
    } finally {
      setState(() => isLoadingRoutings = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InventoryController());

    return Column(
      children: [
        // Header with routing filter
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (routings.isNotEmpty) ...[
                Text(
                  'Filter by Routing',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: selectedRoutingId,
                      hint: Row(
                        children: [
                          Icon(Icons.filter_list, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          const Text('All Routings'),
                        ],
                      ),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Row(
                            children: [
                              Icon(Icons.select_all, size: 18, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              const Text('All Routings'),
                            ],
                          ),
                        ),
                        ...routings.map((routing) {
                          return DropdownMenuItem(
                            value: routing['routing_id'] as int,
                            child: Row(
                              children: [
                                Icon(Icons.route, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(routing['name']),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (routingId) {
                        setState(() => selectedRoutingId = routingId);
                        controller.setRoutingFilter(routingId);
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Stats summary
        Obx(() {
          final summary = controller.summary;
          if (summary.isEmpty) return const SizedBox();
          
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatChip('Total', summary['total'] ?? 0, AppTheme.primary),
                const SizedBox(width: 8),
                _buildStatChip('Low', summary['lowStock'] ?? 0, Colors.red[600]!),
                const SizedBox(width: 8),
                _buildStatChip('High', summary['highStock'] ?? 0, Colors.orange[600]!),
                const SizedBox(width: 8),
                _buildStatChip('OK', summary['normal'] ?? 0, Colors.green[600]!),
              ],
            ),
          );
        }),

        // Operations grid
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.operations.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.operations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No operations found',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try selecting a different routing',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: controller.loadDashboard,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.operations.length,
                itemBuilder: (context, index) {
                  return _buildOperationCard(controller.operations[index]);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationCard(OperationStockView operation) {
    final statusColor = _getStatusColor(operation.stockStatus);
    final statusIcon = _getStatusIcon(operation.stockStatus);
    final statusText = _getStatusText(operation.stockStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to details if needed
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      operation.operationName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoBox('Actual Stock', '${operation.actualQty}', AppTheme.primary),
                  const SizedBox(width: 12),
                  if (operation.minTarget > 0)
                    _buildInfoBox('Min Target', '${operation.minTarget}', Colors.orange[700]!),
                  if (operation.minTarget > 0) const SizedBox(width: 12),
                  if (operation.maxTarget > 0)
                    _buildInfoBox('Max Target', '${operation.maxTarget}', Colors.green[700]!),
                ],
              ),
              if (operation.stockStatus != 'NOT_SET' && operation.varianceFromMin != 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      operation.varianceFromMin >= 0 ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: operation.varianceFromMin >= 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${operation.varianceFromMin.abs()} from minimum',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'LOW':
        return Colors.red[600]!;
      case 'HIGH':
        return Colors.orange[600]!;
      case 'NORMAL':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'LOW':
        return Icons.arrow_downward;
      case 'HIGH':
        return Icons.arrow_upward;
      case 'NORMAL':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'LOW':
        return 'Low Stock';
      case 'HIGH':
        return 'High Stock';
      case 'NORMAL':
        return 'Normal';
      default:
        return 'Not Set';
    }
  }
}
