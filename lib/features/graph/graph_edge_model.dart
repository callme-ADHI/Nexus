enum EdgeType { dependency, subgoal }

class GraphEdge {
  final String sourceId;
  final String targetId;
  final EdgeType type;
  bool isHighlighted;
  bool isDimmed;

  GraphEdge({
    required this.sourceId,
    required this.targetId,
    required this.type,
    this.isHighlighted = false,
    this.isDimmed = false,
  });
}
