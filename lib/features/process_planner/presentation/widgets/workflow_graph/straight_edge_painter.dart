import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'node_position.dart';

/// Paints orthogonal (right-angle) directed edges, like StarUML / Visio.
///
/// Routing model:
///   1. Each SOURCE node owns a small private vertical channel right after
///      its stub. All of its outgoing edges share that channel — never
///      mingling with other sources. This stops same-level sources (e.g.
///      Fusing + Label Attach) from drawing on top of each other.
///   2. The horizontal run uses the TARGET's Y. If that horizontal segment
///      would pass through another node's bounding box, the run dodges to
///      a free Y (just above or below the obstacle) and re-bends at the
///      target.
class StraightEdgePainter extends CustomPainter {
  final List<Connection> connections;

  // ── Tunables ──────────────────────────────────────────────────────────────
  static const double _stubLength = 22.0;          // initial right kick from source
  static const double _laneOffset = 18.0;          // fan-in spacing at target
  static const double _sourceChannelStep = 14.0;   // spread per same-source edge in channel
  static const double _multiSourceChannelStep = 40.0; // X spread between sibling sources (was 16)
  static const double _arrowSize = 8.0;
  static const double _strokeWidth = 1.8;
  static const double _cornerRadius = 5.0;
  static const double _minApproachLen = 18.0;      // min horizontal run before arrowhead
  static const double _obstacleClearance = 14.0;   // padding above/below a blocking node
  static const double _straightYTolerance = 6.0;   // if |start.y - end.y| <= this → straight

  /// Master switch — flip to false to revert to old straight-diagonal renderer
  static const bool useOrthogonalRouting = true;

  /// Bounding boxes of every node currently on the canvas.
  /// Built once per paint and consulted when routing each edge so a horizontal
  /// run does not pass through the body of an unrelated node.
  late List<Rect> _nodeRects;
  late Map<int, Rect> _nodeRectByIndex;

  StraightEdgePainter({required this.connections});

  @override
  void paint(Canvas canvas, Size size) {
    if (!useOrthogonalRouting) {
      _paintLegacyStraight(canvas);
      return;
    }
    _buildNodeRects();
    _paintOrthogonal(canvas);
  }

  void _buildNodeRects() {
    final rects = <Rect>[];
    final byIndex = <int, Rect>{};
    final seen = <int>{};
    for (final c in connections) {
      if (seen.add(c.from.index)) {
        final r = Rect.fromLTWH(c.from.x, c.from.y, c.from.width, c.from.height);
        rects.add(r);
        byIndex[c.from.index] = r;
      }
      if (seen.add(c.to.index)) {
        final r = Rect.fromLTWH(c.to.x, c.to.y, c.to.width, c.to.height);
        rects.add(r);
        byIndex[c.to.index] = r;
      }
    }
    _nodeRects = rects;
    _nodeRectByIndex = byIndex;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Orthogonal routing
  // ─────────────────────────────────────────────────────────────────────────

  void _paintOrthogonal(Canvas canvas) {
    final linePaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final arrowPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.fill;

    // ── Lane offsets at target (multiple incoming edges fan in vertically) ─
    final byTarget = <int, List<Connection>>{};
    for (final c in connections) {
      byTarget.putIfAbsent(c.to.index, () => []).add(c);
    }
    final laneOffset = <String, double>{};
    for (final entry in byTarget.entries) {
      final list = entry.value;
      if (list.length <= 1) {
        laneOffset[_key(list.first)] = 0.0;
        continue;
      }
      list.sort((a, b) => a.from.rightCenter.dy.compareTo(b.from.rightCenter.dy));
      final spread = (list.length - 1) * _laneOffset;
      final start = -spread / 2;
      for (int i = 0; i < list.length; i++) {
        laneOffset[_key(list[i])] = start + i * _laneOffset;
      }
    }

    // ── Source → outgoing edges grouping (StarUML-style tree branching).
    //    All outgoing edges from a source SHARE the source's rightCenter as
    //    their start point — no Y stagger at the stub. They travel together
    //    along a single channel X and split vertically at that channel X to
    //    reach their individual targets.
    final bySource = <int, List<Connection>>{};
    for (final c in connections) {
      bySource.putIfAbsent(c.from.index, () => []).add(c);
    }

    // ── Per-source channel X: each source owns a single channel column.
    // Sibling sources at the same level get staggered X values so their
    // channels don't overlap.
    final channelXBySource = <int, double>{};
    {
      final sourcesByLevel = <int, List<NodePosition>>{};
      for (final entry in bySource.entries) {
        final src = entry.value.first.from;
        final q = ((src.x + src.width) / 5).round();
        sourcesByLevel.putIfAbsent(q, () => []).add(src);
      }
      sourcesByLevel.forEach((_, group) {
        group.sort((a, b) => a.y.compareTo(b.y));
        for (int i = 0; i < group.length; i++) {
          final src = group[i];
          final shift = i * _multiSourceChannelStep;
          channelXBySource[src.index] = src.x + src.width + _stubLength + shift;
        }
      });
    }

    // ── Draw each edge ────────────────────────────────────────────────────
    for (final conn in connections) {
      _drawOrthogonalEdge(
        canvas,
        conn,
        laneOffset[_key(conn)] ?? 0.0,
        channelXBySource[conn.from.index],
        linePaint,
        arrowPaint,
      );
    }
  }

  /// Routes one orthogonal edge.
  /// Path: source.rightCenter → channelX → target.y → target.left
  /// (Source.rightCenter is always the start — no stub stagger.)
  /// If the horizontal run at target.y intersects another node, dodge above/below.
  void _drawOrthogonalEdge(
    Canvas canvas,
    Connection conn,
    double laneOffsetY,
    double? channelXOverride,
    Paint linePaint,
    Paint arrowPaint,
  ) {
    final start = conn.from.rightCenter;
    final end = Offset(conn.to.leftCenter.dx, conn.to.leftCenter.dy + laneOffsetY);

    final sourceRightX = conn.from.x + conn.from.width;
    final targetLeftX = conn.to.x;

    // ── Fast path: source and target are roughly at the same Y → draw a
    // pure horizontal line. This handles the common case of a single edge
    // between two parallel-aligned nodes (e.g. Cuff Hemming → Cuff Run).
    // We snap end.dy to start.dy so the line is perfectly horizontal.
    if ((start.dy - end.dy).abs() <= _straightYTolerance) {
      // Verify the horizontal run isn't blocked by another node
      final obstacle = _findObstacleOnHorizontal(
        fromX: sourceRightX,
        toX: targetLeftX,
        atY: start.dy,
        ignore: {conn.from.index, conn.to.index},
      );
      if (obstacle == null) {
        final straightEnd = Offset(end.dx, start.dy);
        canvas.drawLine(start, straightEnd, linePaint);
        _drawArrowhead(canvas, arrowPaint, straightEnd);
        return;
      }
    }

    // Clamp channel X within [sourceRight + 4, targetLeft - minApproach]

    // Clamp channel X within [sourceRight + 4, targetLeft - minApproach]
    final minX = sourceRightX + 4;
    final maxX = math.max(minX, targetLeftX - _minApproachLen);
    final desired = channelXOverride ?? (sourceRightX + _stubLength);
    double channelX = desired.clamp(minX, maxX).toDouble();

    // Vertical-run obstacle dodge: if the vertical segment at channelX would
    // pass THROUGH another node's box between start.dy and end.dy, shift the
    // channel further right past the obstacle so the line doesn't visually
    // overlap a different step (which causes the "going to wrong target"
    // confusion the user sees).
    {
      final yMin = math.min(start.dy, end.dy);
      final yMax = math.max(start.dy, end.dy);
      const int maxShifts = 12;
      for (int attempt = 0; attempt < maxShifts; attempt++) {
        final blocker = _findObstacleOnVertical(
          atX: channelX,
          fromY: yMin,
          toY: yMax,
          ignore: {conn.from.index, conn.to.index},
        );
        if (blocker == null) break;
        // Push channelX past the blocker's right edge
        final next = blocker.right + 8.0;
        if (next > maxX) break; // no room left
        channelX = next.clamp(minX, maxX).toDouble();
      }
    }

    // Detect vertical-run crossing the source or target (almost impossible
    // since channelX is right of source) — handled by clamping.

    // Detect if the HORIZONTAL run at end.dy crosses a node's box.
    // We try end.dy first; if blocked, try shifting up or down past the obstacle.
    double runY = end.dy;
    final obstacle = _findObstacleOnHorizontal(
      fromX: channelX,
      toX: targetLeftX,
      atY: runY,
      ignore: {conn.from.index, conn.to.index},
    );
    if (obstacle != null) {
      // Try going above the obstacle (between source's Y and obstacle.top)
      final tryUp = obstacle.top - _obstacleClearance;
      // Try going below the obstacle
      final tryDown = obstacle.bottom + _obstacleClearance;
      // Pick whichever is closer to end.dy
      final upDist = (tryUp - end.dy).abs();
      final downDist = (tryDown - end.dy).abs();
      final candidate = upDist <= downDist ? tryUp : tryDown;
      // Verify candidate is also clear; if not, fall back to other side
      final candObstacle = _findObstacleOnHorizontal(
        fromX: channelX,
        toX: targetLeftX,
        atY: candidate,
        ignore: {conn.from.index, conn.to.index},
      );
      if (candObstacle == null) {
        runY = candidate;
      } else {
        final alt = upDist <= downDist ? tryDown : tryUp;
        final altObstacle = _findObstacleOnHorizontal(
          fromX: channelX,
          toX: targetLeftX,
          atY: alt,
          ignore: {conn.from.index, conn.to.index},
        );
        if (altObstacle == null) runY = alt; // else give up — accept overlap
      }
    }

    // Build path: start → (channelX, start.dy) → (channelX, runY) → (targetLeftX, runY) → (targetLeftX, end.dy) → end
    if ((start.dy - end.dy).abs() < 0.5 && obstacle == null) {
      // Straight horizontal — no bend needed
      canvas.drawLine(start, end, linePaint);
      _drawArrowhead(canvas, arrowPaint, end);
      return;
    }

    final corner1 = Offset(channelX, start.dy);
    final corner2 = Offset(channelX, runY);
    final corner3 = Offset(targetLeftX, runY);

    final path = Path()..moveTo(start.dx, start.dy);

    // Segment a: start → corner1 (horizontal)
    _addRoundedCorner(path, start, corner1, corner2);
    // Segment b: corner1 → corner2 (vertical) — corner already added
    _addRoundedCorner(path, corner1, corner2, corner3);
    // If runY != end.dy, we need an additional bend at corner3
    if ((runY - end.dy).abs() > 0.5) {
      _addRoundedCorner(path, corner2, corner3, end);
      // last segment: corner3 → end (vertical) → end.dy
      // But to arrive horizontal into the target, do another bend at (targetLeftX, end.dy)
      final corner4 = Offset(targetLeftX, end.dy);
      _addRoundedCorner(path, corner3, corner4, end);
      path.lineTo(end.dx, end.dy);
    } else {
      path.lineTo(end.dx, end.dy);
    }

    canvas.drawPath(path, linePaint);
    _drawArrowhead(canvas, arrowPaint, end);
  }

  /// Returns the rect of any node whose body is intersected by the horizontal
  /// segment from (fromX, atY) to (toX, atY). Skips nodes in [ignore].
  /// Returns the FIRST such rect found (closest is fine for simple cases).
  Rect? _findObstacleOnHorizontal({
    required double fromX,
    required double toX,
    required double atY,
    required Set<int> ignore,
  }) {
    final lo = math.min(fromX, toX);
    final hi = math.max(fromX, toX);
    Rect? closest;
    double closestDist = double.infinity;
    _nodeRectByIndex.forEach((idx, r) {
      if (ignore.contains(idx)) return;
      // Vertical overlap?
      if (atY < r.top || atY > r.bottom) return;
      // Horizontal overlap with segment?
      if (r.right < lo || r.left > hi) return;
      // Found a blocker
      final d = (r.center.dx - (lo + hi) / 2).abs();
      if (d < closestDist) {
        closestDist = d;
        closest = r;
      }
    });
    return closest;
  }

  /// Returns any node rect whose body is crossed by the vertical segment
  /// from (atX, fromY) to (atX, toY). Skips nodes in [ignore].
  Rect? _findObstacleOnVertical({
    required double atX,
    required double fromY,
    required double toY,
    required Set<int> ignore,
  }) {
    final lo = math.min(fromY, toY);
    final hi = math.max(fromY, toY);
    Rect? closest;
    double closestDist = double.infinity;
    _nodeRectByIndex.forEach((idx, r) {
      if (ignore.contains(idx)) return;
      // Horizontal overlap?
      if (atX < r.left || atX > r.right) return;
      // Vertical overlap with segment?
      if (r.bottom < lo || r.top > hi) return;
      final d = (r.center.dy - (lo + hi) / 2).abs();
      if (d < closestDist) {
        closestDist = d;
        closest = r;
      }
    });
    return closest;
  }

  /// Add a rounded right-angle turn into the path.
  /// Path is currently at `prev`; we want to draw to `corner` then turn toward `next`.
  void _addRoundedCorner(Path path, Offset prev, Offset corner, Offset next) {
    if (_cornerRadius <= 0) {
      path.lineTo(corner.dx, corner.dy);
      return;
    }
    final inDir = _unit(corner - prev);
    final outDir = _unit(next - corner);
    if (inDir == Offset.zero || outDir == Offset.zero) {
      path.lineTo(corner.dx, corner.dy);
      return;
    }
    final inLen = (corner - prev).distance;
    final outLen = (next - corner).distance;
    final r = math.min(_cornerRadius, math.min(inLen, outLen) / 2);
    if (r <= 0.5) {
      path.lineTo(corner.dx, corner.dy);
      return;
    }
    final p1 = corner - inDir * r;
    final p2 = corner + outDir * r;
    path.lineTo(p1.dx, p1.dy);
    path.arcToPoint(p2, radius: Radius.circular(r));
  }

  Offset _unit(Offset v) {
    final l = v.distance;
    if (l < 1e-6) return Offset.zero;
    return v / l;
  }

  /// Horizontal-pointing arrowhead at `end`.
  void _drawArrowhead(Canvas canvas, Paint paint, Offset end) {
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - _arrowSize, end.dy - _arrowSize / 2)
      ..lineTo(end.dx - _arrowSize, end.dy + _arrowSize / 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  static String _key(Connection c) => '${c.from.index}->${c.to.index}';

  // ─────────────────────────────────────────────────────────────────────────
  //  Legacy straight-diagonal fallback
  // ─────────────────────────────────────────────────────────────────────────

  void _paintLegacyStraight(Canvas canvas) {
    final linePaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final arrowPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.fill;
    final byTarget = <int, List<Connection>>{};
    for (final conn in connections) {
      byTarget.putIfAbsent(conn.to.index, () => []).add(conn);
    }
    final laneOffsets = <String, double>{};
    for (final entry in byTarget.entries) {
      final incoming = entry.value;
      if (incoming.length <= 1) {
        laneOffsets[_key(incoming.first)] = 0.0;
        continue;
      }
      incoming.sort((a, b) => a.from.rightCenter.dy.compareTo(b.from.rightCenter.dy));
      final count = incoming.length;
      final totalSpread = (count - 1) * _laneOffset;
      final startOffset = -totalSpread / 2;
      for (int i = 0; i < count; i++) {
        laneOffsets[_key(incoming[i])] = startOffset + i * _laneOffset;
      }
    }
    for (final conn in connections) {
      final offset = laneOffsets[_key(conn)] ?? 0.0;
      final start = conn.from.rightCenter;
      final rawEnd = conn.to.leftCenter;
      final end = Offset(rawEnd.dx, rawEnd.dy + offset);
      canvas.drawLine(start, end, linePaint);
      _drawDiagonalArrow(canvas, arrowPaint, start, end);
    }
  }

  void _drawDiagonalArrow(Canvas canvas, Paint paint, Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = math.atan2(dy, dx);
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - _arrowSize * math.cos(angle - math.pi / 6),
        end.dy - _arrowSize * math.sin(angle - math.pi / 6),
      )
      ..lineTo(
        end.dx - _arrowSize * math.cos(angle + math.pi / 6),
        end.dy - _arrowSize * math.sin(angle + math.pi / 6),
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(StraightEdgePainter oldDelegate) =>
      oldDelegate.connections != connections;
}
