import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'goal_graph_controller.dart';
import 'graph_node_model.dart';

class GraphInteractionHandler extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerHover: _onPointerHover,
      child: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }

  static GraphNode? _draggedNode;
  static Offset _pointerDownPos = Offset.zero;

  void _onPointerDown(PointerDownEvent event) {
    _pointerDownPos = event.localPosition;
    final canvasPoint = _screenToCanvas(event.localPosition);
    _draggedNode = _findNodeAt(canvasPoint);
    
    if (_draggedNode != null) {
      _draggedNode!.isPinned = true;
      _draggedNode!.velocity = Offset.zero;
      controller.restartSimulation();
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_draggedNode != null) {
      _draggedNode!.position = _screenToCanvas(event.localPosition);
      _draggedNode!.velocity = Offset.zero;
      controller.notifyListeners();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_draggedNode != null) {
      _draggedNode!.isPinned = false;
      _draggedNode!.velocity = Offset.zero;
      _draggedNode = null;
      controller.restartSimulation();
    }

    final dist = (event.localPosition - _pointerDownPos).distance;
    if (dist < 8) {
      final canvasPoint = _screenToCanvas(event.localPosition);
      final tapped = _findNodeAt(canvasPoint);
      if (tapped != null) {
        onNodeTap(tapped.id);
      }
    }
  }

  void _onPointerHover(PointerEvent event) {
    final canvasPoint = _screenToCanvas(event.localPosition);
    bool changed = false;
    GraphNode? hovered;

    for (var node in controller.nodes) {
      final dist = (node.position - canvasPoint).distance;
      final isHovered = dist < (node.finalRadius + 12);
      if (node.isHovered != isHovered) {
        node.isHovered = isHovered;
        changed = true;
      }
      if (isHovered) hovered = node;
    }

    if (changed) {
      _updateConnectivity(hovered);
      controller.notifyListeners();
    }
  }

  void _updateConnectivity(GraphNode? hovered) {
    if (hovered == null) {
      for (var n in controller.nodes) {
        n.isHighlighted = false;
        n.isDimmed = false;
      }
      for (var e in controller.edges) {
        e.isHighlighted = false;
        e.isDimmed = false;
      }
      return;
    }

    final connectedIds = <String>{hovered.id};
    for (var e in controller.edges) {
      if (e.sourceId == hovered.id) connectedIds.add(e.targetId);
      if (e.targetId == hovered.id) connectedIds.add(e.sourceId);
    }

    for (var n in controller.nodes) {
      n.isHighlighted = connectedIds.contains(n.id);
      n.isDimmed = !n.isHighlighted;
    }

    for (var e in controller.edges) {
      e.isHighlighted = (e.sourceId == hovered.id || e.targetId == hovered.id);
      e.isDimmed = !e.isHighlighted;
    }
  }

  void _onScaleStart(ScaleStartDetails details) {}

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_draggedNode != null) return;

    if (details.scale != 1.0) {
      controller.zoom(details.scale, details.localFocalPoint, const Size(500, 500));
    } else {
      controller.pan(details.focalPointDelta);
    }
  }

  Offset _screenToCanvas(Offset screenPoint) {
    return (screenPoint - controller.panOffset) / controller.zoomLevel;
  }

  GraphNode? _findNodeAt(Offset canvasPoint) {
    for (var node in controller.nodes.reversed) {
      if ((node.position - canvasPoint).distance < (node.finalRadius + 12)) {
        return node;
      }
    }
    return null;
  }
}
