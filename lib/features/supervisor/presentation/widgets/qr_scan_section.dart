import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/attendance/data/api/attendance_api_service.dart';
import '../../data/api/job_api_service.dart';
import '../../../hr/data/models/station_models.dart';
import 'tray_qty_sheet.dart';
import 'job_complete_sheet.dart';

class QrScanSection extends StatefulWidget {
  final StationModel station;
  final String supervisorEmpId;
  final VoidCallback onJobAssigned;
  final VoidCallback onJobCompleted;
  final Function(String) onError;

  const QrScanSection({
    super.key,
    required this.station,
    required this.supervisorEmpId,
    required this.onJobAssigned,
    required this.onJobCompleted,
    required this.onError,
  });

  @override
  State<QrScanSection> createState() => _QrScanSectionState();
}

class _QrScanSectionState extends State<QrScanSection> {
  final _jobApi = JobApiService();
  final _attApi = AttendanceApiService();
  final _empController = TextEditingController();
  final _trayController = TextEditingController();
  MobileScannerController? _scanner;
  String? _scanningField;

  @override
  void dispose() {
    _scanner?.dispose();
    _empController.dispose();
    _trayController.dispose();
    super.dispose();
  }

  void _startScan(String field) {
    setState(() => _scanningField = field);
    _scanner = MobileScannerController();
  }

  void _stopScan() {
    _scanner?.dispose();
    _scanner = null;
    setState(() => _scanningField = null);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;
    if (_scanningField == 'emp') _empController.text = code;
    else if (_scanningField == 'tray') _trayController.text = code;
    _stopScan();
  }

  Future<void> _submit() async {
    final empQr = _empController.text.trim();
    final trayQr = _trayController.text.trim();

    if (empQr.isEmpty || !empQr.startsWith('EMP-TEMP-')) {
      widget.onError('Invalid Employee QR (must start with EMP-TEMP-)');
      return;
    }
    if (trayQr.isEmpty || !trayQr.startsWith('TRAY-')) {
      widget.onError('Invalid Tray QR (must start with TRAY-)');
      return;
    }

    try {
      int empId;
      try {
        empId = await _attApi.resolveQr(empQr);
      } catch (_) {
        widget.onError('Employee not checked in today. Check in first.');
        return;
      }
      final jobs = await _jobApi.getActiveJobsByStation(widget.station.wsId);
      final existing = jobs.where((j) => j.empId == empId).firstOrNull;

      if (existing != null) {
        final res = await _jobApi.scanBundle(
          barcode: existing.barcode,
          wsId: widget.station.wsId,
          empId: empId,
          assignedBy: int.tryParse(widget.supervisorEmpId) ?? 0,
        );
        if (res.action == 'COMPLETE' && res.completedJob != null && mounted) {
          await JobCompleteSheet.show(context, res.completedJob!);
          _empController.clear();
          _trayController.clear();
          widget.onJobCompleted();
        }
      } else {
        final qty = await TrayQtySheet.show(context, 'Employee $empId');
        if (qty != null && qty > 0) {
          await _jobApi.scanBundle(
            barcode: trayQr,
            wsId: widget.station.wsId,
            empId: empId,
            assignedBy: int.tryParse(widget.supervisorEmpId) ?? 0,
            bundleQty: qty,
          );
          _empController.clear();
          _trayController.clear();
          widget.onJobAssigned();
        }
      }
    } catch (e) {
      widget.onError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_scanningField != null) {
      return Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(height: 300, child: MobileScanner(controller: _scanner!, onDetect: _onDetect)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _stopScan,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Cancel'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
          ),
        ),
      ]);
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 3, height: 20, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            const Text('Assign Job', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
          ]),
          const SizedBox(height: 20),
          TextFormField(
            controller: _empController,
            decoration: InputDecoration(
              labelText: 'Employee QR',
              hintText: 'EMP-TEMP-XXX',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => _startScan('emp'),
                icon: Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primary),
                tooltip: 'Scan',
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _trayController,
            decoration: InputDecoration(
              labelText: 'Tray QR',
              hintText: 'TRAY-XXX',
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              suffixIcon: IconButton(
                onPressed: () => _startScan('tray'),
                icon: Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primary),
                tooltip: 'Scan',
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: const Text('Submit & Assign', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
