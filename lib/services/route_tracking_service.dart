import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import '../models/route.dart' as route_model;
import 'gps_tracking_service.dart';
import 'map_service.dart';

class RouteTrackingService extends ChangeNotifier {
  static final RouteTrackingService _instance = RouteTrackingService._internal();
  factory RouteTrackingService() => _instance;
  RouteTrackingService._internal();

  final GPSTrackingService _gpsService = GPSTrackingService();
  final MapService _mapService = MapService();
  final PolylinePoints _polylinePoints = PolylinePoints();

  // Current route tracking state
  route_model.Route? _currentRoute;
  List<LatLng> _routePoints = [];
  List<LatLng> _userTrackingPoints = [];
  
  // Route following
  int _currentRouteSegment = 0;
  double _distanceFromRoute = 0.0;
  bool _isOffRoute = false;
  LatLng? _nextWaypoint;
  double _distanceToNextWaypoint = 0.0;
  
  // Analytics
  double _routeCompletion = 0.0;
  double _totalDeviation = 0.0;
  int _offRouteCount = 0;
  Duration _offRouteDuration = Duration.zero;
  DateTime? _lastOffRouteTime;
  
  // Settings
  double _maxDeviationDistance = 50.0; // meters
  double _waypointRadius = 20.0; // meters
  bool _autoRecalculateRoute = true;
  
  // Real-time updates
  Timer? _analysisTimer;
  StreamSubscription<Position>? _positionSubscription;

  // Getters
  route_model.Route? get currentRoute => _currentRoute;
  List<LatLng> get routePoints => List.unmodifiable(_routePoints);
  List<LatLng> get userTrackingPoints => List.unmodifiable(_userTrackingPoints);
  int get currentRouteSegment => _currentRouteSegment;
  double get distanceFromRoute => _distanceFromRoute;
  bool get isOffRoute => _isOffRoute;
  LatLng? get nextWaypoint => _nextWaypoint;
  double get distanceToNextWaypoint => _distanceToNextWaypoint;
  double get routeCompletion => _routeCompletion;
  double get averageDeviation => _offRouteCount > 0 ? _totalDeviation / _offRouteCount : 0.0;
  int get offRouteCount => _offRouteCount;
  Duration get offRouteDuration => _offRouteDuration;

  /// Start tracking a specific route
  Future<bool> startRouteTracking(route_model.Route route) async {
    try {
      _currentRoute = route;
      _resetTrackingState();
      
      // Decode route polyline to get points
      await _loadRoutePoints();
      
      if (_routePoints.isEmpty) {
        debugPrint('No route points available for tracking');
        return false;
      }
      
      // Start GPS tracking
      final gpsStarted = await _gpsService.startTracking();
      if (!gpsStarted) {
        debugPrint('Failed to start GPS for route tracking');
        return false;
      }
      
      // Start position monitoring
      _startPositionMonitoring();
      
      // Start analysis timer
      _startAnalysisTimer();
      
      // Display route on map
      await _displayRouteOnMap();
      
      notifyListeners();
      return true;
      
    } catch (e) {
      debugPrint('Error starting route tracking: $e');
      return false;
    }
  }

  /// Stop route tracking
  Future<RouteTrackingAnalytics> stopRouteTracking() async {
    await _positionSubscription?.cancel();
    _analysisTimer?.cancel();
    
    final analytics = _generateAnalytics();
    
    _resetTrackingState();
    notifyListeners();
    
    return analytics;
  }

  /// Load route points from polyline or coordinates
  Future<void> _loadRoutePoints() async {
    if (_currentRoute == null) return;
    
    if (_currentRoute!.coordinates != null && _currentRoute!.coordinates!.isNotEmpty) {
      _routePoints = _currentRoute!.coordinates!;
    } else if (_currentRoute!.polyline.isNotEmpty) {
      try {
        final decodedPoints = _polylinePoints.decodePolyline(_currentRoute!.polyline);
        _routePoints = decodedPoints
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      } catch (e) {
        debugPrint('Error decoding polyline: $e');
        _routePoints = [];
      }
    }
    
    if (_routePoints.isNotEmpty) {
      _nextWaypoint = _routePoints.first;
      _updateDistanceToNextWaypoint();
    }
  }

  /// Start monitoring GPS position updates
  void _startPositionMonitoring() {
    _positionSubscription = _gpsService.trackingPoints.isNotEmpty
        ? Stream.periodic(const Duration(seconds: 1))
            .where((_) => _gpsService.trackingPoints.isNotEmpty)
            .map((_) => _gpsService.trackingPoints.last)
            .listen(_onPositionUpdate)
        : null;
  }

  /// Handle position updates
  void _onPositionUpdate(Position position) {
    if (_currentRoute == null || _routePoints.isEmpty) return;
    
    final currentLocation = LatLng(position.latitude, position.longitude);
    _userTrackingPoints.add(currentLocation);
    
    // Update route analysis
    _analyzePosition(currentLocation);
    
    // Update map
    _updateMapPolylines(currentLocation);
  }

  /// Analyze current position relative to route
  void _analyzePosition(LatLng currentLocation) {
    if (_routePoints.isEmpty) return;
    
    // Find closest point on route
    final closestPointResult = _findClosestPointOnRoute(currentLocation);
    final closestPoint = closestPointResult['point'] as LatLng;
    final segmentIndex = closestPointResult['segment'] as int;
    
    // Calculate distance from route
    _distanceFromRoute = Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      closestPoint.latitude,
      closestPoint.longitude,
    );
    
    // Update route segment
    _currentRouteSegment = segmentIndex;
    
    // Check if off route
    final wasOffRoute = _isOffRoute;
    _isOffRoute = _distanceFromRoute > _maxDeviationDistance;
    
    if (_isOffRoute && !wasOffRoute) {
      _lastOffRouteTime = DateTime.now();
      _offRouteCount++;
    } else if (!_isOffRoute && wasOffRoute && _lastOffRouteTime != null) {
      _offRouteDuration += DateTime.now().difference(_lastOffRouteTime!);
    }
    
    if (_isOffRoute) {
      _totalDeviation += _distanceFromRoute;
    }
    
    // Update progress
    _updateRouteProgress();
    
    // Update next waypoint
    _updateNextWaypoint();
    
    notifyListeners();
  }

  /// Find closest point on route
  Map<String, dynamic> _findClosestPointOnRoute(LatLng userLocation) {
    double minDistance = double.infinity;
    LatLng closestPoint = _routePoints.first;
    int closestSegment = 0;
    
    for (int i = 0; i < _routePoints.length - 1; i++) {
      final segmentStart = _routePoints[i];
      final segmentEnd = _routePoints[i + 1];
      
      final closestOnSegment = _getClosestPointOnSegment(
        userLocation,
        segmentStart,
        segmentEnd,
      );
      
      final distance = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        closestOnSegment.latitude,
        closestOnSegment.longitude,
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = closestOnSegment;
        closestSegment = i;
      }
    }
    
    return {
      'point': closestPoint,
      'segment': closestSegment,
      'distance': minDistance,
    };
  }

  /// Get closest point on a line segment
  LatLng _getClosestPointOnSegment(LatLng point, LatLng lineStart, LatLng lineEnd) {
    final dx = lineEnd.longitude - lineStart.longitude;
    final dy = lineEnd.latitude - lineStart.latitude;
    
    if (dx == 0 && dy == 0) {
      return lineStart; // Line segment is just a point
    }
    
    final t = ((point.longitude - lineStart.longitude) * dx + 
               (point.latitude - lineStart.latitude) * dy) / 
               (dx * dx + dy * dy);
    
    final clampedT = math.max(0, math.min(1, t));
    
    return LatLng(
      lineStart.latitude + clampedT * dy,
      lineStart.longitude + clampedT * dx,
    );
  }

  /// Update route completion progress
  void _updateRouteProgress() {
    if (_routePoints.isEmpty || _currentRouteSegment >= _routePoints.length) return;
    
    double completedDistance = 0.0;
    
    // Calculate distance of completed segments
    for (int i = 0; i < _currentRouteSegment; i++) {
      if (i + 1 < _routePoints.length) {
        completedDistance += Geolocator.distanceBetween(
          _routePoints[i].latitude,
          _routePoints[i].longitude,
          _routePoints[i + 1].latitude,
          _routePoints[i + 1].longitude,
        );
      }
    }
    
    _routeCompletion = _currentRoute != null 
        ? (completedDistance / _currentRoute!.distance).clamp(0.0, 1.0)
        : 0.0;
  }

  /// Update next waypoint
  void _updateNextWaypoint() {
    if (_routePoints.isEmpty) return;
    
    // Look ahead for next significant waypoint
    final lookAheadDistance = 100.0; // meters
    double accumulatedDistance = 0.0;
    
    for (int i = _currentRouteSegment; i < _routePoints.length - 1; i++) {
      final segmentDistance = Geolocator.distanceBetween(
        _routePoints[i].latitude,
        _routePoints[i].longitude,
        _routePoints[i + 1].latitude,
        _routePoints[i + 1].longitude,
      );
      
      accumulatedDistance += segmentDistance;
      
      if (accumulatedDistance >= lookAheadDistance) {
        _nextWaypoint = _routePoints[i + 1];
        break;
      }
    }
    
    _updateDistanceToNextWaypoint();
  }

  /// Update distance to next waypoint
  void _updateDistanceToNextWaypoint() {
    if (_nextWaypoint == null || _gpsService.currentPosition == null) {
      _distanceToNextWaypoint = 0.0;
      return;
    }
    
    _distanceToNextWaypoint = Geolocator.distanceBetween(
      _gpsService.currentPosition!.latitude,
      _gpsService.currentPosition!.longitude,
      _nextWaypoint!.latitude,
      _nextWaypoint!.longitude,
    );
  }

  /// Start analysis timer for periodic updates
  void _startAnalysisTimer() {
    _analysisTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_gpsService.currentPosition != null) {
        _updateDistanceToNextWaypoint();
        notifyListeners();
      }
    });
  }

  /// Display route on map
  Future<void> _displayRouteOnMap() async {
    if (_currentRoute == null || _routePoints.isEmpty) return;
    
    // Create route polyline
    final routePolyline = Polyline(
      polylineId: const PolylineId('route_path'),
      points: _routePoints,
      color: Colors.blue,
      width: 4,
      patterns: [PatternItem.dash(10), PatternItem.gap(5)],
    );
    
    _mapService.addPolyline(routePolyline);
    
    // Add route markers
    if (_routePoints.isNotEmpty) {
      final startMarker = Marker(
        markerId: const MarkerId('route_start'),
        position: _routePoints.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Start',
          snippet: _currentRoute!.startLocationName,
        ),
      );
      
      final endMarker = Marker(
        markerId: const MarkerId('route_end'),
        position: _routePoints.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Finish',
          snippet: _currentRoute!.endLocationName,
        ),
      );
      
      _mapService.addMarker(startMarker);
      _mapService.addMarker(endMarker);
    }
  }

  /// Update map polylines with user tracking
  void _updateMapPolylines(LatLng currentLocation) {
    if (_userTrackingPoints.isEmpty) return;
    
    // Update user tracking polyline
    final userPolyline = Polyline(
      polylineId: const PolylineId('user_path'),
      points: _userTrackingPoints,
      color: _isOffRoute ? Colors.red : Colors.green,
      width: 6,
    );
    
    _mapService.addPolyline(userPolyline);
    
    // Update current position marker
    final currentMarker = Marker(
      markerId: const MarkerId('current_position'),
      position: currentLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(
        _isOffRoute ? BitmapDescriptor.hueRed : BitmapDescriptor.hueBlue,
      ),
    );
    
    _mapService.addMarker(currentMarker);
  }

  /// Generate analytics report
  RouteTrackingAnalytics _generateAnalytics() {
    return RouteTrackingAnalytics(
      route: _currentRoute,
      userPath: List.from(_userTrackingPoints),
      routeCompletion: _routeCompletion,
      averageDeviation: averageDeviation,
      maxDeviation: _totalDeviation > 0 ? _totalDeviation / _offRouteCount : 0,
      offRouteCount: _offRouteCount,
      offRouteDuration: _offRouteDuration,
      totalDistance: _calculateTotalUserDistance(),
      routeEfficiency: _calculateRouteEfficiency(),
    );
  }

  /// Calculate total distance traveled by user
  double _calculateTotalUserDistance() {
    double totalDistance = 0.0;
    
    for (int i = 0; i < _userTrackingPoints.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        _userTrackingPoints[i].latitude,
        _userTrackingPoints[i].longitude,
        _userTrackingPoints[i + 1].latitude,
        _userTrackingPoints[i + 1].longitude,
      );
    }
    
    return totalDistance;
  }

  /// Calculate route following efficiency
  double _calculateRouteEfficiency() {
    if (_currentRoute == null || _userTrackingPoints.isEmpty) return 0.0;
    
    final userDistance = _calculateTotalUserDistance();
    final routeDistance = _currentRoute!.distance;
    
    return routeDistance > 0 ? (routeDistance / userDistance).clamp(0.0, 1.0) : 0.0;
  }

  /// Reset tracking state
  void _resetTrackingState() {
    _currentRoute = null;
    _routePoints.clear();
    _userTrackingPoints.clear();
    _currentRouteSegment = 0;
    _distanceFromRoute = 0.0;
    _isOffRoute = false;
    _nextWaypoint = null;
    _distanceToNextWaypoint = 0.0;
    _routeCompletion = 0.0;
    _totalDeviation = 0.0;
    _offRouteCount = 0;
    _offRouteDuration = Duration.zero;
    _lastOffRouteTime = null;
    
    _positionSubscription?.cancel();
    _analysisTimer?.cancel();
  }

  /// Get turn-by-turn guidance
  String getTurnGuidance() {
    if (_nextWaypoint == null || _distanceToNextWaypoint == 0) {
      return 'Follow the route';
    }
    
    if (_distanceToNextWaypoint < _waypointRadius) {
      return 'Waypoint reached';
    } else if (_distanceToNextWaypoint < 50) {
      return 'Approaching waypoint in ${_distanceToNextWaypoint.round()}m';
    } else {
      return 'Continue ${_distanceToNextWaypoint.round()}m to next waypoint';
    }
  }

  @override
  void dispose() {
    stopRouteTracking();
    super.dispose();
  }
}

class RouteTrackingAnalytics {
  final route_model.Route? route;
  final List<LatLng> userPath;
  final double routeCompletion;
  final double averageDeviation;
  final double maxDeviation;
  final int offRouteCount;
  final Duration offRouteDuration;
  final double totalDistance;
  final double routeEfficiency;

  const RouteTrackingAnalytics({
    required this.route,
    required this.userPath,
    required this.routeCompletion,
    required this.averageDeviation,
    required this.maxDeviation,
    required this.offRouteCount,
    required this.offRouteDuration,
    required this.totalDistance,
    required this.routeEfficiency,
  });

  Map<String, dynamic> toJson() {
    return {
      'route_id': route?.id,
      'route_completion': routeCompletion,
      'average_deviation': averageDeviation,
      'max_deviation': maxDeviation,
      'off_route_count': offRouteCount,
      'off_route_duration_seconds': offRouteDuration.inSeconds,
      'total_distance_meters': totalDistance,
      'route_efficiency': routeEfficiency,
      'user_path': userPath.map((p) => [p.latitude, p.longitude]).toList(),
    };
  }
}