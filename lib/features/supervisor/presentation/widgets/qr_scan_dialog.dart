import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/config/app_config.dart';
import '../../../hr/domain/models/employee_model.dart';
import '../controller/temp_qr_controller.dart';

class QrScanDialog extends StatefulWidget {
  final TempQrController controller;
  final List<EmployeeModel> employees;
  
  const QrScanDialog({
    super.key, 
    required this.controller,
    required this.employees,
  });
  
  @override
  State<QrScanDialog> createState() => _QrScanDialogState();
}

class _QrScanDialogState extends State<QrScanDialog> {
  final TextEditingController qrController = TextEditingController();
  final TextEditingController employeeSearchController = TextEditingController();
  EmployeeModel? selectedEmployee;
  bool isCheckingQr = false;
  bool needsEmployeeSelection = false;
  bool useCameraScanner = true;
  late MobileScannerController mobileScannerController;
  List<EmployeeModel> employees = [];
  List<EmployeeModel> filteredEmployees = [];
  bool isLoadingEmployees = false;
  
  @override
  void initState() {
    super.initState();
    mobileScannerController = MobileScannerController();
    employees = widget.employees;
    filteredEmployees = employees;
    employeeSearchController.addListener(_filterEmployees);
    
    // If no employees provided, fetch from API
    if (employees.isEmpty) {
      _fetchEmployees();
    }
  }
  
  void _filterEmployees() {
    final query = employeeSearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredEmployees = employees;
      } else {
        filteredEmployees = employees.where((emp) {
          return emp.empName.toLowerCase().contains(query) ||
              emp.empId.toLowerCase().contains(query);
        }).toList();
      }
    });
  }
  
  Future<void> _fetchEmployees() async {
    setState(() {
      isLoadingEmployees = true;
    });
    
    try {
      debugPrint('[QR] Fetching employees from API');
      final response = await ApiClient().dio.get(
        '/api/temp-qr/employees',
      );
      
      if (response.statusCode == 200) {
        final list = (response.data as List<dynamic>)
            .map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>))
            .toList();
        
        setState(() {
          employees = list;
          filteredEmployees = list;
          debugPrint('[QR] Loaded ${employees.length} employees');
        });
      }
    } catch (e) {
      debugPrint('[QR] Error fetching employees: $e');
      _showError('Failed to load employees: $e');
    } finally {
      setState(() {
        isLoadingEmployees = false;
      });
    }
  }
  
  @override
  void dispose() {
    qrController.dispose();
    employeeSearchController.dispose();
    mobileScannerController.dispose();
    super.dispose();
  }
  
  Future<void> _handleScan() async {
    if (qrController.text.isEmpty) {
      _showError('Please enter QR code');
      return;
    }
    
    setState(() {
      isCheckingQr = true;
    });
    
    try {
      // Check if QR has active mapping
      final activeMappings = widget.controller.activeMappings;
      final existingMapping = activeMappings.firstWhereOrNull(
        (m) => m.qrId == qrController.text,
      );
      
      if (existingMapping != null) {
        // CHECK_OUT - no employee selection needed
        final response = await widget.controller.scanQrCode(
          qrId: qrController.text,
        );
        
        if (response != null && mounted) {
          Navigator.pop(context);
          _showSuccess(response.message);
        }
      } else {
        // CHECK_IN - need employee selection
        // Refresh active mappings before showing employee selector
        await widget.controller.loadActiveMappings();
        
        setState(() {
          needsEmployeeSelection = true;
          isCheckingQr = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
      setState(() {
        isCheckingQr = false;
      });
    }
  }
  
  Future<void> _handleCheckIn() async {
    if (selectedEmployee == null) {
      _showError('Please select an employee');
      return;
    }
    
    setState(() {
      isCheckingQr = true;
    });
    
    try {
      final response = await widget.controller.scanQrCode(
        qrId: qrController.text,
        employeeId: int.parse(selectedEmployee!.empId),
      );
      
      if (response != null && mounted) {
        Navigator.pop(context);
        _showSuccess(response.message);
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      setState(() {
        isCheckingQr = false;
      });
    }
  }
  
  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        setState(() {
          qrController.text = barcode.rawValue!;
          useCameraScanner = false;
        });
        // Auto-scan after detecting QR
        Future.delayed(const Duration(milliseconds: 500), _handleScan);
        break;
      }
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scan QR Code'),
      content: SizedBox(
        width: 400,
        height: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Camera Scanner
              if (useCameraScanner && !needsEmployeeSelection)
                SizedBox(
                  height: 300,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: MobileScanner(
                      controller: mobileScannerController,
                      onDetect: _onDetect,
                    ),
                  ),
                )
              else
                // Manual Input
                TextField(
                  controller: qrController,
                  decoration: AppTheme.inputDecoration('Enter QR Code'),
                  enabled: !needsEmployeeSelection,
                  autofocus: true,
                ),
            
            const SizedBox(height: 12),
            
            // Toggle between camera and manual input
            if (!needsEmployeeSelection)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    useCameraScanner = !useCameraScanner;
                  });
                },
                icon: Icon(useCameraScanner ? Icons.edit : Icons.camera_alt),
                label: Text(useCameraScanner ? 'Manual Input' : 'Use Camera'),
              ),
            
            if (needsEmployeeSelection) ...[
              const SizedBox(height: 16),
              const Text(
                'Select Employee for Check-in:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildEmployeeSelector(),
            ],
          ],
        ),
      ),
      ),
      actions: [
        TextButton(
          onPressed: isCheckingQr ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isCheckingQr
              ? null
              : (needsEmployeeSelection ? _handleCheckIn : _handleScan),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
          child: isCheckingQr
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(needsEmployeeSelection ? 'Check In' : 'Scan'),
        ),
      ],
    );
  }
  
  Widget _buildEmployeeSelector() {
    if (isLoadingEmployees) {
      return const Center(child: CircularProgressIndicator());
    }
    
    debugPrint('[QR_SELECTOR] Total employees: ${employees.length}');
    debugPrint('[QR_SELECTOR] Active mappings: ${widget.controller.activeMappings.length}');
    
    // Filter out employees who are already checked in (status = 'ACTIVE')
    final availableEmployees = filteredEmployees.where((emp) {
      // Check if this employee has an active check-in (status = 'ACTIVE')
      final hasActiveCheckIn = widget.controller.activeMappings.any(
        (mapping) {
          final match = mapping.employeeId == int.parse(emp.empId) && mapping.status == 'ACTIVE';
          if (match) {
            debugPrint('[QR_SELECTOR] Filtering out ${emp.empName} (${emp.empId}) - status: ${mapping.status}');
          }
          return match;
        },
      );
      return !hasActiveCheckIn;
    }).toList();
    
    debugPrint('[QR_SELECTOR] Available employees after filter: ${availableEmployees.length}');
    
    if (availableEmployees.isEmpty) {
      return const Text('No employees available (all checked in)');
    }

    // Reset selectedEmployee if it's no longer in the available list
    final validSelection = selectedEmployee != null &&
        availableEmployees.any((e) => e.empId == selectedEmployee!.empId);
    final effectiveSelection = validSelection ? selectedEmployee : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        TextField(
          controller: employeeSearchController,
          decoration: AppTheme.inputDecoration('Search employee by name or ID'),
          onChanged: (_) => _filterEmployees(),
        ),
        const SizedBox(height: 8),
        // Dropdown
        DropdownButtonFormField<EmployeeModel>(
          value: effectiveSelection,
          decoration: AppTheme.inputDecoration('Select Employee'),
          isExpanded: true,
          items: availableEmployees.map((emp) {
            return DropdownMenuItem(
              value: emp,
              child: SizedBox(
                width: 300,
                child: Text(
                  '${emp.empId} - ${emp.empName}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedEmployee = value;
            });
          },
        ),
      ],
    );
  }
}
