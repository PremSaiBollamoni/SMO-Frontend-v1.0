import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/api/process_planner_api_service.dart';
import '../controller/process_planner_controller.dart';
import 'workflow_graph/workflow_node.dart';
import 'workflow_graph/horizontal_workflow_graph.dart';
import 'workflow_graph/workflow_graph_builder.dart';
import 'insert_operation_dialog.dart';
import 'rename_operation_dialog.dart';
import 'delete_operation_dialog.dart';
import 'reconnect_edge_dialog.dart';
import 'move_operation_dialog.dart';
import 'connect_to_step_dialog.dart';

/// Edit Routing View
/// Lets the planner pick an existing routing, see its graph (using the same
/// renderer as the rest of the app), tap any node, and choose to:
///   - Insert an operation BEFORE the tapped node
///   - Insert an operation AFTER the tapped node
///   - Rename the tapped node (scoped to this routing only)
class EditRoutingView extends StatefulWidget {
  const EditRoutingView({super.key});

  @override
  State<EditRoutingView> createState() => _EditRoutingViewState();
}

class _EditRoutingViewState extends State<EditRoutingView> {
  final ProcessPlannerApiService _api = ProcessPlannerApiService();

  int? _selectedRoutingId;
  Map<String, dynamic>? _planData; // raw response from /api/processplan/{id}
  bool _loadingPlan = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    // Make sure routings list is available
    final controller = Get.find<ProcessPlannerController>();
    if (controller.routings.isEmpty) {
      controller.fetchRoutings();
    }
  }

  Future<void> _loadPlan(int routingId) async {
    setState(() {
      _loadingPlan = true;
      _loadError = null;
      _planData = null;
    });
    try {
      final data = await _api.getProcessPlan(routingId);
      if (!mounted) return;
      setState(() {
        _planData = data;
        _loadingPlan = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loadingPlan = false;
      });
    }
  }

  /// Build WorkflowNode list from current plan data using the existing builder.
  List<WorkflowNode> _buildNodes() {
    if (_planData == null) return [];
    final routingId = _planData!['routingId'] as int? ?? _selectedRoutingId ?? 0;
    final operationsRaw = (_planData!['operations'] as List<dynamic>? ?? []);
    final edgesRaw = (_planData!['edges'] as List<dynamic>? ?? []);

    final operations = operationsRaw.map<Map<String, dynamic>>((op) {
      final m = Map<String, dynamic>.from(op as Map);
      return {
        'operation_id': m['operationId'] ?? m['operation_id'] ?? 0,
        'name': m['name'] ?? '',
        'description': m['description'] ?? '',
        'sequence': m['sequence'] ?? 0,
        'stage_group': m['stageGroup'] ?? m['stage_group'] ?? 1,
        'operation_type':
            (m['operationType'] ?? m['operation_type'] ?? 'sequential')
                .toString()
                .toLowerCase(),
      };
    }).toList();

    final edges = edgesRaw.map<Map<String, dynamic>>((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return {
        'from_operation_id': m['fromOperationId'] ?? m['from_operation_id'] ?? 0,
        'to_operation_id': m['toOperationId'] ?? m['to_operation_id'] ?? 0,
        'from_name': m['fromName'] ?? m['from_name'] ?? '',
        'to_name': m['toName'] ?? m['to_name'] ?? '',
        'edge_type': m['edgeType'] ?? m['edge_type'] ?? 'sequential',
      };
    }).toList();

    return WorkflowGraphBuilder.buildNodes(
      operations: operations,
      edges: edges,
      routingId: routingId,
    );
  }

  /// Resolve the operations adjacent (in & out) to a tapped node so the
  /// dialogs can show "Will be inserted between X and Y" hints.
  Map<String, dynamic> _adjacent(int operationId) {
    if (_planData == null) {
      return {'before': <Map<String, dynamic>>[], 'after': <Map<String, dynamic>>[]};
    }
    final edgesRaw = (_planData!['edges'] as List<dynamic>? ?? []);
    final before = <Map<String, dynamic>>[];
    final after = <Map<String, dynamic>>[];
    for (final e in edgesRaw) {
      final m = Map<String, dynamic>.from(e as Map);
      final fromId = (m['fromOperationId'] ?? m['from_operation_id']) as int?;
      final toId = (m['toOperationId'] ?? m['to_operation_id']) as int?;
      final fromName = (m['fromName'] ?? m['from_name'] ?? '').toString();
      final toName = (m['toName'] ?? m['to_name'] ?? '').toString();
      if (toId == operationId) {
        before.add({'id': fromId, 'name': fromName});
      }
      if (fromId == operationId) {
        after.add({'id': toId, 'name': toName});
      }
    }
    return {'before': before, 'after': after};
  }

  void _onNodeTap(int routingId, int operationId, String operationName) {
    final adj = _adjacent(operationId);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  operationName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Operation #$operationId',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 16),
                _ActionTile(
                  icon: Icons.arrow_upward,
                  color: Colors.indigo,
                  title: 'Add a step BEFORE this one',
                  subtitle: (adj['before'] as List).isEmpty
                      ? 'This is a starting step (nothing comes before it yet)'
                      : 'New step will go between '
                          '${(adj['before'] as List).map((m) => m['name']).join(', ')} and $operationName',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showInsertDialog(
                        position: 'BEFORE',
                        anchorOperationId: operationId,
                        anchorName: operationName);
                  },
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.arrow_downward,
                  color: Colors.teal,
                  title: 'Add a step AFTER this one',
                  subtitle: (adj['after'] as List).isEmpty
                      ? 'This is an end step (nothing comes after it yet)'
                      : 'New step will go between $operationName and '
                          '${(adj['after'] as List).map((m) => m['name']).join(', ')}',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showInsertDialog(
                        position: 'AFTER',
                        anchorOperationId: operationId,
                        anchorName: operationName);
                  },
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.swap_calls,
                  color: Colors.purple,
                  title: 'Change what comes next',
                  subtitle: (adj['after'] as List).isEmpty
                      ? 'This step has no next step set yet'
                      : 'Pick one of this step\'s outgoing connections and point it to a different step',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReconnectDialog(operationId, operationName);
                  },
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.timeline,
                  color: Colors.cyan,
                  title: 'Connect to another step',
                  subtitle:
                      'Add a new arrow from this step to any other step in the routing',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showConnectDialog(operationId, operationName);
                  },
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.move_up,
                  color: Colors.brown,
                  title: 'Move this step',
                  subtitle: 'Pick it up and place it somewhere else in the routing',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showMoveDialog(operationId, operationName);
                  },
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.edit,
                  color: Colors.deepOrange,
                  title: 'Edit name & description',
                  subtitle: 'Affects only this routing — other routings keep the original',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showRenameDialog(operationId, operationName);
                  },
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.delete_forever,
                  color: Colors.red,
                  title: 'Remove this step from the routing',
                  subtitle: 'Takes it out of this routing\'s flow. Old neighbors are reconnected automatically.',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDeleteDialog(operationId, operationName);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showReconnectDialog(int operationId, String operationName) async {
    if (_selectedRoutingId == null) return;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ReconnectEdgeDialog(
        routingId: _selectedRoutingId!,
        fromOperationId: operationId,
        fromOperationName: operationName,
        existingPlanData: _planData!,
      ),
    );
    if (result == true && mounted) {
      await _loadPlan(_selectedRoutingId!);
    }
  }

  Future<void> _showConnectDialog(int operationId, String operationName) async {
    if (_selectedRoutingId == null) return;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConnectToStepDialog(
        routingId: _selectedRoutingId!,
        fromOperationId: operationId,
        fromOperationName: operationName,
        existingPlanData: _planData!,
      ),
    );
    if (result == true && mounted) {
      await _loadPlan(_selectedRoutingId!);
    }
  }

  Future<void> _showMoveDialog(int operationId, String operationName) async {
    if (_selectedRoutingId == null) return;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MoveOperationDialog(
        routingId: _selectedRoutingId!,
        operationId: operationId,
        operationName: operationName,
        existingPlanData: _planData!,
      ),
    );
    if (result == true && mounted) {
      await _loadPlan(_selectedRoutingId!);
    }
  }

  Future<void> _showDeleteDialog(int operationId, String operationName) async {
    if (_selectedRoutingId == null) return;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DeleteOperationDialog(
        routingId: _selectedRoutingId!,
        operationId: operationId,
        operationName: operationName,
        existingPlanData: _planData!,
      ),
    );
    if (result == true && mounted) {
      await _loadPlan(_selectedRoutingId!);
    }
  }

  Future<void> _showInsertDialog({
    required String position,
    required int anchorOperationId,
    required String anchorName,
  }) async {
    if (_selectedRoutingId == null) return;
    final adj = _adjacent(anchorOperationId);
    // Pre-select first neighbor only if exactly one exists; the dialog
    // handles multi-branch selection on its own.
    int? candidateOtherEnd;
    if (position == 'AFTER') {
      final after = adj['after'] as List;
      if (after.length == 1) candidateOtherEnd = after.first['id'] as int?;
    } else {
      final before = adj['before'] as List;
      if (before.length == 1) candidateOtherEnd = before.first['id'] as int?;
    }

    final controller = Get.find<ProcessPlannerController>();
    if (controller.operations.isEmpty) {
      await controller.fetchOperations();
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => InsertOperationDialog(
        routingId: _selectedRoutingId!,
        position: position,
        anchorOperationId: anchorOperationId,
        anchorOperationName: anchorName,
        otherEndOperationId: candidateOtherEnd,
        existingPlanData: _planData!,
      ),
    );

    if (result == true && mounted) {
      await _loadPlan(_selectedRoutingId!);
    }
  }

  Future<void> _showRenameDialog(int operationId, String currentName) async {
    if (_selectedRoutingId == null) return;
    // Pull current description from the loaded plan so the dialog can prefill it
    String currentDescription = '';
    if (_planData != null) {
      final ops = (_planData!['operations'] as List<dynamic>? ?? []);
      for (final op in ops) {
        final m = Map<String, dynamic>.from(op as Map);
        final id = (m['operationId'] ?? m['operation_id']) as int?;
        if (id == operationId) {
          currentDescription = (m['description'] ?? '').toString();
          break;
        }
      }
    }
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RenameOperationDialog(
        routingId: _selectedRoutingId!,
        operationId: operationId,
        currentName: currentName,
        currentDescription: currentDescription,
      ),
    );
    if (result == true && mounted) {
      await _loadPlan(_selectedRoutingId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProcessPlannerController>();

    return Scaffold(
      body: Column(
        children: [
          // Routing picker
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              if (controller.routings.isEmpty && controller.loadingRoutings.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.routings.isEmpty) {
                return _emptyState();
              }
              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedRoutingId,
                      decoration: const InputDecoration(
                        labelText: 'Select Routing',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.route),
                      ),
                      isExpanded: true,
                      items: controller.routings.map((r) {
                        return DropdownMenuItem<int>(
                          value: r.routingId,
                          child: Text('Routing #${r.routingId} (Product ${r.productId})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedRoutingId = value);
                        _loadPlan(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _selectedRoutingId == null
                        ? null
                        : () => _loadPlan(_selectedRoutingId!),
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reload graph',
                  ),
                ],
              );
            }),
          ),

          // Helper text
          if (_selectedRoutingId != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app, size: 18, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap any node to insert a step before/after it, or rename it.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Graph area
          Expanded(child: _buildGraphArea()),
        ],
      ),
    );
  }

  Widget _buildGraphArea() {
    if (_selectedRoutingId == null) {
      return _selectRoutingPrompt();
    }
    if (_loadingPlan) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to load routing graph'),
              const SizedBox(height: 4),
              Text(
                _loadError!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadPlan(_selectedRoutingId!),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final nodes = _buildNodes();
    if (nodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_tree_outlined,
                  color: Colors.grey.shade400, size: 56),
              const SizedBox(height: 12),
              Text(
                'No operations in this routing yet',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                'Use the Routing Steps tab to add the first operation',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: HorizontalWorkflowGraph(
          nodes: nodes,
          onNodeTap: _onNodeTap,
        ),
      ),
    );
  }

  Widget _selectRoutingPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_upward, color: Colors.grey.shade400, size: 56),
            const SizedBox(height: 12),
            Text(
              'Select a routing above to view and edit its graph',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No routings yet. Create a routing first in the Routings tab.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
