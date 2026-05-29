import 'package:flutter/material.dart';
import '../../../../core/utils/api_error_helper.dart';
import '../../data/api/process_planner_api_service.dart';
import 'workflow_graph/workflow_node.dart';
import 'workflow_graph/horizontal_workflow_graph.dart';
import 'workflow_graph/workflow_graph_builder.dart';

/// Reconnect dialog: pick one of an operation's outgoing edges and redirect
/// it to a different existing operation in the same routing.
class ReconnectEdgeDialog extends StatefulWidget {
  final int routingId;
  final int fromOperationId;
  final String fromOperationName;
  final Map<String, dynamic> existingPlanData;

  const ReconnectEdgeDialog({
    super.key,
    required this.routingId,
    required this.fromOperationId,
    required this.fromOperationName,
    required this.existingPlanData,
  });

  @override
  State<ReconnectEdgeDialog> createState() => _ReconnectEdgeDialogState();
}

class _ReconnectEdgeDialogState extends State<ReconnectEdgeDialog> {
  final ProcessPlannerApiService _api = ProcessPlannerApiService();
  int? _selectedOldTo;
  int? _selectedNewTo;
  bool _submitting = false;
  String? _error;

  late List<Map<String, dynamic>> _outgoing;
  late List<Map<String, dynamic>> _candidatesNew;

  @override
  void initState() {
    super.initState();
    _outgoing = _resolveOutgoing();
    _candidatesNew = _resolveCandidates();
    if (_outgoing.length == 1) {
      _selectedOldTo = _outgoing.first['id'] as int?;
    }
  }

  List<Map<String, dynamic>> _resolveOutgoing() {
    final edges = (widget.existingPlanData['edges'] as List<dynamic>? ?? []);
    final out = <Map<String, dynamic>>[];
    for (final e in edges) {
      final m = Map<String, dynamic>.from(e as Map);
      final fromId = (m['fromOperationId'] ?? m['from_operation_id']) as int?;
      final toId = (m['toOperationId'] ?? m['to_operation_id']) as int?;
      if (fromId == widget.fromOperationId) {
        out.add({'id': toId, 'name': (m['toName'] ?? m['to_name'] ?? '').toString()});
      }
    }
    return out;
  }

  List<Map<String, dynamic>> _resolveCandidates() {
    final ops = (widget.existingPlanData['operations'] as List<dynamic>? ?? []);
    final out = <Map<String, dynamic>>[];
    for (final op in ops) {
      final m = Map<String, dynamic>.from(op as Map);
      final id = (m['operationId'] ?? m['operation_id']) as int?;
      if (id == null) continue;
      if (id == widget.fromOperationId) continue;
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

    if (_selectedOldTo != null && _selectedNewTo != null) {
      // Remove old edge, add new edge
      edges.removeWhere((e) =>
          e['from_operation_id'] == widget.fromOperationId &&
          e['to_operation_id'] == _selectedOldTo);
      // Avoid duplicate
      final exists = edges.any((e) =>
          e['from_operation_id'] == widget.fromOperationId &&
          e['to_operation_id'] == _selectedNewTo);
      if (!exists) {
        String newToName = '';
        for (final c in _candidatesNew) {
          if (c['id'] == _selectedNewTo) {
            newToName = (c['name'] ?? '').toString();
            break;
          }
        }
        edges.add({
          'from_operation_id': widget.fromOperationId,
          'to_operation_id': _selectedNewTo,
          'from_name': widget.fromOperationName,
          'to_name': newToName,
          'edge_type': 'sequential',
        });
      }
    }

    return WorkflowGraphBuilder.buildNodes(
      operations: ops,
      edges: edges,
      routingId: widget.routingId,
    );
  }

  Future<void> _submit() async {
    if (_selectedOldTo == null) {
      setState(() => _error = 'Pick which edge to reconnect');
      return;
    }
    if (_selectedNewTo == null) {
      setState(() => _error = 'Pick the new target');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _api.reconnectEdge(
        routingId: widget.routingId,
        fromOperationId: widget.fromOperationId,
        oldToOperationId: _selectedOldTo!,
        newToOperationId: _selectedNewTo!,
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
                color: Colors.purple,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_calls, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Change what comes next',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Text('After "${widget.fromOperationName}"',
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
                    if (_outgoing.isEmpty)
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
                                'This step has no next step set yet. Use "Add a step AFTER this one" to create one.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Text(
                        'Which next step do you want to change?',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 6),
                      ..._outgoing.map((e) {
                        final id = e['id'] as int?;
                        return RadioListTile<int>(
                          value: id ?? -1,
                          groupValue: _selectedOldTo ?? -1,
                          onChanged: (v) =>
                              setState(() => _selectedOldTo = v == -1 ? null : v),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${widget.fromOperationName}  →  ${e['name']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedNewTo,
                        decoration: const InputDecoration(
                          labelText: 'Point it to this step instead',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                        ),
                        isExpanded: true,
                        items: _candidatesNew
                            .where((c) => c['id'] != _selectedOldTo)
                            .map((c) {
                          return DropdownMenuItem<int>(
                            value: c['id'] as int?,
                            child:
                                Text((c['name'] ?? '').toString(), overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedNewTo = v),
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
                    onPressed: (_outgoing.isEmpty || _submitting)
                        ? null
                        : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.swap_calls),
                    label: Text(_submitting ? 'Updating...' : 'Update connection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
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
