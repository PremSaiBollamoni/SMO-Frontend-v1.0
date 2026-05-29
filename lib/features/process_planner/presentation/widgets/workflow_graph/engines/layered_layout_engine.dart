import 'package:flutter/material.dart';
import '../workflow_node.dart';
import '../node_position.dart';
import 'phase_level_assigner.dart';

/// Layered DAG layout engine for process workflow graphs.
///
/// Pipeline:
///   1. Assign phase levels (topological, immutable)
///   2. Apply semantic node ordering within levels
///   3. Assign X/Y coordinates: X = level column, Y = centered within level
class LayeredLayoutEngine {
  // ── Layout constants ───────────────────────────────────────────────────────
  static const double levelSpacing = 200.0; // Standard horizontal spacing
  static const double mergeChainLevelSpacing = 160.0; // Tighter spacing for merge chains
  static const double nodeSpacing =
      85.0; // Reduced from 100 for tighter vertical spacing
  static const double startX = 60.0; // Left margin
  static const double startY = 60.0; // Top margin
  static const double nodeWidth = 140.0;
  static const double nodeHeight = 60.0;

  /// Feature flag — set to false to fully disable the barycenter pass and
  /// restore exactly the previous (semantic-only) ordering behavior.
  static const bool enableCrossingMinimization = true;

  /// Feature flag — when a level has a SINGLE node whose only parent is in
  /// the previous level, vertically align the node with its parent so the
  /// arrow draws as a clean horizontal line. Set to false to revert.
  static const bool alignSoloChildToParent = true;

  /// Markers that indicate a level is governed by hand-tuned semantic ordering.
  /// If ANY node in a level matches one of these tokens (case-insensitive
  /// substring match against the node id), the barycenter pass skips that
  /// level so the existing logic stays in control.
  static const List<String> _semanticMarkers = [
    'SLEEVE_LINE',
    'COLLAR_CUFF_LINE',
    'POCKET_PLACKET_LINE',
    'BODY_LINE',
    'MERGE_COLLAR',
    'MERGE_POCKET',
    'MERGE_SLEEVE',
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  static List<NodePosition> calculatePositions(List<WorkflowNode> nodes) {
    if (nodes.isEmpty) return [];

    // Step 1: Assign phase levels — IMMUTABLE after this point
    final levels = PhaseLevelAssigner.assign(nodes);
    final maxLevel = PhaseLevelAssigner.maxLevel(levels);
    final levelGroups = PhaseLevelAssigner.groupByLevel(levels);

    // Step 2: Crossing minimization disabled — level assignment is immutable
    // Correctness preserved: nodes stay in their assigned phase level

    // Step 3: Assign coordinates using immutable level groups
    return _assignCoordinates(nodes, levelGroups, maxLevel);
  }

  static List<NodePosition> _assignCoordinates(
    List<WorkflowNode> nodes,
    Map<int, List<String>> levelGroups,
    int maxLevel,
  ) {
    final positions = <NodePosition>[];

    // ── Crossing-minimization pass (additive, opt-in via flag) ──────────────
    // Only reorders nodes within "plain" levels — levels that have no semantic
    // markers (SLEEVE_LINE / COLLAR_CUFF_LINE / POCKET_PLACKET_LINE /
    // BODY_LINE / MERGE_*) so the hand-tuned logic stays in charge of those.
    // Returns a fresh map so we don't mutate the caller's level groups.
    final orderedLevelGroups = enableCrossingMinimization
        ? _reduceCrossings(nodes, levelGroups, maxLevel)
        : levelGroups;

    // Calculate the maximum number of nodes in any level for canvas height
    final maxNodesInLevel = orderedLevelGroups.values
        .map((v) => v.length)
        .fold(0, (a, b) => a > b ? a : b);

    // Canvas center Y — anchor for symmetric fan-out
    final canvasCenterY = startY + (maxNodesInLevel * nodeSpacing) / 2 + 40;

    // Build node map for merge detection
    final nodeMap = <String, WorkflowNode>{};
    for (final n in nodes) {
      nodeMap[n.id] = n;
    }

    // Build incoming-edges map (nodeId -> list of parent ids).
    // Used by the solo-child alignment pass below.
    final incomingByNode = <String, List<String>>{};
    if (alignSoloChildToParent) {
      for (final n in nodes) {
        for (final idx in n.connections) {
          if (idx >= 0 && idx < nodes.length) {
            final childId = nodes[idx].id;
            incomingByNode.putIfAbsent(childId, () => []).add(n.id);
          }
        }
      }
    }

    // Track Y of every placed node so a later level can lookup its parent's Y.
    final placedNodeY = <String, double>{};

    // Calculate X positions with adaptive spacing for merge chains
    double currentX = startX;
    final levelXPositions = <int, double>{};
    
    for (int level = 0; level <= maxLevel; level++) {
      levelXPositions[level] = currentX;
      
      final levelNodes = orderedLevelGroups[level] ?? [];
      if (levelNodes.isEmpty) continue;
      
      // Detect if this level is part of a merge chain (single merge node)
      final isMergeChainLevel = levelNodes.length == 1 && 
                                 nodeMap[levelNodes.first]?.isMerge == true;
      
      // Use tighter spacing for merge chain levels
      final spacing = isMergeChainLevel ? mergeChainLevelSpacing : levelSpacing;
      currentX += spacing;
    }

    for (int level = 0; level <= maxLevel; level++) {
      var levelNodes = List<String>.from(orderedLevelGroups[level] ?? []);
      if (levelNodes.isEmpty) continue;

      final x = levelXPositions[level]!;

      // ── Polish 1: Sort level 2 so BODY_LINE is central ──────────────────
      // Preferred semantic order when all 4 feeder lines are present:
      //   SLEEVE_LINE, COLLAR_CUFF_LINE, BODY_LINE (center), POCKET_PLACKET_LINE
      // Falls back to generic centering if not all nodes are present.
      if (levelNodes.length > 1) {
        const preferredOrder = [
          'SLEEVE_LINE',
          'COLLAR_CUFF_LINE',
          'POCKET_PLACKET_LINE',
          'BODY_LINE',
        ];

        // Check if all preferred nodes are present in this level
        final allPresent = preferredOrder.every(
          (name) => levelNodes.any((id) => id.toUpperCase().contains(name)),
        );

        if (allPresent) {
          // Apply preferred semantic order
          final ordered = <String>[];
          for (final name in preferredOrder) {
            final match = levelNodes.firstWhere(
              (id) => id.toUpperCase().contains(name),
              orElse: () => '',
            );
            if (match.isNotEmpty) ordered.add(match);
          }
          // Append any remaining nodes not in preferred list
          for (final id in levelNodes) {
            if (!ordered.contains(id)) ordered.add(id);
          }
          levelNodes = ordered;
        } else {
          // Generic fallback: center BODY_LINE if present
          final bodyId = levelNodes.firstWhere(
            (id) => id.toUpperCase().contains('BODY_LINE'),
            orElse: () => '',
          );
          if (bodyId.isNotEmpty) {
            levelNodes.remove(bodyId);
            levelNodes.insert(levelNodes.length ~/ 2, bodyId);
          }
        }
      }

      // ── Polish 2: Tighter spacing for merge chain level ────────────────────
      // Detect if this level contains merge-chain nodes (MERGE_COLLAR etc.)
      final isMergeChainLevel = levelNodes.any(
        (id) =>
            id.toUpperCase().contains('MERGE_COLLAR') ||
            id.toUpperCase().contains('MERGE_POCKET') ||
            id.toUpperCase().contains('MERGE_SLEEVE'),
      );
      final effectiveSpacing = isMergeChainLevel
          ? nodeSpacing * 1.2  // Reduced from 1.65 for tighter merge stack
          : nodeSpacing;

      // ── Polish 3: Symmetric fan-out — center all levels around canvasCenterY
      final totalHeight = (levelNodes.length - 1) * effectiveSpacing;
      double levelStartY = canvasCenterY - totalHeight / 2;

      // ── Polish 4 (NEW): align solo-child levels to their parent's Y so the
      // edge draws as a clean horizontal line.
      // Only applies when:
      //   - the level has exactly 1 node
      //   - that node has exactly 1 parent in incoming edges
      //   - the parent has already been placed (i.e. is in a lower level)
      // Multi-node and multi-parent levels keep their normal centered layout.
      if (alignSoloChildToParent && levelNodes.length == 1) {
        final loneId = levelNodes.first;
        final parents = incomingByNode[loneId] ?? const <String>[];
        if (parents.length == 1) {
          final parentId = parents.first;
          final parentY = placedNodeY[parentId];
          if (parentY != null) {
            levelStartY = parentY;
          }
        }
      }

      // ── Polish 5 (NEW): per-node parent-Y alignment within multi-node levels.
      // For each node, prefer its parent's Y (or the average of parent Ys when
      // there are multiple). Then resolve overlaps by enforcing min spacing.
      // Skipped for semantic levels so hand-tuned layouts stay untouched.
      List<double>? customYs;
      if (alignSoloChildToParent &&
          levelNodes.length > 1 &&
          !_isSemanticLevel(levelNodes)) {
        final preferred = <double>[];
        bool anyHasParent = false;
        for (final id in levelNodes) {
          final parents = incomingByNode[id] ?? const <String>[];
          double sum = 0;
          int count = 0;
          for (final p in parents) {
            final py = placedNodeY[p];
            if (py != null) {
              sum += py;
              count++;
            }
          }
          if (count > 0) {
            anyHasParent = true;
            preferred.add(sum / count);
          } else {
            // Fall back to centered position
            preferred.add(levelStartY + preferred.length * effectiveSpacing);
          }
        }

        if (anyHasParent) {
          // Sort indexes of levelNodes by preferred Y to produce a stable
          // top-to-bottom order matching parent positions.
          final indexes = List<int>.generate(levelNodes.length, (i) => i);
          indexes.sort((a, b) => preferred[a].compareTo(preferred[b]));

          // Walk the sorted list, enforcing min vertical spacing.
          final assigned = List<double>.filled(levelNodes.length, 0);
          double lastY = double.negativeInfinity;
          for (final i in indexes) {
            double y = preferred[i];
            if (y < lastY + effectiveSpacing) {
              y = lastY + effectiveSpacing;
            }
            assigned[i] = y;
            lastY = y;
          }
          customYs = assigned;
        }
      }

      for (int i = 0; i < levelNodes.length; i++) {
        final nodeId = levelNodes[i];
        final y = customYs != null
            ? customYs[i]
            : levelStartY + i * effectiveSpacing;

        placedNodeY[nodeId] = y;

        positions.add(
          NodePosition(
            index: _indexOf(nodes, nodeId),
            x: x,
            y: y,
            width: nodeWidth,
            height: nodeHeight,
          ),
        );
      }
    }

    return positions;
  }

  /// Canvas size based on positions
  static Size calculateCanvasSize(List<NodePosition> positions) {
    if (positions.isEmpty) return const Size(600, 500);

    double maxX = 0, maxY = 0, minY = double.infinity;
    for (final p in positions) {
      if (p.x + p.width > maxX) maxX = p.x + p.width;
      if (p.y + p.height > maxY) maxY = p.y + p.height;
      if (p.y < minY) minY = p.y;
    }

    // Ensure top nodes are not clipped
    final topPad = minY < 40 ? (40 - minY) + 40 : 40;
    return Size(maxX + 80, maxY + topPad + 60);
  }

  static int _indexOf(List<WorkflowNode> nodes, String id) {
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i].id == id) return i;
    }
    return 0;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Crossing minimization (barycenter sweep)
  //
  //  Reorders nodes within plain levels so that each node sits as close as
  //  possible to the average position of the predecessors that point to it.
  //  This dramatically reduces edge crossings in plain DAG layouts without
  //  touching levels assigned by the semantic ordering rules above.
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns true if any node id in [levelIds] contains one of the semantic
  /// marker tokens. Such a level is left untouched by the barycenter pass.
  static bool _isSemanticLevel(List<String> levelIds) {
    for (final id in levelIds) {
      final upper = id.toUpperCase();
      for (final marker in _semanticMarkers) {
        if (upper.contains(marker)) return true;
      }
    }
    return false;
  }

  /// Run a top-down barycenter sweep across all plain (non-semantic) levels.
  /// Level 0 is left as-is (no predecessors to balance against).
  /// Returns a NEW map — the input is never mutated.
  static Map<int, List<String>> _reduceCrossings(
    List<WorkflowNode> nodes,
    Map<int, List<String>> levelGroups,
    int maxLevel,
  ) {
    // Deep copy to avoid mutating caller state
    final ordered = <int, List<String>>{};
    levelGroups.forEach((k, v) => ordered[k] = List<String>.from(v));

    // Build a map of nodeId -> outgoing target ids (forward adjacency)
    // The connections list on WorkflowNode stores target indexes into nodes.
    final outgoing = <String, List<String>>{};
    for (final n in nodes) {
      final targets = <String>[];
      for (final idx in n.connections) {
        if (idx >= 0 && idx < nodes.length) {
          targets.add(nodes[idx].id);
        }
      }
      outgoing[n.id] = targets;
    }

    // Build incoming map: child -> list of parent ids
    final incoming = <String, List<String>>{};
    outgoing.forEach((parent, children) {
      for (final child in children) {
        incoming.putIfAbsent(child, () => []).add(parent);
      }
    });

    // One top-down pass is enough for most practical graphs and avoids any
    // chance of oscillation on edge cases. Skip level 0 (no predecessors).
    for (int level = 1; level <= maxLevel; level++) {
      final ids = ordered[level] ?? const <String>[];
      if (ids.length < 2) continue; // nothing to reorder
      if (_isSemanticLevel(ids)) continue; // hand-tuned levels stay as-is

      // Predecessor positions = current order of the previous level
      final prev = ordered[level - 1] ?? const <String>[];
      final prevIndex = <String, int>{};
      for (int i = 0; i < prev.length; i++) {
        prevIndex[prev[i]] = i;
      }

      // Compute barycenter (average parent index) for each node in this level.
      // Nodes without parents in the previous level keep their current index
      // so they don't get shoved to one end of the level.
      final originalIndex = <String, int>{};
      for (int i = 0; i < ids.length; i++) {
        originalIndex[ids[i]] = i;
      }

      double bary(String id) {
        final parents = incoming[id] ?? const <String>[];
        final indices = <int>[];
        for (final p in parents) {
          final idx = prevIndex[p];
          if (idx != null) indices.add(idx);
        }
        if (indices.isEmpty) {
          // No usable parent → keep current relative position
          return originalIndex[id]!.toDouble();
        }
        double sum = 0;
        for (final i in indices) {
          sum += i;
        }
        return sum / indices.length;
      }

      final sorted = List<String>.from(ids);
      sorted.sort((a, b) {
        final ba = bary(a);
        final bb = bary(b);
        final cmp = ba.compareTo(bb);
        if (cmp != 0) return cmp;
        // Stable tiebreaker by original index
        return originalIndex[a]!.compareTo(originalIndex[b]!);
      });

      ordered[level] = sorted;
    }

    return ordered;
  }
}
