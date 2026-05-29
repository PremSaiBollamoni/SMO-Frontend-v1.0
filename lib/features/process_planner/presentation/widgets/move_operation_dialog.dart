import 'package:flutter/material.dart';
import '../../../../core/utils/api_error_helper.dart';
import '../../data/api/process_planner_api_service.dart';
import 'workflow_graph/workflow_node.dart';
import 'workflow_graph/horizontal_workflow_graph.dart';
import 'workflow_graph/workflow_graph_builder.dart';

/// Dialog to move an operation to a new position in the routing.
/// Three modes: SPLIT_EDGE (After/Before another node), ADD_BRANCH (parallel),
/// or TERMINAL (detach completely so it becomes a terminal node).
class MoveOperationDialog extends StatefulWidget {
  final int routingId;
  final int operationId;
  final String operationName;
  final Map<String, dynamic> existingPlanData;

  const MoveOperationDialog({
    super.key,
    required this.routingId,
    required this.operationId,
    required this.operationName,
    required this.existingPlanData,
  });

  @override
  State<MoveOperationDialog> createState() => _MoveOperationDialogState();
}

class _MoveOperationDialogState extends State<MoveOperationDialog> {
  final ProcessPlannerApiService _api = ProcessPlannerApiService();

  String _mode = 'SPLIT_EDGE'; // SPLIT_EDGE / ADD_BRANCH / TERMINAL
  String _position = 'AFTER';
  int? _selectedAnchorId;
  int? _selectedOtherEnd;
  int? _selectedMergeTarget;
  bool _skipAutoBridge = false;

  bool _submitting = false;
  String? _error;

  late List<Map<String, dynamic>> _candidates; // ops eligible as anchor (not self)

  @override
  void initState() {
    super.initState();
    _candidates = _resolveCandidates();
  }

  List<Map<String, dynamic>> _resolveCandidates() {
    final ops = (widget.existingPlanData['operations'] as List<dynamic>? ?? []);
    final out = <Map<String, dynamic>>[];
    for (final op in ops) {
      final m = Map<String, dynamic>.from(op as Map);
      final id = (m['operationId'] ?? m['operation_id']) as int?;
      if (id == null || id == widget.operationId) continue;
      out.add({'id': id, 'name': (m['name'] ?? '').toString()});
    }
    return out;
  }

  /// Anchor's neighbors in the chosen direction (filtered for SPLIT_EDGE mode).
  List<Map<String, dynamic>> _anchorNeighbors() {
    if (_selectedAnchorId == null) return [];
    final edges = (widget.existingPlanData['edges'] as List<dynamic>? ?? []);
    final out = <Map<String, dynamic>>[];
    for (final e in edges) {
      final m = Map<String, dynamic>.from(e as Map);
      final fromId = (m['fromOperationId'] ?? m['from_operation_id']) as int?;
      final toId = (m['toOperationId'] ?? m['to_operation_id']) as int?;
      if (_position == 'AFTER' && fromId == _selectedAnchorId) {
        out.add({
          'id': toId,
          'name': (m['toName'] ?? m['to_name'] ?? '').toString(),
        });
      } else if (_position == 'BEFORE' && toId == _selectedAnchorId) {
        out.add({
          'id': fromId,
          'name': (m['fromName'] ?? m['from_name'] ?? '').toString(),
        });
      }
    }
    return out;
  }

  /// Build preview graph after the move.
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

    // Step A: detach the moving op (collect predecessors/successors)
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
    edges.removeWhere((e) =>
        e['from_operation_id'] == widget.operationId ||
        e['to_operation_id'] == widget.operationId);

    if (!_skipAutoBridge) {
      final pairs = edges
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
          if (pairs.contains(key)) continue;
          edges.add({
            'from_operation_id': p,
            'to_operation_id': s,
            'from_name': nameMap[p] ?? '',
            'to_name': nameMap[s] ?? '',
            'edge_type': 'sequential',
          });
          pairs.add(key);
        }
      }
    }

    if (_mode == 'TERMINAL') {
      // Op stays in graph, no edges → terminal
      return WorkflowGraphBuilder.buildNodes(
        operations: ops,
        edges: edges,
        routingId: widget.routingId,
      );
    }

    if (_selectedAnchorId == null) {
      // Show graph with just the detach for now
      return WorkflowGraphBuilder.buildNodes(
        operations: ops,
        edges: edges,
        routingId: widget.routingId,
      );
    }

    // Step B: re-insert
    if (_mode == 'ADD_BRANCH') {
      // anchor -> moving op
      edges.add({
        'from_operation_id': _selectedAnchorId,
        'to_operation_id': widget.operationId,
        'from_name': _opNameById(_selectedAnchorId!),
        'to_name': widget.operationName,
        'edge_type': 'parallel',
      });
      if (_selectedMergeTarget != null) {
        edges.add({
          'from_operation_id': widget.operationId,
          'to_operation_id': _selectedMergeTarget,
          'from_name': widget.operationName,
          'to_name': _opNameById(_selectedMergeTarget!),
          'edge_type': 'parallel',
        });
      }
    } else {
      // SPLIT_EDGE
      final otherEnd = _selectedOtherEnd;
      if (_position == 'AFTER') {
        if (otherEnd != null) {
          edges.removeWhere((e) =>
              e['from_operation_id'] == _selectedAnchorId &&
              e['to_operation_id'] == otherEnd);
          edges.add({
            'from_operation_id': _selectedAnchorId,
            'to_operation_id': widget.operationId,
            'from_name': _opNameById(_selectedAnchorId!),
            'to_name': widget.operationName,
            'edge_type': 'sequential',
          });
          edges.add({
            'from_operation_id': widget.operationId,
            'to_operation_id': otherEnd,
            'from_name': widget.operationName,
            'to_name': _opNameById(otherEnd),
            'edge_type': 'sequential',
          });
        } else {
          edges.add({
            'from_operation_id': _selectedAnchorId,
            'to_operation_id': widget.operationId,
            'from_name': _opNameById(_selectedAnchorId!),
            'to_name': widget.operationName,
            'edge_type': 'sequential',
          });
        }
      } else {
        if (otherEnd != null) {
          edges.removeWhere((e) =>
              e['from_operation_id'] == otherEnd &&
              e['to_operation_id'] == _selectedAnchorId);
          edges.add({
            'from_operation_id': otherEnd,
            'to_operation_id': widget.operationId,
            'from_name': _opNameById(otherEnd),
            'to_name': widget.operationName,
            'edge_type': 'sequential',
          });
          edges.add({
            'from_operation_id': widget.operationId,
            'to_operation_id': _selectedAnchorId,
            'from_name': widget.operationName,
            'to_name': _opNameById(_selectedAnchorId!),
            'edge_type': 'sequential',
          });
        } else {
          edges.add({
            'from_operation_id': widget.operationId,
            'to_operation_id': _selectedAnchorId,
            'from_name': widget.operationName,
            'to_name': _opNameById(_selectedAnchorId!),
            'edge_type': 'sequential',
          });
        }
      }
    }

    return WorkflowGraphBuilder.buildNodes(
      operations: ops,
      edges: edges,
      routingId: widget.routingId,
    );
  }

  String _opNameById(int id) {
    final ops = (widget.existingPlanData['operations'] as List<dynamic>? ?? []);
    for (final op in ops) {
      final m = Map<String, dynamic>.from(op as Map);
      final opId = (m['operationId'] ?? m['operation_id']) as int?;
      if (opId == id) return (m['name'] ?? '').toString();
    }
    return '';
  }

  String _modeHint() {
    switch (_mode) {
      case 'ADD_BRANCH':
        return '• A new parallel path will start from the chosen step.';
      case 'TERMINAL':
        return '• The step stays in the routing but is detached from the flow.';
      case 'SPLIT_EDGE':
      default:
        return '• The step will be placed inside an existing path.';
    }
  }

  Future<void> _submit() async {
    if (_mode != 'TERMINAL' && _selectedAnchorId == null) {
      setState(() => _error = 'Pick an anchor operation');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _api.moveOperation(
        routingId: widget.routingId,
        operationId: widget.operationId,
        mode: _mode,
        position: _mode == 'TERMINAL' ? null : _position,
        anchorOperationId: _mode == 'TERMINAL' ? null : _selectedAnchorId,
        otherEndOperationId: _mode == 'SPLIT_EDGE' ? _selectedOtherEnd : null,
        mergeTargetOperationId:
            _mode == 'ADD_BRANCH' ? _selectedMergeTarget : null,
        skipAutoBridge: _skipAutoBridge,
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
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.brown,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.move_up, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Move Step',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text('"${widget.operationName}"',
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
                    Text(
                      'How should this step be repositioned?',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'SPLIT_EDGE',
                          label: Text('Place between two steps'),
                          icon: Icon(Icons.call_split),
                        ),
                        ButtonSegment<String>(
                          value: 'ADD_BRANCH',
                          label: Text('Run alongside (parallel)'),
                          icon: Icon(Icons.alt_route),
                        ),
                        ButtonSegment<String>(
                          value: 'TERMINAL',
                          label: Text('Detach (no connections)'),
                          icon: Icon(Icons.flag),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (s) {
                        setState(() {
                          _mode = s.first;
                          _selectedOtherEnd = null;
                          _selectedMergeTarget = null;
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _modeHint(),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    if (_mode != 'TERMINAL') _buildAnchorPicker(),
                    if (_mode == 'SPLIT_EDGE') _buildSplitEdgeDetails(),
                    if (_mode == 'ADD_BRANCH') _buildAddBranchDetails(),
                    if (_mode == 'TERMINAL') _buildTerminalNote(),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      value: !_skipAutoBridge,
                      onChanged: (v) => setState(() => _skipAutoBridge = !v),
                      title: const Text('Reconnect old neighbors automatically'),
                      subtitle: const Text(
                        'When ON, the steps that came before this step will continue to the steps that came after — so the flow stays unbroken.',
                        style: TextStyle(fontSize: 12),
                      ),
                      contentPadding: EdgeInsets.zero,
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
                        : const Icon(Icons.move_up),
                    label: Text(_submitting ? 'Moving...' : 'Move'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
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

  Widget _buildAnchorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_mode == 'SPLIT_EDGE')
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'AFTER',
                      label: Text('Place AFTER the chosen step'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                    ButtonSegment<String>(
                      value: 'BEFORE',
                      label: Text('Place BEFORE the chosen step'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                  ],
                  selected: {_position},
                  onSelectionChanged: (s) {
                    setState(() {
                      _position = s.first;
                      _selectedOtherEnd = null;
                    });
                  },
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _selectedAnchorId,
          decoration: const InputDecoration(
            labelText: 'Reference step *',
            hintText: 'Pick the step to position relative to',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.anchor),
          ),
          isExpanded: true,
          items: _candidates.map((c) {
            return DropdownMenuItem<int>(
              value: c['id'] as int?,
              child: Text((c['name'] ?? '').toString(),
                  overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (v) {
            setState(() {
              _selectedAnchorId = v;
              _selectedOtherEnd = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSplitEdgeDetails() {
    if (_selectedAnchorId == null) return const SizedBox.shrink();
    final neighbors = _anchorNeighbors();
    if (neighbors.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.all(10),
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
                  'No next/previous step exists on that side. The step will simply be added at that end.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (neighbors.length == 1) {
      _selectedOtherEnd ??= neighbors.first['id'] as int?;
      final n = neighbors.first;
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.brown.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.brown.shade200),
          ),
          child: Text(
            _position == 'AFTER'
                ? 'Will be placed between the reference step and "${n['name']}"'
                : 'Will be placed between "${n['name']}" and the reference step',
            style: TextStyle(fontSize: 12, color: Colors.brown.shade900),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The reference step is part of ${neighbors.length} different paths. Which one should this step join?',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          ...neighbors.map((n) {
            final id = n['id'] as int?;
            return RadioListTile<int>(
              value: id ?? -1,
              groupValue: _selectedOtherEnd ?? -1,
              onChanged: (v) =>
                  setState(() => _selectedOtherEnd = v == -1 ? null : v),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                _position == 'AFTER'
                    ? 'Reference step  →  ${n['name']}'
                    : '${n['name']}  →  Reference step',
                style: const TextStyle(fontSize: 13),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAddBranchDetails() {
    if (_selectedAnchorId == null) return const SizedBox.shrink();
    final mergeOptions = _candidates
        .where((c) => c['id'] != _selectedAnchorId)
        .toList();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<int?>(
        value: _selectedMergeTarget,
        decoration: const InputDecoration(
          labelText: 'Where should the new path lead to? (optional)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.merge_type),
        ),
        isExpanded: true,
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('End here (nothing comes after)',
                overflow: TextOverflow.ellipsis),
          ),
          ...mergeOptions.map((c) {
            return DropdownMenuItem<int?>(
              value: c['id'] as int?,
              child: Text('Continue to: ${c['name']}',
                  overflow: TextOverflow.ellipsis),
            );
          }),
        ],
        onChanged: (v) => setState(() => _selectedMergeTarget = v),
      ),
    );
  }

  Widget _buildTerminalNote() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.brown.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.flag, color: Colors.brown.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'The step is removed from the flow but stays in the routing. Use this to take a step out of the path temporarily, or to set it aside as a final/terminal step.',
              style: TextStyle(fontSize: 12, color: Colors.brown.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
