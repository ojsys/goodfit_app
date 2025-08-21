import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route.dart' as route_model;
import 'api_service.dart';

class RouteAnalyticsService extends ChangeNotifier {
  static final RouteAnalyticsService _instance = RouteAnalyticsService._internal();
  factory RouteAnalyticsService() => _instance;
  RouteAnalyticsService._internal();

  final ApiService _apiService = ApiService();
  
  // Analytics data cache
  Map<String, RouteHeatmapData> _routeHeatmaps = {};
  Map<String, RouteStatistics> _routeStats = {};
  bool _isLoading = false;

  // Getters
  bool get isLoading => _isLoading;
  
  /// Get route heatmap data
  Future<RouteHeatmapData?> getRouteHeatmap(String routeId) async {
    // Check cache first
    if (_routeHeatmaps.containsKey(routeId)) {
      return _routeHeatmaps[routeId];
    }

    _setLoading(true);
    
    try {
      final response = await _apiService.get('/fitness/routes/$routeId/heatmap/');
      
      if (response.success && response.data != null) {
        final heatmapData = RouteHeatmapData.fromJson(response.data!);
        _routeHeatmaps[routeId] = heatmapData;
        return heatmapData;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error fetching route heatmap: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Get route statistics
  Future<RouteStatistics?> getRouteStatistics(String routeId) async {
    // Check cache first
    if (_routeStats.containsKey(routeId)) {
      return _routeStats[routeId];
    }

    _setLoading(true);
    
    try {
      final response = await _apiService.get('/fitness/routes/$routeId/statistics/');
      
      if (response.success && response.data != null) {
        final stats = RouteStatistics.fromJson(response.data!);
        _routeStats[routeId] = stats;
        return stats;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error fetching route statistics: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Generate heatmap from user tracking data
  RouteHeatmapData generateHeatmapFromTracking(
    List<LatLng> userPaths,
    route_model.Route route,
  ) {
    final heatmapPoints = <HeatmapPoint>[];
    final segmentAnalysis = <RouteSegment>[];
    
    // Create grid for heatmap
    final gridSize = 0.001; // ~100m grid
    final pointCounts = <String, int>{};
    final pointSpeeds = <String, List<double>>{};
    
    // Process user tracking points
    for (int i = 0; i < userPaths.length - 1; i++) {
      final point = userPaths[i];
      final nextPoint = userPaths[i + 1];
      
      // Calculate grid key
      final gridKey = '${(point.latitude / gridSize).floor()}_${(point.longitude / gridSize).floor()}';
      
      // Count points in grid
      pointCounts[gridKey] = (pointCounts[gridKey] ?? 0) + 1;
      
      // Calculate speed for this segment
      final distance = _calculateDistance(point, nextPoint);
      final timeInterval = 1.0; // Assuming 1 second intervals
      final speed = distance / timeInterval; // m/s
      
      if (!pointSpeeds.containsKey(gridKey)) {
        pointSpeeds[gridKey] = [];
      }
      pointSpeeds[gridKey]!.add(speed);
    }
    
    // Convert to heatmap points
    pointCounts.forEach((gridKey, count) {
      final parts = gridKey.split('_');
      final lat = int.parse(parts[0]) * gridSize;
      final lng = int.parse(parts[1]) * gridSize;
      
      final speeds = pointSpeeds[gridKey] ?? [];
      final avgSpeed = speeds.isNotEmpty 
          ? speeds.reduce((a, b) => a + b) / speeds.length 
          : 0.0;
      
      heatmapPoints.add(HeatmapPoint(
        location: LatLng(lat, lng),
        intensity: count.toDouble(),
        averageSpeed: avgSpeed,
        sampleCount: count,
      ));
    });
    
    // Analyze route segments
    if (route.coordinates != null) {
      segmentAnalysis.addAll(_analyzeRouteSegments(route.coordinates!, userPaths));
    }
    
    return RouteHeatmapData(
      routeId: route.id,
      heatmapPoints: heatmapPoints,
      segments: segmentAnalysis,
      generatedAt: DateTime.now(),
      totalSamples: userPaths.length,
    );
  }

  /// Analyze route segments for difficulty and characteristics
  List<RouteSegment> _analyzeRouteSegments(
    List<LatLng> routePoints,
    List<LatLng> userPaths,
  ) {
    final segments = <RouteSegment>[];
    final segmentSize = math.max(1, routePoints.length ~/ 20); // 20 segments max
    
    for (int i = 0; i < routePoints.length - segmentSize; i += segmentSize) {
      final segmentEnd = math.min(i + segmentSize, routePoints.length - 1);
      final segmentPoints = routePoints.sublist(i, segmentEnd + 1);
      
      // Calculate segment characteristics
      final distance = _calculateSegmentDistance(segmentPoints);
      final elevationGain = _estimateElevationGain(segmentPoints);
      final difficulty = _calculateDifficulty(distance, elevationGain);
      
      // Find user performance on this segment
      final userSegmentData = _findUserDataForSegment(segmentPoints, userPaths);
      
      segments.add(RouteSegment(
        startIndex: i,
        endIndex: segmentEnd,
        startPoint: segmentPoints.first,
        endPoint: segmentPoints.last,
        distance: distance,
        estimatedElevationGain: elevationGain,
        difficulty: difficulty,
        averageUserSpeed: userSegmentData['averageSpeed'],
        userDeviations: userSegmentData['deviations'],
        popularityScore: userSegmentData['popularity'],
      ));
    }
    
    return segments;
  }

  /// Calculate distance between two points
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth radius in meters
    
    final lat1Rad = point1.latitude * math.pi / 180;
    final lat2Rad = point2.latitude * math.pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final deltaLng = (point2.longitude - point1.longitude) * math.pi / 180;
    
    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Calculate total distance for a segment
  double _calculateSegmentDistance(List<LatLng> points) {
    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += _calculateDistance(points[i], points[i + 1]);
    }
    return totalDistance;
  }

  /// Estimate elevation gain (simplified calculation)
  double _estimateElevationGain(List<LatLng> points) {
    // This is a simplified estimation
    // In a real app, you'd use elevation APIs
    double gain = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      // Rough estimate based on terrain changes
      final distance = _calculateDistance(points[i], points[i + 1]);
      if (distance > 100) { // Significant distance change
        gain += distance * 0.02; // 2% grade assumption
      }
    }
    return gain;
  }

  /// Calculate difficulty score
  double _calculateDifficulty(double distance, double elevationGain) {
    // Simple difficulty calculation
    final distanceFactor = distance / 1000; // km
    final elevationFactor = elevationGain / 100; // per 100m
    return (distanceFactor + elevationFactor * 2).clamp(1.0, 5.0);
  }

  /// Find user performance data for a segment
  Map<String, dynamic> _findUserDataForSegment(
    List<LatLng> segmentPoints,
    List<LatLng> userPaths,
  ) {
    // Simplified analysis
    return {
      'averageSpeed': 10.0, // km/h
      'deviations': 5.0, // meters
      'popularity': 0.8, // 0-1 scale
    };
  }

  /// Create Google Maps heatmap
  Set<Circle> createHeatmapCircles(RouteHeatmapData heatmapData) {
    final circles = <Circle>{};
    
    for (final point in heatmapData.heatmapPoints) {
      final intensity = (point.intensity / 10).clamp(0.0, 1.0);
      final radius = 50.0 + (intensity * 50.0); // 50-100m radius
      
      circles.add(
        Circle(
          circleId: CircleId('heatmap_${point.location.latitude}_${point.location.longitude}'),
          center: point.location,
          radius: radius,
          fillColor: _getHeatmapColor(intensity).withOpacity(0.3),
          strokeColor: _getHeatmapColor(intensity),
          strokeWidth: 1,
        ),
      );
    }
    
    return circles;
  }

  /// Get color for heatmap intensity
  Color _getHeatmapColor(double intensity) {
    if (intensity < 0.2) return Colors.blue;
    if (intensity < 0.4) return Colors.green;
    if (intensity < 0.6) return Colors.yellow;
    if (intensity < 0.8) return Colors.orange;
    return Colors.red;
  }

  /// Export route data
  Future<Map<String, dynamic>> exportRouteData(String routeId) async {
    final heatmap = await getRouteHeatmap(routeId);
    final stats = await getRouteStatistics(routeId);
    
    return {
      'route_id': routeId,
      'exported_at': DateTime.now().toIso8601String(),
      'heatmap_data': heatmap?.toJson(),
      'statistics': stats?.toJson(),
    };
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clear cache
  void clearCache() {
    _routeHeatmaps.clear();
    _routeStats.clear();
    notifyListeners();
  }
}

class RouteHeatmapData {
  final String routeId;
  final List<HeatmapPoint> heatmapPoints;
  final List<RouteSegment> segments;
  final DateTime generatedAt;
  final int totalSamples;

  const RouteHeatmapData({
    required this.routeId,
    required this.heatmapPoints,
    required this.segments,
    required this.generatedAt,
    required this.totalSamples,
  });

  factory RouteHeatmapData.fromJson(Map<String, dynamic> json) {
    return RouteHeatmapData(
      routeId: json['route_id'] ?? '',
      heatmapPoints: (json['heatmap_points'] as List<dynamic>? ?? [])
          .map((point) => HeatmapPoint.fromJson(point))
          .toList(),
      segments: (json['segments'] as List<dynamic>? ?? [])
          .map((segment) => RouteSegment.fromJson(segment))
          .toList(),
      generatedAt: DateTime.parse(json['generated_at'] ?? DateTime.now().toIso8601String()),
      totalSamples: json['total_samples'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_id': routeId,
      'heatmap_points': heatmapPoints.map((p) => p.toJson()).toList(),
      'segments': segments.map((s) => s.toJson()).toList(),
      'generated_at': generatedAt.toIso8601String(),
      'total_samples': totalSamples,
    };
  }
}

class HeatmapPoint {
  final LatLng location;
  final double intensity;
  final double averageSpeed;
  final int sampleCount;

  const HeatmapPoint({
    required this.location,
    required this.intensity,
    required this.averageSpeed,
    required this.sampleCount,
  });

  factory HeatmapPoint.fromJson(Map<String, dynamic> json) {
    return HeatmapPoint(
      location: LatLng(json['lat'] ?? 0.0, json['lng'] ?? 0.0),
      intensity: (json['intensity'] ?? 0.0).toDouble(),
      averageSpeed: (json['average_speed'] ?? 0.0).toDouble(),
      sampleCount: json['sample_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': location.latitude,
      'lng': location.longitude,
      'intensity': intensity,
      'average_speed': averageSpeed,
      'sample_count': sampleCount,
    };
  }
}

class RouteSegment {
  final int startIndex;
  final int endIndex;
  final LatLng startPoint;
  final LatLng endPoint;
  final double distance;
  final double estimatedElevationGain;
  final double difficulty;
  final double averageUserSpeed;
  final double userDeviations;
  final double popularityScore;

  const RouteSegment({
    required this.startIndex,
    required this.endIndex,
    required this.startPoint,
    required this.endPoint,
    required this.distance,
    required this.estimatedElevationGain,
    required this.difficulty,
    required this.averageUserSpeed,
    required this.userDeviations,
    required this.popularityScore,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      startIndex: json['start_index'] ?? 0,
      endIndex: json['end_index'] ?? 0,
      startPoint: LatLng(json['start_lat'] ?? 0.0, json['start_lng'] ?? 0.0),
      endPoint: LatLng(json['end_lat'] ?? 0.0, json['end_lng'] ?? 0.0),
      distance: (json['distance'] ?? 0.0).toDouble(),
      estimatedElevationGain: (json['elevation_gain'] ?? 0.0).toDouble(),
      difficulty: (json['difficulty'] ?? 0.0).toDouble(),
      averageUserSpeed: (json['average_speed'] ?? 0.0).toDouble(),
      userDeviations: (json['user_deviations'] ?? 0.0).toDouble(),
      popularityScore: (json['popularity_score'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_index': startIndex,
      'end_index': endIndex,
      'start_lat': startPoint.latitude,
      'start_lng': startPoint.longitude,
      'end_lat': endPoint.latitude,
      'end_lng': endPoint.longitude,
      'distance': distance,
      'elevation_gain': estimatedElevationGain,
      'difficulty': difficulty,
      'average_speed': averageUserSpeed,
      'user_deviations': userDeviations,
      'popularity_score': popularityScore,
    };
  }
}

class RouteStatistics {
  final String routeId;
  final int totalCompletions;
  final double averageTime;
  final double averageSpeed;
  final double popularityScore;
  final Map<String, int> difficultyRatings;
  final List<String> commonIssues;

  const RouteStatistics({
    required this.routeId,
    required this.totalCompletions,
    required this.averageTime,
    required this.averageSpeed,
    required this.popularityScore,
    required this.difficultyRatings,
    required this.commonIssues,
  });

  factory RouteStatistics.fromJson(Map<String, dynamic> json) {
    return RouteStatistics(
      routeId: json['route_id'] ?? '',
      totalCompletions: json['total_completions'] ?? 0,
      averageTime: (json['average_time'] ?? 0.0).toDouble(),
      averageSpeed: (json['average_speed'] ?? 0.0).toDouble(),
      popularityScore: (json['popularity_score'] ?? 0.0).toDouble(),
      difficultyRatings: Map<String, int>.from(json['difficulty_ratings'] ?? {}),
      commonIssues: List<String>.from(json['common_issues'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_id': routeId,
      'total_completions': totalCompletions,
      'average_time': averageTime,
      'average_speed': averageSpeed,
      'popularity_score': popularityScore,
      'difficulty_ratings': difficultyRatings,
      'common_issues': commonIssues,
    };
  }
}