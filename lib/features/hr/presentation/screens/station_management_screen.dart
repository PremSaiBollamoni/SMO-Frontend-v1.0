import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/api/workstation_api_service.dart';
import '../../data/models/station_models.dart';
import '../widgets/create_station_dialog.dart';
import '../widgets/station_card.dart';

class StationManagementScreen extends StatefulWidget {
  const StationManagementScreen({super.key});

  @override
  State<StationManagementScreen> createState() => _StationManagementScreenState();
}

class _StationManagementScreenState extends State<StationManagementScreen> {
  final _api = WorkstationApiService();
  List<StationModel> _stations = [];
  List<OperationModel> _operations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([_api.getAll(), _api.getOperations()]);
      if (mounted) setState(() {
        _stations = results[0] as List<StationModel>;
        _operations = results[1] as List<OperationModel>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _create() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => CreateStationDialog(operations: _operations),
    );
    if (ok == true) _load();
  }

  Future<void> _edit(StationModel station, String wsCode, String? machineCode) async {
    try {
      await _api.update(station.wsId, wsCode: wsCode, machineCode: machineCode);
      _load();
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _assignOperation(StationModel station, int opId) async {
    try {
      await _api.assignOperation(station.wsId, opId);
      _load();
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _delete(StationModel station) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Station'),
        content: Text('Delete ${station.wsCode}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.delete(station.wsId);
        _load();
      } catch (e) {
        if (mounted) _showError(e.toString());
      }
    }
  }

  void _showError(String msg) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(msg),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Stations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Station'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : _stations.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.workspaces_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No stations yet', style: AppTheme.titleMedium.copyWith(color: AppTheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _create,
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Station'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                      ),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _stations.length,
                        itemBuilder: (_, i) => StationCard(
                          station: _stations[i],
                          operations: _operations,
                          onAssignOperation: (opId) => _assignOperation(_stations[i], opId),
                          onDelete: () => _delete(_stations[i]),
                          onEdit: (wsCode, mc) => _edit(_stations[i], wsCode, mc),
                        ),
                      ),
                    ),
    );
  }
}
