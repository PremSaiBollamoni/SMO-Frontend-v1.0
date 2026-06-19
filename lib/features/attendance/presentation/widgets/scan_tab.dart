import 'package:flutter/material.dart';
import '../../data/api/attendance_api_service.dart';
import '../../data/models/attendance_models.dart';
import '../../../../core/utils/api_error_helper.dart';
import '../../../hr/data/models/shift_models.dart';
import 'qr_scanner_card.dart';
import 'attendance_widgets.dart';

enum ScanStep { idle, scanning, mapEmployee, scanMachineQr, selectShift }

class ScanTab extends StatefulWidget {
  final int supervisorEmpId;
  final List<EmployeeOption> employees;
  final List<ShiftTemplateModel> shifts;
  final AttendanceApiService api;
  final VoidCallback onSuccess;

  const ScanTab({
    super.key,
    required this.supervisorEmpId,
    required this.employees,
    required this.shifts,
    required this.api,
    required this.onSuccess,
  });

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  ScanStep _step = ScanStep.idle;
  String? _tempQrToken;
  EmployeeOption? _selectedEmployee;
  String? _machineCode;
  bool _processing = false;
  String? _error;

  void _reset() => setState(() {
        _step = ScanStep.idle;
        _tempQrToken = null;
        _selectedEmployee = null;
        _machineCode = null;
        _processing = false;
        _error = null;
      });

  Future<void> _onTempQrScanned(String qrToken) async {
    setState(() { _tempQrToken = qrToken; _processing = true; _error = null; });

    // Try checkout first — if there's an active check-in for this QR today
    try {
      await widget.api.checkOut(tempQrToken: qrToken, markedBy: widget.supervisorEmpId);
      if (!mounted) return;
      _showSuccess('Check-out recorded for $qrToken');
      widget.onSuccess();
      _reset();
      return;
    } catch (_) {}

    // Not checked in — proceed with check-in flow
    try {
      final empId = await widget.api.resolveQr(qrToken);
      final emp = widget.employees.where((e) => e.empId == empId).firstOrNull;
      setState(() { _selectedEmployee = emp; _step = ScanStep.scanMachineQr; _processing = false; });
    } catch (_) {
      setState(() { _step = ScanStep.mapEmployee; _processing = false; });
    }
  }

  Future<void> _onEmployeeSelected(EmployeeOption emp) async {
    setState(() { _selectedEmployee = emp; _processing = true; _error = null; });
    try {
      await widget.api.mapQr(qrToken: _tempQrToken!, empId: emp.empId, mappedBy: widget.supervisorEmpId);
      setState(() { _step = ScanStep.scanMachineQr; _processing = false; });
    } catch (e) {
      setState(() { _error = ApiErrorHelper.getMessage(e); _processing = false; });
    }
  }

  Future<void> _onMachineQrScanned(String machineCode) async {
    setState(() { _machineCode = machineCode; });
    if (widget.shifts.isNotEmpty) {
      setState(() => _step = ScanStep.selectShift);
    } else {
      await _doCheckIn(null);
    }
  }

  Future<void> _doCheckIn(ShiftTemplateModel? shift) async {
    setState(() { _processing = true; _error = null; });
    try {
      await widget.api.checkIn(
        tempQrToken: _tempQrToken!,
        machineCode: _machineCode!,
        shiftTemplateId: shift?.templateId,
        markedBy: widget.supervisorEmpId,
      );
      if (!mounted) return;
      _showSuccess('${_selectedEmployee?.name ?? "Employee"} checked in at $_machineCode');
      widget.onSuccess();
      _reset();
    } catch (e) {
      setState(() { _error = ApiErrorHelper.getMessage(e); _processing = false; _step = ScanStep.idle; });
    }
  }

  void _showSuccess(String msg) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Success')]),
          content: Text(msg),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            ErrorBanner(message: _error!, onDismiss: () => setState(() { _error = null; _step = ScanStep.idle; })),

          if (_step == ScanStep.idle)
            IdleScanPrompt(onScan: () => setState(() => _step = ScanStep.scanning)),

          if (_step == ScanStep.scanning) ...[
            const StepHeader(step: '1', title: 'Scan Employee Temp QR', subtitle: 'Scan the physical QR card given to the employee'),
            const SizedBox(height: 16),
            QrScannerCard(onScanned: _onTempQrScanned, expectedPrefix: 'EMP-TEMP'),
            if (_processing) const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator())),
            const SizedBox(height: 12),
            TextButton(onPressed: _reset, child: const Text('Cancel')),
          ],

          if (_step == ScanStep.mapEmployee) ...[
            StepHeader(step: '2', title: 'Assign Employee', subtitle: '${_tempQrToken ?? ""} not assigned today.\nSelect who holds this card.'),
            const SizedBox(height: 16),
            EmployeeDropdown(
              employees: widget.employees,
              selected: _selectedEmployee,
              onChanged: _processing ? null : (emp) { if (emp != null) _onEmployeeSelected(emp); },
            ),
            if (_processing) const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator())),
            const SizedBox(height: 12),
            TextButton(onPressed: _reset, child: const Text('Cancel')),
          ],

          if (_step == ScanStep.scanMachineQr) ...[
            const StepHeader(step: '3', title: 'Scan Machine QR', subtitle: 'Scan the QR code fixed on the machine'),
            const SizedBox(height: 8),
            if (_selectedEmployee != null) InfoChip(label: 'Employee', value: _selectedEmployee!.name),
            const SizedBox(height: 12),
            QrScannerCard(onScanned: _onMachineQrScanned, expectedPrefix: 'MACHINE'),
            const SizedBox(height: 12),
            TextButton(onPressed: _reset, child: const Text('Cancel')),
          ],

          if (_step == ScanStep.selectShift) ...[
            const StepHeader(step: '4', title: 'Select Shift', subtitle: 'Which shift is this employee attending?'),
            const SizedBox(height: 8),
            if (_selectedEmployee != null) InfoChip(label: 'Employee', value: _selectedEmployee!.name),
            if (_machineCode != null) InfoChip(label: 'Machine', value: _machineCode!),
            const SizedBox(height: 16),
            ...widget.shifts.map((s) => ShiftTile(shift: s, onTap: _processing ? null : () => _doCheckIn(s))),
            TextButton(onPressed: _processing ? null : () => _doCheckIn(null), child: const Text('Skip (No Shift)')),
            TextButton(onPressed: _reset, child: const Text('Cancel')),
            if (_processing) const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
