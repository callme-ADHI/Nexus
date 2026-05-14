import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'goal_graph_controller.dart';
import 'graph_node_model.dart';

/// Handles all touch/pointer interactions for the graph canvas.
/// Converted to StatefulWidget to properly track per-gesture state.
class GraphInteractionHandler extends StatefulWidget {
  final GoalGraphController controller;
  final Widget child;
  final Function(String) onNodeTap;

  const GraphInteractionHandler({
    super.key,
    required this.controller,
    required this.child,
    required this.onNodeTap,
  });

  @override
  State<GraphInteractionHandler> createState() => _GraphInteractionHandlerState();
}

class _GraphInteractionHandlerState extends State<GraphInteractionHandler> {
  GraphNode? _draggedNode;
  Offset _pointerDownPos = Offset.zero;
  bool _isDraggingNode = false;

  // Scale tracking — `details.scale` is cumulative from gesture start,
  // so we track the previous frame's value to compute the per-frame delta.
  double _previousScale = 1.0;
  Offset _previousFocalPoint = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      child: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: _onScaleEnd,
        behavior: HitTestBehavior.opaque,
        child: widget.child,
      ),
    );
  }

  // ── Node Drag (single pointer) ────────────────────────────────────────────

  void _onPointerDown(PointerDownEvent event) {
    _pointerDownPos = event.localPosition;
    _isDraggingNode = false;

    final canvasPoint = _screenToCanvas(event.localPosition);
    _draggedNode = _findNodeAt(canvasPoint);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_draggedNode == null) return;

    final canvasPoint = _screenToCanvas(event.localPosition);
    widget.controller.moveNode(_draggedNode!, canvasPoint);
    _isDraggingNode = true;
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_draggedNode != null) {
      // Save the new layout without restarting physics
      widget.controller.onNodeDropped();
      _draggedNode = null;
      _isDraggingNode = false;
    }

    // Detect tap (minimal movement, no drag)
    final dist = (event.localPosition - _pointerDownPos).distance;
    if (dist < 8 && !_isDraggingNode) {
      final canvasPoint = _screenToCanvas(event.localPosition);
      final tapped = _findNodeAt(canvasPoint);
      if (tapped != null) {
        widget.onNodeTap(tapped.id);
      }
    }
  }

  // ── Pan & Pinch Zoom ──────────────────────────────────────────────────────

  void _onScaleStart(ScaleStartDetails details) {
    // Snapshot scale=1.0 at start so deltas are computed correctly
    _previousScale = 1.0;
    _previousFocalPoint = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    // Don't interfere while dragging a node
    if (_draggedNode != null) return;

    // ── Zoom (pinch) ──
    final scaleDelta = details.scale / _previousScale;
    _previousScale = details.scale;

    if ((scaleDelta - 1.0).abs() > 0.0005) {
      widget.controller.zoomAt(scaleDelta, details.localFocalPoint);
    }

    // ── Pan (focal point movement) ──
    final panDelta = details.localFocalPoint - _previousFocalPoint;
    _previousFocalPoint = details.localFocalPoint;

    if (panDelta.distance > 0.1) {
      widget.controller.pan(panDelta);
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _previousScale = 1.0;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Offset _screenToCanvas(Offset screenPoint) {
    return (screenPoint - widget.controller.panOffset) / widget.controller.zoomLevel;
  }

  GraphNode? _findNodeAt(Offset canvasPoint) {
    for (var node in widget.controller.nodes.reversed) {
      if ((node.position - canvasPoint).distance < (node.finalRadius + 14)) {
        return node;
      }
    }
    return null;
  }
}
