import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists node positions and viewport state across app restarts.
class GraphPositionsService {
  static const _posKey = 'graph_node_positions_v2';
  static const _viewKey = 'graph_viewport_v2';

  // ── Node Positions ─────────────────────────────────────────────────────────

  static Future<Map<String, Offset>> loadPositions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_posKey);
      if (raw == null) return {};
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((id, val) {
        final coords = val as Map<String, dynamic>;
        return MapEntry(
          id,
          Offset(
            (coords['x'] as num).toDouble(),
            (coords['y'] as num).toDouble(),
          ),
        );
      });
    } catch (_) {
      return {};
    }
  }

  static Future<void> savePositions(Map<String, Offset> positions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = positions.map(
        (id, offset) => MapEntry(id, {'x': offset.dx, 'y': offset.dy}),
      );
      await prefs.setString(_posKey, jsonEncode(map));
    } catch (_) {}
  }

  static Future<void> clearPositions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_posKey);
      await prefs.remove(_viewKey);
    } catch (_) {}
  }

  // ── Viewport State ─────────────────────────────────────────────────────────

  static Future<void> saveViewport({
    required Offset panOffset,
    required double zoomLevel,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _viewKey,
        jsonEncode({
          'px': panOffset.dx,
          'py': panOffset.dy,
          'zoom': zoomLevel,
        }),
      );
    } catch (_) {}
  }

  static Future<({Offset panOffset, double zoomLevel})?> loadViewport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_viewKey);
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return (
        panOffset: Offset((m['px'] as num).toDouble(), (m['py'] as num).toDouble()),
        zoomLevel: (m['zoom'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
