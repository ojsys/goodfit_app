import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class GPSTrackingService extends ChangeNotifier {
  static final GPSTrackingService _instance = GPSTrackingService._internal();
  factory GPSTrackingService() => _instance;
  GPSTrackingService._internal();

  // Tracking state
  bool _isTracking = false;
  bool _isPaused = false;
  DateTime? _startTime;
  DateTime? _pausedTime;
  Duration _pausedDuration = Duration.zero;
  
  // GPS data
  Position? _currentPosition;
  List<Position> _trackingPoints = [];
  StreamSubscription<Position>? _positionStream;
  
  // Calculated metrics
  double _totalDistance = 0.0; // in meters
  double _currentSpeed = 0.0; // in m/s
  double _averageSpeed = 0.0; // in m/s
  double _currentPace = 0.0; // in min/km
  double _averagePace = 0.0; // in min/km
  int _elevationGain = 0;
  int _elevationLoss = 0;
  
  // Settings
  int _gpsUpdateInterval = 5000; // milliseconds
  double _minDistanceFilter = 2.0; // meters - minimum distance between updates
  
  // Getters
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  DateTime? get startTime => _startTime;
  Position? get currentPosition => _currentPosition;
  List<Position> get trackingPoints => List.unmodifiable(_trackingPoints);
  
  // Metrics getters
  double get totalDistanceKm => _totalDistance / 1000;
  double get currentSpeedKmh => _currentSpeed * 3.6;
  double get averageSpeedKmh => _averageSpeed * 3.6;
  double get currentPaceMinPerKm => _currentPace;
  double get averagePaceMinPerKm => _averagePace;
  int get elevationGain => _elevationGain;
  int get elevationLoss => _elevationLoss;
  
  Duration get elapsedTime {
    if (_startTime == null) return Duration.zero;
    
    final now = DateTime.now();
    final totalElapsed = now.difference(_startTime!);
    
    if (_isPaused && _pausedTime != null) {
      final currentPauseDuration = now.difference(_pausedTime!);
      return totalElapsed - _pausedDuration - currentPauseDuration;
    }
    
    return totalElapsed - _pausedDuration;
  }
  
  String get elapsedTimeFormatted {
    final elapsed = elapsedTime;
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    final seconds = elapsed.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Check and request necessary permissions
  Future<bool> checkPermissions() async {
    // Check location permission
    final locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) {
      final result = await Permission.location.request();
      if (!result.isGranted) {
        return false;
      }
    }

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check location permission with Geolocator
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Start GPS tracking
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    // Check permissions
    if (!await checkPermissions()) {
      return false;
    }

    try {
      // Reset tracking data
      _reset();
      
      _isTracking = true;
      _isPaused = false;
      _startTime = DateTime.now();
      
      // Get initial position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (_currentPosition != null) {
        _trackingPoints.add(_currentPosition!);
      }

      // Start position stream
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // minimum 2 meters between updates
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onPositionUpdate,
        onError: _onPositionError,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error starting GPS tracking: $e');
      _isTracking = false;
      notifyListeners();
      return false;
    }
  }

  /// Pause tracking
  void pauseTracking() {
    if (!_isTracking || _isPaused) return;
    
    _isPaused = true;
    _pausedTime = DateTime.now();
    _positionStream?.pause();
    
    notifyListeners();
  }

  /// Resume tracking
  void resumeTracking() {
    if (!_isTracking || !_isPaused) return;
    
    if (_pausedTime != null) {
      _pausedDuration += DateTime.now().difference(_pausedTime!);
    }
    
    _isPaused = false;
    _pausedTime = null;
    _positionStream?.resume();
    
    notifyListeners();
  }

  /// Stop tracking
  Future<Map<String, dynamic>> stopTracking() async {
    if (!_isTracking) return {};

    _isTracking = false;
    _isPaused = false;
    
    await _positionStream?.cancel();
    _positionStream = null;

    // Calculate final metrics
    final finalMetrics = _calculateFinalMetrics();
    
    notifyListeners();
    return finalMetrics;
  }

  /// Handle position updates
  void _onPositionUpdate(Position position) {
    if (!_isTracking || _isPaused) return;

    final previousPosition = _currentPosition;
    _currentPosition = position;
    
    // Add to tracking points
    _trackingPoints.add(position);

    if (previousPosition != null) {
      // Calculate distance between points
      final distance = Geolocator.distanceBetween(
        previousPosition.latitude,
        previousPosition.longitude,
        position.latitude,
        position.longitude,
      );

      // Only update if movement is significant (reduce GPS noise)
      if (distance >= _minDistanceFilter) {
        _totalDistance += distance;
        
        // Calculate current speed (m/s)
        final timeDiff = position.timestamp!.difference(previousPosition.timestamp!);
        if (timeDiff.inSeconds > 0) {
          _currentSpeed = distance / timeDiff.inSeconds;
        }

        // Calculate pace (min/km)
        if (_currentSpeed > 0) {
          _currentPace = (1000 / _currentSpeed) / 60; // Convert to min/km
        }

        // Calculate average metrics
        _calculateAverageMetrics();
        
        // Calculate elevation changes
        _calculateElevationChanges(previousPosition, position);

        notifyListeners();
      }
    }
  }

  /// Handle position stream errors
  void _onPositionError(dynamic error) {
    debugPrint('GPS tracking error: $error');
    // Continue tracking despite errors
  }

  /// Calculate average speed and pace
  void _calculateAverageMetrics() {
    final elapsed = elapsedTime;
    
    if (elapsed.inSeconds > 0 && _totalDistance > 0) {
      _averageSpeed = _totalDistance / elapsed.inSeconds;
      _averagePace = (1000 / _averageSpeed) / 60; // min/km
    }
  }

  /// Calculate elevation gain and loss
  void _calculateElevationChanges(Position previous, Position current) {
    if (previous.altitude != null && current.altitude != null) {
      final elevationDiff = current.altitude! - previous.altitude!;
      
      if (elevationDiff > 1) { // Minimum 1 meter threshold
        _elevationGain += elevationDiff.round();
      } else if (elevationDiff < -1) {
        _elevationLoss += (-elevationDiff).round();
      }
    }
  }

  /// Calculate final metrics for completed activity
  Map<String, dynamic> _calculateFinalMetrics() {
    final elapsed = elapsedTime;
    
    return {
      'distance_km': totalDistanceKm,
      'duration_seconds': elapsed.inSeconds,
      'average_speed_kmh': averageSpeedKmh,
      'average_pace_min_per_km': averagePaceMinPerKm,
      'elevation_gain': elevationGain,
      'elevation_loss': elevationLoss,
      'total_points': _trackingPoints.length,
      'start_time': _startTime?.toIso8601String(),
      'end_time': DateTime.now().toIso8601String(),
      'coordinates': _trackingPoints.map((p) => {
        'lat': p.latitude,
        'lng': p.longitude,
        'altitude': p.altitude,
        'timestamp': p.timestamp?.millisecondsSinceEpoch,
        'accuracy': p.accuracy,
        'speed': p.speed,
      }).toList(),
    };
  }

  /// Get current live metrics for real-time updates
  Map<String, dynamic> getCurrentMetrics() {
    return {
      'distance': totalDistanceKm,
      'duration': elapsedTime.inSeconds,
      'current_speed': currentSpeedKmh,
      'average_speed': averageSpeedKmh,
      'current_pace': currentPaceMinPerKm,
      'average_pace': averagePaceMinPerKm,
      'elevation_gain': elevationGain,
      'elevation_loss': elevationLoss,
      'is_tracking': isTracking,
      'is_paused': isPaused,
    };
  }

  /// Reset all tracking data
  void _reset() {
    _totalDistance = 0.0;
    _currentSpeed = 0.0;
    _averageSpeed = 0.0;
    _currentPace = 0.0;
    _averagePace = 0.0;
    _elevationGain = 0;
    _elevationLoss = 0;
    _trackingPoints.clear();
    _currentPosition = null;
    _startTime = null;
    _pausedTime = null;
    _pausedDuration = Duration.zero;
  }

  /// Update GPS settings
  void updateGPSSettings({
    int? updateInterval,
    double? minDistanceFilter,
  }) {
    if (updateInterval != null) {
      _gpsUpdateInterval = updateInterval;
    }
    if (minDistanceFilter != null) {
      _minDistanceFilter = minDistanceFilter;
    }
  }

  /// Get estimated calories burned (basic calculation)
  int getEstimatedCalories({double weightKg = 70.0}) {
    // Basic MET calculation
    // Running: ~10 METs, Walking: ~3.5 METs
    final avgSpeedKmh = averageSpeedKmh;
    final timeHours = elapsedTime.inSeconds / 3600.0;
    
    double met;
    if (avgSpeedKmh > 8) {
      met = 10.0; // Running
    } else if (avgSpeedKmh > 5) {
      met = 6.0; // Jogging
    } else {
      met = 3.5; // Walking
    }
    
    // Calories = MET × weight (kg) × time (hours)
    return (met * weightKg * timeHours).round();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}