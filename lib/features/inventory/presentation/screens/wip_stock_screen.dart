import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smo_flutter/core/config/app_config.dart';
import 'package:smo_flutter/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class WipStockScreen extends StatefulWidget {
  const WipStockScreen({Key? key}) : super(key: key);

  @override
  State<WipStockScreen> createState() => _WipStockScreenState();
}

class _WipStockScreenState extends State<WipStockScreen> {
  List<Map<String, dynamic>> operations = [];
  List<Map<String, dynamic>> routings = [];
  int? selectedRoutingId;
  bool isLoading = true;
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
            if (version != null) name += ' v$version';
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

  Future<void> _loadOperations() async {
    if (selectedRoutingId == null) return;
    
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/inventory/dashboard?routingId=$selectedRoutingId'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          operations = (data['operations'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Failed to load operations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load operations: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
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
              Text(
                'WIP Stock Management',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage garment pieces at each operation',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              
              // Routing selector
              Text(
                'Select Routing',
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
                  child: DropdownButton<int>(
                    value: selectedRoutingId,
                    hint: Row(
                      children: [
                        Icon(Icons.route, size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        const Text('Choose routing'),
                      ],
                    ),
                    isExpanded: true,
                    items: routings.map((routing) {
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
                    }).toList(),
                    onChanged: isLoadingRoutings ? null : (routingId) {
                      setState(() => selectedRoutingId = routingId);
                      if (routingId != null) {
                        _loadOperations();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Operations list
        Expanded(
          child: selectedRoutingId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Select a Routing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          'Choose a routing to manage WIP stock',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
              : isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : operations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No Operations',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadOperations,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: operations.length,
                            itemBuilder: (context, index) {
                              return _buildOperationCard(operations[index]);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildOperationCard(Map<String, dynamic> operation) {
    final operationName = operation['operationName'] ?? '';
    final operationId = operation['operationId'];
    final actualQty = operation['actualQty'] ?? 0;
    final minTarget = operation['minTarget'] ?? 0;
    final maxTarget = operation['maxTarget'] ?? 0;
    final status = operation['stockStatus'] ?? 'NOT_SET';
    
    final statusColor = _getStatusColor(status);
    final stockPercent = maxTarget > 0 ? (actualQty / maxTarget).clamp(0.0, 1.0) : 0.5;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
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
                        operationName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Operation ID: $operationId',
                        style: TextStyle(
                          fontSize: 12,
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
                    status == 'NOT_SET' ? 'No Target' : status,
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
            
            // Stock info boxes
            Row(
              children: [
                Expanded(
                  child: _buildStockBox(
                    'Current Stock',
                    '$actualQty pcs',
                    AppTheme.primary,
                    Icons.inventory_2,
                  ),
                ),
                if (minTarget > 0) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStockBox(
                      'Target/Day',
                      '$minTarget pcs',
                      Colors.orange[700]!,
                      Icons.flag,
                    ),
                  ),
                ],
              ],
            ),
            
            if (minTarget > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: stockPercent,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining: ${minTarget - actualQty} pcs',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${((actualQty / minTarget) * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReceiveDialog(operation),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Receive'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green[700],
                      side: BorderSide(color: Colors.green[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: actualQty > 0
                        ? () => _showIssueDialog(operation)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    label: const Text('Issue'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange[700],
                      side: BorderSide(color: Colors.orange[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockBox(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  void _showReceiveDialog(Map<String, dynamic> operation) {
    final qtyController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receive Pieces'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              operation['operationName'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Current Stock: ${operation['actualQty']} pieces',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity to Receive',
                hintText: 'e.g., 100',
                border: OutlineInputBorder(),
                suffixText: 'pieces',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'From previous operation...',
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
              final qty = int.tryParse(qtyController.text.trim());
              if (qty == null || qty <= 0) {
                CustomSnackbar.showError(context, 'Please enter a valid quantity');
                return;
              }
              
              Navigator.pop(context);
              CustomSnackbar.showInfo(
                context,
                'Receive WIP stock feature - Coming soon!\nWill add $qty pieces to ${operation['operationName']}',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Receive'),
          ),
        ],
      ),
    );
  }

  void _showIssueDialog(Map<String, dynamic> operation) {
    final qtyController = TextEditingController();
    final notesController = TextEditingController();
    final currentQty = operation['actualQty'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Issue Pieces'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              operation['operationName'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Available: $currentQty pieces',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity to Issue',
                hintText: 'Max: $currentQty',
                border: const OutlineInputBorder(),
                suffixText: 'pieces',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Sent to next operation...',
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
              final qty = int.tryParse(qtyController.text.trim());
              if (qty == null || qty <= 0) {
                CustomSnackbar.showError(context, 'Please enter a valid quantity');
                return;
              }
              
              if (qty > currentQty) {
                CustomSnackbar.showError(
                  context,
                  'Cannot issue more than available ($currentQty pieces)',
                );
                return;
              }
              
              Navigator.pop(context);
              CustomSnackbar.showInfo(
                context,
                'Issue WIP stock feature - Coming soon!\nWill remove $qty pieces from ${operation['operationName']}',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Issue'),
          ),
        ],
      ),
    );
  }
}
