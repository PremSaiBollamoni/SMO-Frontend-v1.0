import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:smo_flutter/core/config/app_config.dart';
import 'package:smo_flutter/core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DailyLedgerScreen extends StatefulWidget {
  const DailyLedgerScreen({Key? key}) : super(key: key);

  @override
  State<DailyLedgerScreen> createState() => _DailyLedgerScreenState();
}

class _DailyLedgerScreenState extends State<DailyLedgerScreen> {
  DateTime selectedDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd');
  
  List<Map<String, dynamic>> routings = [];
  Map<String, dynamic>? selectedRouting;
  bool isLoadingRoutings = true;
  bool isLoadingLedger = false;
  List<Map<String, dynamic>> ledgerData = [];

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

  Future<void> _loadDailyLedger() async {
    if (selectedRouting == null) return;
    
    setState(() => isLoadingLedger = true);
    try {
      final dateStr = _apiDateFormat.format(selectedDate);
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/inventory/daily-ledger?date=$dateStr'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          ledgerData = data.cast<Map<String, dynamic>>();
        });
      } else {
        if (mounted) {
          CustomSnackbar.showError(context, 'Failed to load daily ledger');
        }
      }
    } catch (e) {
      debugPrint('Failed to load daily ledger: $e');
      if (mounted) {
        CustomSnackbar.showError(context, 'Error loading daily ledger: $e');
      }
    } finally {
      setState(() => isLoadingLedger = false);
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
              // Date selector
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.event, size: 20, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: Text(
                          _dateFormat.format(selectedDate),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: () {
                        setState(() {
                          selectedDate = selectedDate.subtract(const Duration(days: 1));
                        });
                        _loadDailyLedger();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: selectedDate.day != DateTime.now().day
                          ? () {
                              setState(() {
                                selectedDate = selectedDate.add(const Duration(days: 1));
                              });
                              _loadDailyLedger();
                            }
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Routing selector
              Text(
                'Select Routing/Style',
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
                  child: DropdownButton<Map<String, dynamic>>(
                    value: selectedRouting,
                    hint: Row(
                      children: [
                        Icon(Icons.route, size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        const Text('Choose routing/style'),
                      ],
                    ),
                    isExpanded: true,
                    items: routings.map((routing) {
                      return DropdownMenuItem(
                        value: routing,
                        child: Row(
                          children: [
                            Icon(Icons.route, size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(routing['name']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: isLoadingRoutings ? null : (routing) {
                      setState(() => selectedRouting = routing);
                      if (routing != null) {
                        _loadDailyLedger();
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
          child: selectedRouting == null
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
                          'Choose a routing to view operations stock ledger',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
              : isLoadingLedger
                  ? const Center(child: CircularProgressIndicator())
                  : ledgerData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No Ledger Data',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No stock movements recorded for this date',
                                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadDailyLedger,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: ledgerData.length,
                            itemBuilder: (context, index) {
                              final ledger = ledgerData[index];
                              return _buildLedgerCard(ledger);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Widget _buildLedgerCard(Map<String, dynamic> ledger) {
    final operationName = ledger['operationName'] ?? '';
    final openingStock = ledger['openingStock'] ?? 0;
    final receivedQty = ledger['receivedQty'] ?? 0;
    final issuedQty = ledger['issuedQty'] ?? 0;
    final closingStock = ledger['closingStock'] ?? 0;
    final minTarget = ledger['minTarget'] ?? 0;
    final maxTarget = ledger['maxTarget'] ?? 0;
    
    // Determine status color based on closing stock vs targets
    Color statusColor = Colors.grey[600]!;
    IconData statusIcon = Icons.help_outline;
    String statusText = 'Not Set';
    
    if (minTarget > 0 && maxTarget > 0) {
      if (closingStock < minTarget) {
        statusColor = Colors.red[600]!;
        statusIcon = Icons.arrow_downward;
        statusText = 'Low';
      } else if (closingStock > maxTarget) {
        statusColor = Colors.orange[600]!;
        statusIcon = Icons.arrow_upward;
        statusText = 'High';
      } else {
        statusColor = Colors.green[600]!;
        statusIcon = Icons.check_circle;
        statusText = 'Normal';
      }
    }

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
            // Operation name and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    operationName,
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
            
            // Stock movement in 4 columns
            Row(
              children: [
                _buildStockBox('Opening', openingStock.toString(), Colors.blue[700]!),
                const SizedBox(width: 8),
                _buildStockBox('Received', receivedQty.toString(), Colors.green[700]!),
                const SizedBox(width: 8),
                _buildStockBox('Issued', issuedQty.toString(), Colors.orange[700]!),
                const SizedBox(width: 8),
                _buildStockBox('Closing', closingStock.toString(), AppTheme.primary),
              ],
            ),
            
            // Targets (if set)
            if (minTarget > 0 || maxTarget > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTargetInfo('Min Target', minTarget.toString(), Colors.orange[700]!),
                    Container(width: 1, height: 30, color: Colors.grey[300]),
                    _buildTargetInfo('Max Target', maxTarget.toString(), Colors.green[700]!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStockBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
