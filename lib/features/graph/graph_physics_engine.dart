import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'graph_node_model.dart';
import 'graph_edge_model.dart';

class GraphPhysicsEngine {
  static const double repulsionStrength = 6000.0;
  static const double attractionStrength = 180.0;
  static const double restLength = 120.0;
  static const double gravityStrength = 0.008;
  static const double damping = 0.78;
  static const double maxSpeed = 8.0;
  static const double margin = 80.0;

  static void applyForces({
    required List<GraphNode> nodes,
    required List<GraphEdge> edges,
    required Size canvasSize,
  }) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);

    // 1. Reset forces
    for (var node in nodes) {
      node.force = Offset.zero;
    }

    // 2. Repulsion (all pairs)
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final nodeA = nodes[i];
        final nodeB = nodes[j];

        final delta = nodeA.position - nodeB.position;
        final distance = delta.distance;

        if (distance > 400) continue; // Barnes-Hut optimization (approx)
        
        final safeDist = math.max(distance, 1.0);
        double strength = repulsionStrength;
        if (nodeA.isMainGoal || nodeB.isMainGoal) strength *= 2.5;

        final forceMag = strength / (safeDist * safeDist);
        final direction = delta / safeDist;

        nodeA.force += direction * forceMag;
        nodeB.force -= direction * forceMag;
      }
    }

    // 3. Attraction (connected pairs)
    final nodeMap = {for (var n in nodes) n.id: n};
    for (var edge in edges) {
      final nodeA = nodeMap[edge.sourceId];
      final nodeB = nodeMap[edge.targetId];

      if (nodeA == null || nodeB == null) continue;

      final delta = nodeB.position - nodeA.position;
      final distance = delta.distance;

      double currentRestLength = restLength;
      double currentAttraction = attractionStrength;

      if (edge.type == EdgeType.subgoal) {
        currentRestLength = 80.0;
        currentAttraction = 120.0;
      }

      if (distance > currentRestLength) {
        final forceMag = (distance - currentRestLength) / currentAttraction;
        final direction = delta / math.max(distance, 1.0);

        nodeA.force += direction * forceMag;
        nodeB.force -= direction * forceMag;
      }
    }

    // 4. Center Gravity & Boundary Repulsion
    for (var node in nodes) {
      // Center Gravity
      final deltaToCenter = center - node.position;
      double currentGravity = gravityStrength;
      if (node.isMainGoal) currentGravity = 0.025;
      
      node.force += deltaToCenter * currentGravity;

      // Boundary Repulsion
      if (node.position.dx < margin) {
        node.force = Offset(node.force.dx + (margin - node.position.dx) * 0.5, node.force.dy);
      } else if (node.position.dx > canvasSize.width - margin) {
        node.force = Offset(node.force.dx - (node.position.dx - (canvasSize.width - margin)) * 0.5, node.force.dy);
      }

      if (node.position.dy < margin) {
        node.force = Offset(node.force.dx, node.force.dy + (margin - node.position.dy) * 0.5);
      } else if (node.position.dy > canvasSize.height - margin) {
        node.force = Offset(node.force.dx, node.force.dy - (node.position.dy - (canvasSize.height - margin)) * 0.5);
      }
    }

    // 5. Integrate Velocity
    for (var node in nodes) {
      if (node.isPinned) continue;

      node.velocity = (node.velocity + node.force) * damping;

      if (node.velocity.distance > maxSpeed) {
        node.velocity = (node.velocity / node.velocity.distance) * maxSpeed;
      }

      node.position += node.velocity;
    }
  }

  static void initializePositions(List<GraphNode> nodes, Size canvasSize) {
    if (nodes.isEmpty) return;
    
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final baseRadius = math.min(canvasSize.width, canvasSize.height) * 0.35;
    final rand = math.Random();

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node.isMainGoal) {
        node.position = center;
      } else {
        final angle = (i / (nodes.length)) * 2 * math.pi;
        final jitterX = (rand.nextDouble() - 0.5) * 40;
        final jitterY = (rand.nextDouble() - 0.5) * 40;
        node.position = center + Offset(math.cos(angle), math.sin(angle)) * baseRadius + Offset(jitterX, jitterY);
      }
      node.velocity = Offset.zero;
    }
  }
}
