import 'package:flutter/material.dart';
import '../../../../core/utils/api_error_helper.dart';
import 'package:get/get.dart';
import '../../data/api/process_planner_api_service.dart';
import '../controller/process_planner_controller.dart';
import 'workflow_graph/workflow_node.dart';
import 'workflow_graph/horizontal_workflow_graph.dart';
import 'workflow_graph/workflow_graph_builder.dart';

/// Insert Operation Dialog with two modes:
///  1) SPLIT_EDGE — insert between anchor and one of its neighbors
///                  (lets user pick a branch when anchor has multiple).
///  2) ADD_BRANCH — add a new parallel branch from the anchor (only enabled
///                  when position=AFTER, since it adds a new outgoing edge).
class InsertOperationDialog extends StatefulWidget {
  final int routingId;
  final String position; // 'AFTER' or 'BEFORE'
  final int anchorOperationId;
  final String anchorOperationName;

  /// Pre-selected other end of the edge (when split mode and unambiguous).
  /// Ignored if anchor has multiple branches (user picks one in the dialog).
  final int? otherEndOperationId;

  /// Current plan data — used to seed the preview graph and find branches.
  final Map<String, dynamic> existingPlanData;

  const InsertOperationDialog({
    super.key,
    required this.routingId,
    required this.position,
    required this.anchorOperationId,
    required this.anchorOperationName,
    required this.otherEndOperationId,
    required this.existingPlanData,
  });

  @override
  State<InsertOperationDialog> createState() => _InsertOperationDialogState();
}

class _InsertOperationDialogState extends State<InsertOperationDialog> {
  final ProcessPlannerApiService _api = ProcessPlannerApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _stdTimeController = TextEditingController(text: '60');
  final _stageGroupController = TextEditingController(text: '1');

  // Mode: 'SPLIT_EDGE' or 'ADD_BRANCH'
  String _mode = 'SPLIT_EDGE';

  // Existing-vs-new operation
  bool _useExisting = false;
  int? _selectedExistingOpId;
  String _operationType = 'SEQUENTIAL';

  // For SPLIT_EDGE mode when multiple branches exist on the anchor:
  // user picks which branch (which neighbor) to split. Initialized below.
  int? _selectedBranchOtherEndOpId;

  // For ADD_BRANCH mode (terminal node or join existing merge point)
  int? _addBranchMergeTargetOpId;

  bool _submitting = false;
  String? _submitError;

  late List<Map<String, dynamic>> _branchNeighbors; // adjacent ops in 'position' direction

  @override
  void initState() {
    super.initState();
    _branchNeighbors = _resolveBranchNeighbors();
    if (_branchNeighbors.isNotEmpty) {
      _selectedBranchOtherEndOpId = widget.otherEndOperationId ??
          _branchNeighbors.first['id'] as int?;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _stdTimeController.dispose();
    _stageGroupController.dispose();
    super.dispose();
  }

  /// Find all neighbors on the relevant side of the anchor.
  /// AFTER → outgoing edges (downstream successors)
  /// BEFORE → incoming edges (upstream predecessors)
  List<Map<String, dynamic>> _resolveBranchNeighbors() {
    final edgesRaw = (widget.existingPlanData['edges'] as List<dynamic>? ?? []);
    final out = <Map<String, dynamic>>[];
    for (final e in edgesRaw) {
      final m = Map<String, dynamic>.from(e as Map);
      final fromId = (m['fromOperationId'] ?? m['from_operation_id']) as int?;
      final toId = (m['toOperationId'] ?? m['to_operation_id']) as int?;
      final fromName = (m['fromName'] ?? m['from_name'] ?? '').toString();
      final toName = (m['toName'] ?? m['to_name'] ?? '').toString();
      if (widget.position == 'AFTER' && fromId == widget.anchorOperationId) {
        out.add({'id': toId, 'name': toName});
      } else if (widget.position == 'BEFORE' && toId == widget.anchorOperationId) {
        out.add({'id': fromId, 'name': fromName});
      }
    }
    return out;
  }

  /// Build preview graph showing the proposed change.
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

    final maxOpId = ops.fold<int>(0, (m, o) => (o['operation_id'] as int) > m ? (o['operation_id'] as int) : m);
    const previewId = -999;
    final newName = _previewName();

    ops.add({
      'operation_id': previewId,
      'name': newName,
      'description': _descController.text,
      'sequence': maxOpId + 1,
      'stage_group': int.tryParse(_stageGroupController.text) ?? 1,
      'operation_type': _operationType.toLowerCase(),
    });

    if (_mode == 'SPLIT_EDGE') {
      _applySplitEdgePreview(edges, previewId, newName);
    } else {
      _applyAddBranchPreview(edges, previewId, newName);
    }

    return WorkflowGraphBuilder.buildNodes(
      operations: ops,
      edges: edges,
      routingId: widget.routingId,
    );
  }

  void _applySplitEdgePreview(List<Map<String, dynamic>> edges, int previewId, String newName) {
    final otherEnd = _selectedBranchOtherEndOpId;
    if (widget.position == 'AFTER') {
      if (otherEnd != null) {
        edges.removeWhere((e) =>
            e['from_operation_id'] == widget.anchorOperationId &&
            e['to_operation_id'] == otherEnd);
        edges.add({
          'from_operation_id': widget.anchorOperationId,
          'to_operation_id': previewId,
          'from_name': widget.anchorOperationName,
          'to_name': newName,
          'edge_type': 'sequential',
        });
        edges.add({
          'from_operation_id': previewId,
          'to_operation_id': otherEnd,
          'from_name': newName,
          'to_name': _opNameById(otherEnd),
          'edge_type': 'sequential',
        });
      } else {
        edges.add({
          'from_operation_id': widget.anchorOperationId,
          'to_operation_id': previewId,
          'from_name': widget.anchorOperationName,
          'to_name': newName,
          'edge_type': 'sequential',
        });
      }
    } else {
      if (otherEnd != null) {
        edges.removeWhere((e) =>
            e['from_operation_id'] == otherEnd &&
            e['to_operation_id'] == widget.anchorOperationId);
        edges.add({
          'from_operation_id': otherEnd,
          'to_operation_id': previewId,
          'from_name': _opNameById(otherEnd),
          'to_name': newName,
          'edge_type': 'sequential',
        });
        edges.add({
          'from_operation_id': previewId,
          'to_operation_id': widget.anchorOperationId,
          'from_name': newName,
          'to_name': widget.anchorOperationName,
          'edge_type': 'sequential',
        });
      } else {
        edges.add({
          'from_operation_id': previewId,
          'to_operation_id': widget.anchorOperationId,
          'from_name': newName,
          'to_name': widget.anchorOperationName,
          'edge_type': 'sequential',
        });
      }
    }
  }

  void _applyAddBranchPreview(List<Map<String, dynamic>> edges, int previewId, String newName) {
    // Always add anchor -> NEW; do NOT remove any existing edges.
    edges.add({
      'from_operation_id': widget.anchorOperationId,
      'to_operation_id': previewId,
      'from_name': widget.anchorOperationName,
      'to_name': newName,
      'edge_type': 'parallel',
    });
    if (_addBranchMergeTargetOpId != null) {
      edges.add({
        'from_operation_id': previewId,
        'to_operation_id': _addBranchMergeTargetOpId,
        'from_name': newName,
        'to_name': _opNameById(_addBranchMergeTargetOpId!),
        'edge_type': 'parallel',
      });
    }
  }

  String _previewName() {
    if (_useExisting && _selectedExistingOpId != null) {
      final controller = Get.find<ProcessPlannerController>();
      final op = controller.operations.firstWhereOrNull(
          (o) => o.operationId == _selectedExistingOpId);
      return op?.name ?? '(existing)';
    }
    final n = _nameController.text.trim();
    return n.isEmpty ? '(new step)' : n;
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

  bool get _canUseAddBranchMode => widget.position == 'AFTER';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_useExisting && _selectedExistingOpId == null) {
      _setError('Please select an existing operation');
      return;
    }
    if (_mode == 'SPLIT_EDGE' &&
        _branchNeighbors.length > 1 &&
        _selectedBranchOtherEndOpId == null) {
      _setError('Please choose which branch to insert into');
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final isAfter = widget.position == 'AFTER';
      await _api.insertOperationIntoRouting(
        routingId: widget.routingId,
        mode: _mode,
        position: widget.position,
        afterOperationId: _mode == 'ADD_BRANCH'
            ? widget.anchorOperationId
            : (isAfter ? widget.anchorOperationId : _selectedBranchOtherEndOpId),
        beforeOperationId: _mode == 'ADD_BRANCH'
            ? null
            : (isAfter ? _selectedBranchOtherEndOpId : widget.anchorOperationId),
        mergeTargetOperationId: _mode == 'ADD_BRANCH' ? _addBranchMergeTargetOpId : null,
        useExisting: _useExisting,
        existingOperationId: _useExisting ? _selectedExistingOpId : null,
        name: _useExisting ? null : _nameController.text.trim(),
        description: _useExisting ? null : _descController.text.trim(),
        operationType: _useExisting ? null : _operationType,
        stageGroup: _useExisting ? null : int.tryParse(_stageGroupController.text) ?? 1,
        standardTime: _useExisting ? null : int.tryParse(_stdTimeController.text) ?? 60,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _setError(ApiErrorHelper.getMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _setError(String msg) => setState(() => _submitError = msg);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProcessPlannerController>();
    final positionLabel = widget.position == 'AFTER' ? 'After' : 'Before';

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_chart, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insert Step $positionLabel',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '"${widget.anchorOperationName}"',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModeSelector(),
                      const SizedBox(height: 16),
                      if (_mode == 'SPLIT_EDGE') _buildSplitEdgeSection(),
                      if (_mode == 'ADD_BRANCH') _buildAddBranchSection(),
                      const Divider(height: 24),
                      // Mode toggle: New / Existing
                      Text(
                        'Step type',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Create a new step'),
                            icon: Icon(Icons.add),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Use an existing step'),
                            icon: Icon(Icons.link),
                          ),
                        ],
                        selected: {_useExisting},
                        onSelectionChanged: (s) =>
                            setState(() => _useExisting = s.first),
                      ),
                      const SizedBox(height: 16),
                      if (_useExisting)
                        _buildExistingSelector(controller)
                      else
                        _buildNewOperationFields(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.preview, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Live Preview',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700),
                          ),
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
                      if (_submitError != null) ...[
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
                                child: Text(_submitError!,
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
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
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
                        : const Icon(Icons.check),
                    label: Text(_submitting ? 'Inserting...' : 'Insert'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
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

  Widget _buildModeSelector() {
    if (!_canUseAddBranchMode) {
      // For BEFORE position, only split-edge makes sense
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.indigo.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.call_split, color: Colors.indigo.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'The new step will be placed in the path before the selected step.',
                style: TextStyle(color: Colors.indigo.shade900, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How should the new step fit in?',
          style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment<String>(
              value: 'SPLIT_EDGE',
              label: Text('Place in the same path'),
              icon: Icon(Icons.call_split),
            ),
            ButtonSegment<String>(
              value: 'ADD_BRANCH',
              label: Text('Run alongside (parallel)'),
              icon: Icon(Icons.alt_route),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        const SizedBox(height: 6),
        Text(
          _mode == 'SPLIT_EDGE'
              ? '• The new step joins the existing flow on one path.'
              : '• A separate parallel path runs at the same time as the others.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSplitEdgeSection() {
    if (_branchNeighbors.isEmpty) {
      return Container(
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
                'No next step exists yet. The new step will be added at the end.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
    if (_branchNeighbors.length == 1) {
      final n = _branchNeighbors.first;
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.indigo.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.arrow_right_alt, color: Colors.indigo.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.position == 'AFTER'
                    ? 'New step will go between "${widget.anchorOperationName}" and "${n['name']}".'
                    : 'New step will go between "${n['name']}" and "${widget.anchorOperationName}".',
                style: TextStyle(color: Colors.indigo.shade900, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
    // Multiple branches — let the user pick one
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.position == 'AFTER'
              ? '"${widget.anchorOperationName}" leads to ${_branchNeighbors.length} different next steps. Which path should the new step go into?'
              : '"${widget.anchorOperationName}" can be reached from ${_branchNeighbors.length} different previous steps. Which path should the new step go into?',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        ..._branchNeighbors.map((n) {
          final id = n['id'] as int?;
          final name = (n['name'] ?? '').toString();
          return RadioListTile<int>(
            value: id ?? -1,
            groupValue: _selectedBranchOtherEndOpId ?? -1,
            onChanged: (v) => setState(() => _selectedBranchOtherEndOpId = v),
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              widget.position == 'AFTER'
                  ? '${widget.anchorOperationName}  →  $name'
                  : '$name  →  ${widget.anchorOperationName}',
              style: const TextStyle(fontSize: 13),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAddBranchSection() {
    final outOps = (widget.existingPlanData['operations'] as List<dynamic>? ?? [])
        .map<Map<String, dynamic>>((op) {
      final m = Map<String, dynamic>.from(op as Map);
      return {
        'id': (m['operationId'] ?? m['operation_id']) as int?,
        'name': (m['name'] ?? '').toString(),
      };
    }).where((o) => o['id'] != null && o['id'] != widget.anchorOperationId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.teal.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.alt_route, color: Colors.teal.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A new path will start from "${widget.anchorOperationName}" and run in parallel with existing paths. Existing paths will not change.',
                  style: TextStyle(color: Colors.teal.shade900, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Where should this new path go after the new step?',
          style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int?>(
          value: _addBranchMergeTargetOpId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.merge_type),
          ),
          isExpanded: true,
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('End here (nothing comes after)', overflow: TextOverflow.ellipsis),
            ),
            ...outOps.map((op) {
              return DropdownMenuItem<int?>(
                value: op['id'] as int?,
                child: Text(
                  'Continue to: ${op['name']}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: (v) => setState(() => _addBranchMergeTargetOpId = v),
        ),
      ],
    );
  }

  Widget _buildNewOperationFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Step name *',
            hintText: 'e.g., "Quality Check"',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label),
          ),
          validator: (v) {
            if (!_useExisting && (v == null || v.trim().isEmpty)) {
              return 'Please enter a step name';
            }
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descController,
          decoration: const InputDecoration(
            labelText: 'What happens here? (optional)',
            hintText: 'A short description of the work',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _stdTimeController,
                decoration: const InputDecoration(
                  labelText: 'Time per piece (seconds)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _stageGroupController,
                decoration: const InputDecoration(
                  labelText: 'Stage group',
                  hintText: 'e.g., 1',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.layers),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _operationType,
          decoration: const InputDecoration(
            labelText: 'Step kind',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: const [
            DropdownMenuItem(
              value: 'SEQUENTIAL',
              child: Text('Normal step (one path in, one path out)'),
            ),
            DropdownMenuItem(
              value: 'PARALLEL_BRANCH',
              child: Text('Side-path step (runs alongside others)'),
            ),
            DropdownMenuItem(
              value: 'MERGE',
              child: Text('Joining step (combines two trays into one)'),
            ),
          ],
          onChanged: (v) => setState(() => _operationType = v ?? 'SEQUENTIAL'),
        ),
      ],
    );
  }

  Widget _buildExistingSelector(ProcessPlannerController controller) {
    final inRoutingIds = ((widget.existingPlanData['operations'] as List<dynamic>? ?? [])
            .map((op) => (op as Map)['operationId'] ?? op['operation_id'])
            .whereType<int>())
        .toSet();
    final available = controller.operations
        .where((op) => !inRoutingIds.contains(op.operationId))
        .toList();

    if (available.isEmpty) {
      return Container(
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
                'No reusable steps are free to add. Switch to "Create a new step" instead.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedExistingOpId,
      decoration: const InputDecoration(
        labelText: 'Pick an existing step *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.link),
      ),
      isExpanded: true,
      items: available.map((op) {
        return DropdownMenuItem<int>(
          value: op.operationId,
          child: Text(op.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedExistingOpId = v),
      validator: (v) {
        if (_useExisting && v == null) return 'Please pick a step';
        return null;
      },
    );
  }
}
