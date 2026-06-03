import 'package:flutter/material.dart';

/// Core data model for a workflow node.
/// displayName = WS code (shown on graph). description = Op Description (tooltip).
class WorkflowNode {
  final String id;
  final String displayName; // Current WS code — shown on graph node
  final String description; // Op Description — shown in tooltip/tap details
  final bool isMerge;
  final List<int> connections;

  /// Row index from spreadsheet — used as sequence bias for level assignment (0-based)
  final int sequenceIndex;

  /// Backend IDs — populated when viewing approved plans; 0 when built from spreadsheet
  final int operationId;
  final int routingId;

  /// Active operators count — 0 means no tracking, >0 means tracking active
  final int activeOperators;

  WorkflowNode({
    required this.id,
    required this.displayName,
    this.description = '',
    required this.isMerge,
    required this.connections,
    this.sequenceIndex = 0,
    this.operationId = 0,
    this.routingId = 0,
    this.activeOperators = 0,
  });
}

/// Widget for rendering a single workflow node with color highlight for active tracking
class WorkflowNodeWidget extends StatelessWidget {
  final WorkflowNode node;
  final double width;
  final double height;

  const WorkflowNodeWidget({
    super.key,
    required this.node,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Determine block color based on tracking status
    Color blockColor;
    Color borderColor;
    
    if (node.activeOperators > 0) {
      // Tracking active - bright green highlight
      blockColor = const Color(0xFF4CAF50);
      borderColor = const Color(0xFF2E7D32);
    } else if (node.isMerge) {
      // Merge operation - orange
      blockColor = const Color(0xFFFFA726);
      borderColor = const Color(0xFFF57C00);
    } else {
      // Normal operation - blue
      blockColor = const Color(0xFF42A5F5);
      borderColor = const Color(0xFF1976D2);
    }

    final nodeWidget = Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          // Add glow effect when tracking
          if (node.activeOperators > 0)
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Center(
        child: Text(
          node.displayName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );

    // Wrap in tooltip showing Op Description if available
    if (node.description.isNotEmpty &&
        node.description != node.displayName) {
      return Tooltip(
        message: node.description,
        preferBelow: false,
        child: nodeWidget,
      );
    }
    
    return nodeWidget;
  }
}
