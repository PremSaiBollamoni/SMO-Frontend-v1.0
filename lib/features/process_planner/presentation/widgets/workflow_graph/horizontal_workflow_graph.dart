import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../../core/network/api_client.dart';
import 'workflow_node.dart';
import 'level_sorted_renderer.dart';

/// Entry point for the workflow graph widget.
/// Wraps LevelSortedRenderer in an InteractiveViewer for pan/zoom support.
/// Fetches real-time active_operators for each operation to show tracking state.
class HorizontalWorkflowGraph extends StatefulWidget {
  final List<WorkflowNode> nodes;

  /// Optional callback fired when a node is tapped.
  final void Function(int routingId, int operationId, String operationName)? onNodeTap;

  /// Optional routing ID for fetching real-time active operators data
  final int? routingId;

  const HorizontalWorkflowGraph({
    super.key,
    required this.nodes,
    this.onNodeTap,
    this.routingId,
  });

  @override
  State<HorizontalWorkflowGraph> createState() =>
      _HorizontalWorkflowGraphState();
}

class _HorizontalWorkflowGraphState extends State<HorizontalWorkflowGraph> {
  final TransformationController _transformationController =
      TransformationController();
  Timer? _activeOperatorsTimer;
  late List<WorkflowNode> _nodesWithActiveOps;

  @override
  void initState() {
    super.initState();
    _nodesWithActiveOps = List.from(widget.nodes);
    _startActiveOperatorsFetcher();
  }

  @override
  void didUpdateWidget(HorizontalWorkflowGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodes != widget.nodes) {
      _nodesWithActiveOps = List.from(widget.nodes);
    }
    if (oldWidget.routingId != widget.routingId) {
      _activeOperatorsTimer?.cancel();
      _startActiveOperatorsFetcher();
    }
  }

  void _startActiveOperatorsFetcher() {
    // Fetch active operators immediately, then every 5 seconds
    _fetchActiveOperators();
    _activeOperatorsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _fetchActiveOperators();
    });
  }

  Future<void> _fetchActiveOperators() async {
    // Only fetch if we have a routing ID and operations to update
    if (widget.routingId == null || _nodesWithActiveOps.isEmpty) {
      return;
    }

    try {
      // Fetch active operators for all operations in this routing
      final response = await ApiClient().dio.get(
        '/api/processplan/operations-active-operators',
        queryParameters: {'routingId': widget.routingId},
      );

      if (response.statusCode == 200 && response.data is List && mounted) {
        // Build a map of operationId -> activeOperators count
        final activeOpsMap = <int, int>{};
        for (final item in (response.data as List)) {
          final opId = item['operation_id'] as int?;
          final activeOps = item['active_operators'] as int? ?? 0;
          if (opId != null) {
            activeOpsMap[opId] = activeOps;
          }
        }

        // Only log if there are active operations
        final activeOps = activeOpsMap.entries.where((e) => e.value > 0);
        if (activeOps.isNotEmpty) {
          print('[HorizontalWorkflowGraph] Active ops: ${Map.fromEntries(activeOps)}');
        }

        // Update nodes with active operators data
        setState(() {
          _nodesWithActiveOps = _nodesWithActiveOps.map((node) {
            final activeOps = activeOpsMap[node.operationId] ?? 0;
            if (node.activeOperators != activeOps) {
              return WorkflowNode(
                id: node.id,
                displayName: node.displayName,
                description: node.description,
                isMerge: node.isMerge,
                connections: node.connections,
                sequenceIndex: node.sequenceIndex,
                operationId: node.operationId,
                routingId: node.routingId,
                activeOperators: activeOps,
              );
            }
            return node;
          }).toList();
        });
      }
    } catch (e) {
      print('[HorizontalWorkflowGraph] Error fetching: $e');
    }
  }

  @override
  void dispose() {
    _activeOperatorsTimer?.cancel();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transformationController,
      boundaryMargin: const EdgeInsets.all(100),
      minScale: 0.5,
      maxScale: 3.0,
      constrained: false,
      clipBehavior: Clip.none,
      child: LevelSortedRenderer(nodes: _nodesWithActiveOps, onNodeTap: widget.onNodeTap),
    );
  }
}
