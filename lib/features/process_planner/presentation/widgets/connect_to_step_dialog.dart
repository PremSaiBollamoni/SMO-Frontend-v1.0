import 'package:flutter/material.dart';
import '../../../../core/utils/api_error_helper.dart';
import '../../data/api/process_planner_api_service.dart';
import 'workflow_graph/workflow_node.dart';
import 'workflow_graph/horizontal_workflow_graph.dart';
import 'workflow_graph/workflow_graph_builder.dart';

/// Dialog to draw a new connection from a chosen "source" step to any other
/// existing step in the same routing. Useful when you have two disconnected
/// pieces of the graph (or a step that should also feed into another step).
class ConnectToStepDialog extends StatefulWidget {
  final int routingId;
  final int fromOperationId;
  final String fromOperationName;
  final Map<String, dynamic> existingPlanData;

  const ConnectToStepDialog({
    super.key,
    required this.routingId,
    required this.fromOperationId,
    required this.fromOperationName,
    required this.existingPlanData,
  });

  @override
  State<ConnectToStepDialog> createState() => _ConnectToStepDialogState();
}

class _ConnectToStepDialogState extends State<ConnectToStepDialog> {
  final ProcessPlannerApiService _api = ProcessPlannerApiService();
  int? _selectedTargetId;
  bool _submitting = false;
  String? _error;

  late List<Map<String, dynamic>> _candidates;

  @override
  void initState() {
    super.initState();
    _candidates = _resolveCandidates();
  }

  /// Candidates = every other step in the routing that doesn't already have
  /// an incoming edge from this source.
  List<Map<String, dynamic>> _resolveCandidates() {
    final ops = (widget.existingPlanData['operations'] as List<dynamic>? ?? []);
    final edges = (widget.existingPlanData['edges'] as List<dynamic>? ?? []);

    final alreadyConnected = <int>{};
    for (final e in edges) {
      final m = Map<String, dynamic>.from(e as Map);
      final fromId = (m['fromOperationId'] ?? m['from_operation_id']) as int?;
      final toId = (m['toOperationId'] ?? m['to_operation_id']) as int?;
      if (fromId == widget.fromOperationId && toId != null) {
        alreadyConnected.add(toId);
      }
    }

    final out = <Map<String, dynamic>>[];
    for (final op in ops) {
      final m = Map<String, dynamic>.from(op as Map);
      final id = (m['operationId'] ?? m['operation_id']) as int?;
      if (id == null) continue;
      if (id == widget.fromOperationId) continue;
      if (alreadyConnected.contains(id)) continue;
      out.add({'id': id, 'name': (m['name'] ?? '').toString()});
    }
    return out;
  }

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

    if (_selectedTargetId != null) {
      String targetName = '';
      for (final c in _candidates) {
        if (c['id'] == _selectedTargetId) {
          targetName = (c['name'] ?? '').toString();
          break;
        }
      }
      edges.add({
        'from_operation_id': widget.fromOperationId,
        'to_operation_id': _selectedTargetId,
        'from_name': widget.fromOperationName,
        'to_name': targetName,
        'edge_type': 'sequential',
      });
    }

    return WorkflowGraphBuilder.buildNodes(
      operations: ops,
      edges: edges,
      routingId: widget.routingId,
    );
  }

  Future<void> _submit() async {
    if (_selectedTargetId == null) {
      setState(() => _error = 'Pick a step to connect to');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _api.addEdge(
        routingId: widget.routingId,
        fromOperationId: widget.fromOperationId,
        toOperationId: _selectedTargetId!,
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
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.cyan,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timeline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connect to another step',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Text('From "${widget.fromOperationName}"',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.cyan.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.cyan.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.cyan.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This adds a new arrow from "${widget.fromOperationName}" to the step you pick. Existing arrows stay as-is.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.cyan.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_candidates.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'There are no other steps left to connect to. This step is already connected to every other step.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Text(
                        'Which step should this connect to?',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: _selectedTargetId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                        ),
                        isExpanded: true,
                        items: _candidates.map((c) {
                          return DropdownMenuItem<int>(
                            value: c['id'] as int?,
                            child: Text(
                              (c['name'] ?? '').toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedTargetId = v),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.preview, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('How the routing will look',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 240,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child:
                            HorizontalWorkflowGraph(nodes: _previewNodes()),
                      ),
                    ],
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
                    onPressed: _candidates.isEmpty || _submitting
                        ? null
                        : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.timeline),
                    label: Text(_submitting ? 'Connecting...' : 'Add connection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
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
