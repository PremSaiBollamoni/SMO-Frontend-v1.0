import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/attendance/data/api/attendance_api_service.dart';
import '../../../../features/attendance/data/models/attendance_models.dart';
import '../../data/api/job_api_service.dart';
import '../../data/models/job_assignment_model.dart';
import '../../../hr/data/api/workstation_api_service.dart';
import '../../../hr/data/models/station_models.dart';
import 'job_complete_sheet.dart';

class BundleScanTab extends StatefulWidget {
  final String supervisorEmpId;
  const BundleScanTab({super.key, required this.supervisorEmpId});

  @override
  State<BundleScanTab> createState() => _BundleScanTabState();
}

class _BundleScanTabState extends State<BundleScanTab> {
  final _jobApi = JobApiService();
  final _wsApi = WorkstationApiService();
  final _attApi = AttendanceApiService();

  List<StationModel> _stations = [];
  List<AttendanceRecord> _checkedInEmployees = [];
  int? _selectedStationId;
  int? _selectedEmpId;

  bool _loadingData = true;
  bool _scanning = false;
  bool _processing = false;
  MobileScannerController? _scanner;
  ScanBundleResponse? _lastAssign;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    _scanner?.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    setState(() => _loadingData = true);
    try {
      final results = await Future.wait([
        _wsApi.getAll(),
        _attApi.getTodayAttendance(),
      ]);
      if (mounted) setState(() {
        _stations = results[0] as List<StationModel>;
        _checkedInEmployees = (results[1] as List<AttendanceRecord>)
            .where((r) => r.status == 'CHECKED_IN')
            .toList();
        _loadingData = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  void _startScan() {
    if (_selectedStationId == null) {
      setState(() => _error = 'Select a station first');
      return;
    }
    if (_selectedEmpId == null) {
      setState(() => _error = 'Select an employee first');
      return;
    }
    setState(() { _scanning = true; _error = null; _lastAssign = null; });
    _scanner = MobileScannerController();
  }

  void _stopScan() {
    _scanner?.dispose();
    _scanner = null;
    setState(() => _scanning = false);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || !code.startsWith('BND-')) return;
    _stopScan();
    setState(() => _processing = true);

    try {
      final res = await _jobApi.scanBundle(
        barcode: code,
        wsId: _selectedStationId!,
        empId: _selectedEmpId!,
        assignedBy: int.tryParse(widget.supervisorEmpId) ?? 0,
      );
      if (res.action == 'COMPLETE' && res.completedJob != null && mounted) {
        await JobCompleteSheet.show(context, res.completedJob!);
        setState(() { _lastAssign = null; _processing = false; });
      } else {
        setState(() { _lastAssign = res; _processing = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _processing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StationDropdown(
          stations: _stations,
          value: _selectedStationId,
          onChanged: (id) => setState(() { _selectedStationId = id; _lastAssign = null; }),
        ),
        const SizedBox(height: 12),
        _EmployeeDropdown(
          employees: _checkedInEmployees,
          value: _selectedEmpId,
          onChanged: (id) => setState(() { _selectedEmpId = id; _lastAssign = null; }),
          onRefresh: _loadDropdowns,
        ),
        const SizedBox(height: 16),
        if (_scanning) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 260,
              child: MobileScanner(controller: _scanner!, onDetect: _onDetect),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity,
              child: OutlinedButton(onPressed: _stopScan, child: const Text('Cancel'))),
        ] else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _processing ? null : _startScan,
              icon: _processing
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.qr_code_scanner),
              label: Text(_processing ? 'Processing...' : 'Scan Bundle QR'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(_error!),
        ],
        if (_lastAssign != null) ...[
          const SizedBox(height: 16),
          _AssignConfirmCard(_lastAssign!),
        ],
      ]),
    );
  }
}

class _StationDropdown extends StatelessWidget {
  final List<StationModel> stations;
  final int? value;
  final ValueChanged<int?> onChanged;
  const _StationDropdown({required this.stations, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Station',
          prefixIcon: const Icon(Icons.workspaces_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        items: stations.map((s) => DropdownMenuItem(
              value: s.wsId,
              child: Text(
                '${s.wsCode}${s.operation != null ? ' — ${s.operation!.opName}' : ''}',
                overflow: TextOverflow.ellipsis,
              ),
            )).toList(),
        onChanged: onChanged,
      );
}

class _EmployeeDropdown extends StatelessWidget {
  final List<AttendanceRecord> employees;
  final int? value;
  final ValueChanged<int?> onChanged;
  final VoidCallback onRefresh;
  const _EmployeeDropdown(
      {required this.employees, required this.value, required this.onChanged, required this.onRefresh});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: value,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Employee (Checked-in today)',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            hint: employees.isEmpty
                ? const Text('No checked-in employees')
                : const Text('Select employee'),
            items: employees.map((e) => DropdownMenuItem(
                  value: e.empId,
                  child: Text(e.empName, overflow: TextOverflow.ellipsis),
                )).toList(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceVariant,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ),
      ]);
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppTheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.error.withValues(alpha: 0.3))),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
        ]),
      );
}

class _AssignConfirmCard extends StatelessWidget {
  final ScanBundleResponse res;
  const _AssignConfirmCard(this.res);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.green.shade200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text('Job Assigned', style: AppTheme.titleMedium.copyWith(color: Colors.green.shade700)),
          ]),
          const SizedBox(height: 10),
          _Row('Station', res.wsCode),
          _Row('Operation', res.opName),
          _Row('Skill Grade', res.skillGrade),
          _Row('Bundle', res.barcode),
          _Row('Qty', '${res.bundleQty} pcs'),
          _Row('SAM', '${res.samValue.toStringAsFixed(2)} min/pc'),
          _Row('Est. Time', '${res.estMinutes.toStringAsFixed(1)} min'),
        ]),
      );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text('$label: ', style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant)),
          Expanded(child: Text(value,
              style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis)),
        ]),
      );
}
