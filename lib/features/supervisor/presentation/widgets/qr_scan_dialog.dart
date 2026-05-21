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
  EmployeeModel? selectedEmployee;
  bool isCheckingQr = false;
  bool needsEmployeeSelection = false;
  bool useCameraScanner = true;
  late MobileScannerController mobileScannerController;
  List<EmployeeModel> employees = [];
  bool isLoadingEmployees = false;
  
  @override
  void initState() {
    super.initState();
    mobileScannerController = MobileScannerController();
    employees = widget.employees;
    
    // If no employees provided, fetch from API
    if (employees.isEmpty) {
      _fetchEmployees();
    }
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Camera Scanner
            if (useCameraScanner && !needsEmployeeSelection)
              Expanded(
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
    
    if (employees.isEmpty) {
      return const Text('No employees available');
    }
    
    return DropdownButtonFormField<EmployeeModel>(
      value: selectedEmployee,
      decoration: AppTheme.inputDecoration('Select Employee'),
      isExpanded: true,
      items: employees.map((emp) {
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
    );
  }
}
