import 'package:flutter/material.dart';
import 'package:smo_flutter/features/inventory/data/stock_management_api.dart';
import 'package:smo_flutter/features/inventory/domain/models/raw_material_stock.dart';
import 'package:smo_flutter/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({Key? key}) : super(key: key);

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  List<RawMaterialStock> materials = [];
  bool isLoading = true;
  String selectedFilter = 'ALL'; // ALL, LOW, CRITICAL

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() => isLoading = true);
    try {
      final data = await StockManagementApi.getAllRawMaterials();
      setState(() {
        materials = data.map((json) => RawMaterialStock.fromJson(json)).toList();
      });
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to load materials: $e');
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<RawMaterialStock> get filteredMaterials {
    if (selectedFilter == 'LOW') {
      return materials.where((m) => m.stockStatus == 'LOW' || m.stockStatus == 'CRITICAL').toList();
    } else if (selectedFilter == 'CRITICAL') {
      return materials.where((m) => m.stockStatus == 'CRITICAL').toList();
    }
    return materials;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with actions
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
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Raw Material Stock',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddMaterialDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Material'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All Stock'),
                    const SizedBox(width: 8),
                    _buildFilterChip('LOW', 'Low Stock'),
                    const SizedBox(width: 8),
                    _buildFilterChip('CRITICAL', 'Critical'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Materials list
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredMaterials.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No materials found',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _showAddMaterialDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Material'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMaterials,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredMaterials.length,
                        itemBuilder: (context, index) {
                          return _buildMaterialCard(filteredMaterials[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => selectedFilter = value);
      },
      selectedColor: AppTheme.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primary : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primary : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildMaterialCard(RawMaterialStock material) {
    final statusColor = _getStatusColor(material.stockStatus);
    final stockPercent = _calculateStockPercent(material);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showMaterialDetails(material),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.materialName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${material.materialType}${material.materialCode != null ? ' • ${material.materialCode}' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      material.stockStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Stock bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: stockPercent,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  _buildStockInfo(
                    'Current',
                    '${material.currentStock.toStringAsFixed(0)} ${material.unit}',
                    AppTheme.primary,
                  ),
                  const SizedBox(width: 16),
                  _buildStockInfo(
                    'Min',
                    material.minStockLevel.toStringAsFixed(0),
                    Colors.orange[700]!,
                  ),
                  const SizedBox(width: 16),
                  _buildStockInfo(
                    'Max',
                    material.maxStockLevel.toStringAsFixed(0),
                    Colors.green[700]!,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showReceiveDialog(material),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Receive'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green[700],
                        side: BorderSide(color: Colors.green[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showIssueDialog(material),
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      label: const Text('Issue'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[700],
                        side: BorderSide(color: Colors.orange[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showAdjustDialog(material),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Adjust'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        side: BorderSide(color: Colors.blue[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CRITICAL':
        return Colors.red[700]!;
      case 'LOW':
        return Colors.orange[700]!;
      case 'HIGH':
        return Colors.blue[700]!;
      default:
        return Colors.green[700]!;
    }
  }

  double _calculateStockPercent(RawMaterialStock material) {
    if (material.maxStockLevel == 0) return 0.5;
    return (material.currentStock / material.maxStockLevel).clamp(0.0, 1.0);
  }

  void _showMaterialDetails(RawMaterialStock material) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MaterialDetailsSheet(material: material),
    );
  }

  void _showAddMaterialDialog() {
    // TODO: Implement add material dialog
    CustomSnackbar.showInfo(context, 'Add Material dialog - Coming soon');
  }

  void _showReceiveDialog(RawMaterialStock material) {
    _showStockMovementDialog(
      material: material,
      title: 'Receive Stock',
      actionLabel: 'Receive',
      actionColor: Colors.green[700]!,
      onSubmit: (qty, notes) async {
        try {
          final result = await StockManagementApi.receiveStock({
            'rawMaterialId': material.rawMaterialId,
            'qty': qty,
            'unit': material.unit,
            'notes': notes,
            'performedBy': 2001, // TODO: Get from auth
          });
          
          if (result['success'] == true && mounted) {
            CustomSnackbar.showSuccess(context, 'Stock received successfully');
            _loadMaterials();
            Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            CustomSnackbar.showError(context, 'Failed to receive stock: $e');
          }
        }
      },
    );
  }

  void _showIssueDialog(RawMaterialStock material) {
    _showStockMovementDialog(
      material: material,
      title: 'Issue Stock',
      actionLabel: 'Issue',
      actionColor: Colors.orange[700]!,
      onSubmit: (qty, notes) async {
        try {
          final result = await StockManagementApi.issueStock({
            'rawMaterialId': material.rawMaterialId,
            'qty': qty,
            'unit': material.unit,
            'notes': notes,
            'performedBy': 2001, // TODO: Get from auth
          });
          
          if (result['success'] == true && mounted) {
            CustomSnackbar.showSuccess(context, 'Stock issued successfully');
            _loadMaterials();
            Navigator.pop(context);
          } else if (mounted) {
            CustomSnackbar.showError(context, result['message'] ?? 'Failed to issue stock');
          }
        } catch (e) {
          if (mounted) {
            CustomSnackbar.showError(context, 'Failed to issue stock: $e');
          }
        }
      },
    );
  }

  void _showAdjustDialog(RawMaterialStock material) {
    _showStockMovementDialog(
      material: material,
      title: 'Adjust Stock',
      actionLabel: 'Adjust',
      actionColor: Colors.blue[700]!,
      allowNegative: true,
      onSubmit: (qty, notes) async {
        try {
          final result = await StockManagementApi.adjustStock({
            'rawMaterialId': material.rawMaterialId,
            'qty': qty,
            'unit': material.unit,
            'notes': notes,
            'performedBy': 2001, // TODO: Get from auth
          });
          
          if (result['success'] == true && mounted) {
            CustomSnackbar.showSuccess(context, 'Stock adjusted successfully');
            _loadMaterials();
            Navigator.pop(context);
          } else if (mounted) {
            CustomSnackbar.showError(context, result['message'] ?? 'Failed to adjust stock');
          }
        } catch (e) {
          if (mounted) {
            CustomSnackbar.showError(context, 'Failed to adjust stock: $e');
          }
        }
      },
    );
  }

  void _showStockMovementDialog({
    required RawMaterialStock material,
    required String title,
    required String actionLabel,
    required Color actionColor,
    bool allowNegative = false,
    required Future<void> Function(int qty, String notes) onSubmit,
  }) {
    final qtyController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              material.materialName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Current Stock: ${material.currentStock.toStringAsFixed(0)} ${material.unit}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.numberWithOptions(signed: allowNegative, decimal: false),
              decoration: InputDecoration(
                labelText: 'Quantity ${allowNegative ? '(+/-)' : ''}',
                hintText: allowNegative ? 'e.g., +50 or -20' : 'e.g., 50',
                border: const OutlineInputBorder(),
                suffixText: material.unit,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Optional notes...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final qtyText = qtyController.text.trim();
              if (qtyText.isEmpty) {
                CustomSnackbar.showError(context, 'Please enter quantity');
                return;
              }
              
              final qty = int.tryParse(qtyText);
              if (qty == null || (!allowNegative && qty <= 0)) {
                CustomSnackbar.showError(context, 'Please enter a valid quantity');
                return;
              }
              
              onSubmit(qty, notesController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

// Material details bottom sheet
class _MaterialDetailsSheet extends StatelessWidget {
  final RawMaterialStock material;

  const _MaterialDetailsSheet({required this.material});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        material.materialName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildDetailRow('Material Type', material.materialType),
                    _buildDetailRow('Material Code', material.materialCode ?? 'N/A'),
                    _buildDetailRow('Current Stock', '${material.currentStock.toStringAsFixed(2)} ${material.unit}'),
                    _buildDetailRow('Minimum Level', '${material.minStockLevel.toStringAsFixed(0)} ${material.unit}'),
                    _buildDetailRow('Maximum Level', '${material.maxStockLevel.toStringAsFixed(0)} ${material.unit}'),
                    _buildDetailRow('Reorder Level', '${material.reorderLevel.toStringAsFixed(0)} ${material.unit}'),
                    _buildDetailRow('Warehouse Location', material.warehouseLocation ?? 'N/A'),
                    _buildDetailRow('Status', material.stockStatus),
                    if (material.lastUpdated != null)
                      _buildDetailRow('Last Updated', DateFormat('MMM dd, yyyy hh:mm a').format(material.lastUpdated!)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
