import 'package:flutter/material.dart';
import '../../../../core/utils/api_error_helper.dart';
import '../../data/api/process_planner_api_service.dart';
import 'workflow_graph/workflow_node.dart';
import 'workflow_graph/horizontal_workflow_graph.dart';
import 'workflow_graph/workflow_graph_builder.dart';

/// Confirmation dialog for deleting an operation from a routing's flow.
/// Shows live preview of the resulting graph (with auto-bridged edges).
class DeleteOperationDialog extends StatefulWidget {
  final int routingId;
  final int operationId;
  final String operationName;
  final Map<String, dynamic> existingPlanData;

  const DeleteOperationDialog({
    super.key,
    required this.routingId,
    required this.operationId,
    required this.operationName,
    required this.existingPlanData,
  });

  @override
  State<DeleteOperationDialog> createState() => _DeleteOperationDialogState();
}

class _DeleteOperationDialogState extends State<DeleteOperationDialog> {
  final ProcessPlannerApiService _api = ProcessPlannerApiService();
  bool _autoBridge = true;
  bool _submitting = false;
  String? _error;

  /// Build preview nodes with the target op + its edges removed,
  /// plus auto-bridge edges if enabled.
  List<WorkflowNode> _previewNodes() {
    final ops = (widget.existingPlanData['operations'] as List<dynamic>? ?? [])
        .map<Map<String, dynamic>>((op) {
      final m = Map<String, dynamic>.from(op as Map);
      return {
        'operation_id': m['operationId'] ?? m['operation_id'] ?? 0,
        'name': m['name'] ?? '',
        'description': m['description'] ?? '',
        'sequence': m['sequence'] ?? 0,
        'stage_group': m['stageGroup'] ?? m['stage_group'] ?? 1,
        'operation_type': (m['operationType'] ?? m['operation_type'] ?? 'sequential')
            .toString()
            .toLowerCase(),
      };
    }).toList();

    final edges = (widget.existingPlanData['edges'] as List<dynamic>? ?? [])
        .map<Map<String, dynamic>>((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return {
        'from_operation_id': m['fromOperationId'] ?? m['from_operation_id'] ?? 0,
        'to_operation_id': m['toOperationId'] ?? m['to_operation_id'] ?? 0,
        'from_name': m['fromName'] ?? m['from_name'] ?? '',
        'to_name': m['toName'] ?? m['to_name'] ?? '',
        'edge_type': m['edgeType'] ?? m['edge_type'] ?? 'sequential',
      };
    }).toList();

    final preds = <int>[];
    final succs = <int>[];
    for (final e in edges) {
      if (e['to_operation_id'] == widget.operationId) {
        preds.add(e['from_operation_id'] as int);
      }
      if (e['from_operation_id'] == widget.operationId) {
        succs.add(e['to_operation_id'] as int);
      }
    }

    // Remove the op and its edges
    ops.removeWhere((o) => o['operation_id'] == widget.operationId);
    edges.removeWhere((e) =>
        e['from_operation_id'] == widget.operationId ||
        e['to_operation_id'] == widget.operationId);

    // Auto-bridge in preview (if enabled)
    if (_autoBridge) {
      final existingPairs = edges
          .map((e) => '${e['from_operation_id']}->${e['to_operation_id']}')
          .toSet();
      Map<int, String> nameMap = {};
      for (final o in ops) {
        nameMap[o['operation_id'] as int] = (o['name'] as String);
      }
      for (final p in preds) {
        for (final s in succs) {
          if (p == s) continue;
          final key = '$p->$s';
          if (existingPairs.contains(key)) continue;
          edges.add({
            'from_operation_id': p,
            'to_operation_id': s,
            'from_name': nameMap[p] ?? '',
            'to_name': nameMap[s] ?? '',
            'edge_type': 'sequential',
          });
          existingPairs.add(key);
        }
      }
    }

    return WorkflowGraphBuilder.buildNodes(
      operations: ops,
      edges: edges,
      routingId: widget.routingId,
    );
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _api.removeOperationFromRouting(
        routingId: widget.routingId,
        operationId: widget.operationId,
        autoBridge: _autoBridge,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiErrorHelper.getMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 700),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delete_forever, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Remove step from routing',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '"${widget.operationName}"',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _submitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        border: Border.all(color: Colors.amber.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.amber),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This only removes the step from this routing. The step itself stays in your master Operations list and other routings keep using it.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      value: _autoBridge,
                      onChanged: (v) => setState(() => _autoBridge = v),
                      title: const Text('Reconnect old neighbors automatically'),
                      subtitle: const Text(
                        'When ON, the steps that came before this one continue to the steps that came after. Recommended.',
                        style: TextStyle(fontSize: 12),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.preview, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('How the routing will look after removal',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: HorizontalWorkflowGraph(nodes: _previewNodes()),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _submitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.delete_forever),
                    label: Text(_submitting ? 'Removing...' : 'Remove from routing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
