import 'package:flutter/material.dart';
import '../../data/api/attendance_api_service.dart';
import '../../data/models/attendance_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/api_error_helper.dart';
import '../../../hr/data/api/shift_api_service.dart';
import '../../../hr/data/models/shift_models.dart';
import '../widgets/scan_tab.dart';
import '../widgets/log_tab.dart';

class AttendanceScreen extends StatefulWidget {
  final String supervisorEmpId;

  const AttendanceScreen({super.key, required this.supervisorEmpId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final AttendanceApiService _api = AttendanceApiService();
  final ShiftApiService _shiftApi = ShiftApiService();

  List<AttendanceRecord> _todayRecords = [];
  List<EmployeeOption> _employees = [];
  List<ShiftTemplateModel> _shifts = [];
  bool _loading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getTodayAttendance(),
        _api.getEmployees(),
        _shiftApi.getActiveShifts(),
      ]);
      if (mounted) {
        setState(() {
          _todayRecords = results[0] as List<AttendanceRecord>;
          _employees = results[1] as List<EmployeeOption>;
          _shifts = results[2] as List<ShiftTemplateModel>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _freeAllQrs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End of Day'),
        content: const Text('Free all temp QR assignments for today? Do this at end of shift only.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Free All QRs'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      final count = await _api.freeAllQrs();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Done')]),
          content: Text('$count QR mapping(s) freed.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(ApiErrorHelper.getMessage(e)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    }
  }

  List<AttendanceRecord> get _activeRecords {
    return _todayRecords.where((r) => r.status == 'CHECKED_IN').toList();
  }

  List<AttendanceRecord> get _historyRecords {
    return _todayRecords.where((r) => r.status == 'CHECKED_OUT').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.primary,
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabs,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Active'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.lock_reset, color: Colors.white),
                tooltip: 'Free All QRs',
                onPressed: _freeAllQrs,
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh',
                onPressed: _loadData,
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              LogTab(records: _todayRecords, loading: _loading, onRefresh: _loadData),
              LogTab(records: _activeRecords, loading: _loading, onRefresh: _loadData),
              LogTab(records: _historyRecords, loading: _loading, onRefresh: _loadData),
            ],
          ),
        ),
      ],
    );
  }
}
