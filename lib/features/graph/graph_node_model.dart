import 'package:flutter/material.dart';
import 'package:nexus/core/models/models.dart';

class GraphNode {
  final String id;
  final String label;
  final String? sublabel;
  final GoalStatus status;
  final int colorIndex;
  final bool isMainGoal;
  final bool isSubGoal;
  final double progress;
  final int depth;

  // Physics state
  Offset position;
  Offset velocity;
  Offset force;
  bool isPinned;
  bool isHovered;
  bool isSelected;
  bool isHighlighted;
  bool isDimmed;

  GraphNode({
    required this.id,
    required this.label,
    this.sublabel,
    required this.status,
    required this.colorIndex,
    required this.isMainGoal,
    required this.isSubGoal,
    this.progress = 0.0,
    this.depth = 1,
    this.position = Offset.zero,
    this.velocity = Offset.zero,
    this.force = Offset.zero,
    this.isPinned = false,
    this.isHovered = false,
    this.isSelected = false,
    this.isHighlighted = false,
    this.isDimmed = false,
  });

  double get baseRadius {
    if (isMainGoal) return 22.0;
    if (depth == 2) return 14.0;
    if (depth >= 3) return 10.0;
    return 14.0;
  }

  // To be updated by controller
  double finalRadius = 14.0;
}
