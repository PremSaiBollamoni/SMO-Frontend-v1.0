import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smo_flutter/features/inventory/data/inventory_api.dart';
import 'package:smo_flutter/features/inventory/domain/models/stock_limit.dart';
import 'package:smo_flutter/core/theme/app_theme.dart';
import 'package:smo_flutter/core/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageStockLimitsScreen extends StatefulWidget {
  const ManageStockLimitsScreen({Key? key}) : super(key: key);

  @override
  State<ManageStockLimitsScreen> createState() => _ManageStockLimitsScreenState();
}

class _ManageStockLimitsScreenState extends State<ManageStockLimitsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _minDayController = TextEditingController();
  final TextEditingController _maxDayController = TextEditingController();
  final TextEditingController _minMonthController = TextEditingController();
  final TextEditingController _maxMonthController = TextEditingController();
  
  List<Map<String, dynamic>> operations = [];
  List<Map<String, dynamic>> allOperations = [];
  List<Map<String, dynamic>> routings = [];
  Map<String, dynamic>? selectedOperation;
  Map<String, dynamic>? selectedRouting;
  bool isLoading = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRoutings();
    _loadOperations();
  }

  Future<void> _loadRoutings() async {
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
    }
  }

  Future<void> _loadOperations() async {
    setState(() => isLoading = true);
    try {
      final ops = await InventoryApi.getOperations();
      setState(() {
        allOperations = ops;
        operations = ops;
      });
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Failed to load operations: $e');
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _filterOperationsByRouting(int? routingId) async {
    if (routingId == null) {
      setState(() {
        operations = allOperations;
        selectedOperation = null;
      });
      return;
    }

    try {
      // Fetch operations for this routing from backend
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/inventory/dashboard?routingId=$routingId'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> opsData = data['operations'] ?? [];
        setState(() {
          operations = opsData.map((op) {
            return {
              'operation_id': op['operationId'],
              'name': op['operationName'],
            };
          }).toList().cast<Map<String, dynamic>>();
          selectedOperation = null;
        });
      }
    } catch (e) {
      debugPrint('Failed to filter operations: $e');
    }
  }

  Future<void> _loadExistingLimit(int operationId) async {
    try {
      final limit = await InventoryApi.getStockLimit(operationId);
      if (limit != null) {
        _minDayController.text = limit.minQtyPerDay.toString();
        _maxDayController.text = limit.maxQtyPerDay.toString();
        _minMonthController.text = limit.minQtyPerMonth.toString();
        _maxMonthController.text = limit.maxQtyPerMonth.toString();
      }
    } catch (e) {
      debugPrint('Failed to load existing limit: $e');
    }
  }

  void _clearForm() {
    _minDayController.clear();
    _maxDayController.clear();
    _minMonthController.clear();
    _maxMonthController.clear();
  }

  Future<void> _saveLimit() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedOperation == null) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Please select an operation');
      }
      return;
    }

    setState(() => isSaving = true);
    try {
      final limit = StockLimit(
        operationId: selectedOperation!['operation_id'],
        minQtyPerDay: int.parse(_minDayController.text),
        maxQtyPerDay: int.parse(_maxDayController.text),
        minQtyPerMonth: int.parse(_minMonthController.text),
        maxQtyPerMonth: int.parse(_maxMonthController.text),
      );

      final response = await InventoryApi.saveStockLimit(limit);
      
      if (response['success'] == true) {
        if (mounted) {
          CustomSnackbar.showSuccess(
            context,
            'Stock limit saved successfully',
          );
        }
        _clearForm();
        setState(() => selectedOperation = null);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context,
          'Failed to save: $e',
        );
      }
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    _minDayController.dispose();
    _maxDayController.dispose();
    _minMonthController.dispose();
    _maxMonthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Routing selector
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
                  color: Colors.white,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>>(
                    value: selectedRouting,
                    hint: const Text('All Routings'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Routings'),
                      ),
                      ...routings.map((routing) {
                        return DropdownMenuItem(
                          value: routing,
                          child: Text(routing['name']),
                        );
                      }),
                    ],
                    onChanged: (routing) {
                      setState(() => selectedRouting = routing);
                      _filterOperationsByRouting(routing?['routing_id'] as int?);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Operation selector
                    Text(
                      'Select Operation',
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
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, dynamic>>(
                          value: selectedOperation,
                          hint: const Text('Choose an operation'),
                          isExpanded: true,
                          items: operations.map((op) {
                            return DropdownMenuItem(
                              value: op,
                              child: Text(op['name'] ?? 'Operation ${op['operation_id']}'),
                            );
                          }).toList(),
                          onChanged: (op) {
                            setState(() => selectedOperation = op);
                            if (op != null) {
                              _clearForm();
                              _loadExistingLimit(op['operation_id']);
                            }
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Daily targets
                    _buildSectionHeader('Daily Targets'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _minDayController,
                            label: 'Minimum/Day',
                            hint: 'e.g., 800',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _maxDayController,
                            label: 'Maximum/Day',
                            hint: 'e.g., 2667',
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Monthly targets
                    _buildSectionHeader('Monthly Targets'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _minMonthController,
                            label: 'Minimum/Month',
                            hint: 'e.g., 20800',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _maxMonthController,
                            label: 'Maximum/Month',
                            hint: 'e.g., 69333',
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _saveLimit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Stock Limits',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            if (int.tryParse(value) == null) {
              return 'Invalid';
            }
            return null;
          },
        ),
      ],
    );
  }
}
