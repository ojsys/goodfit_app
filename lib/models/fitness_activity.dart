class FitnessActivity {
  final int id;
  final String activityType;
  final String? name;
  final int durationMinutes;
  final double? distanceKm;
  final int? caloriesBurned;
  final DateTime startTime;
  final DateTime? endTime;
  final String? startLocation;
  final String? endLocation;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final String? routeData;
  final bool isCompleted;
  
  // Goal linking fields
  final List<int> linkedGoalIds;
  
  // Live tracking fields
  final bool isLiveTracked;
  final String trackingStatus; // 'not_started', 'in_progress', 'paused', 'completed'
  final DateTime? trackingStartedAt;
  final List<Map<String, dynamic>>? liveCoordinates; // [[lat, lng, timestamp], ...]
  final Map<String, dynamic>? liveMetrics; // real-time distance, pace, speed, etc.

  FitnessActivity({
    required this.id,
    required this.activityType,
    this.name,
    required this.durationMinutes,
    this.distanceKm,
    this.caloriesBurned,
    required this.startTime,
    this.endTime,
    this.startLocation,
    this.endLocation,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.routeData,
    this.isCompleted = true,
    this.linkedGoalIds = const [],
    this.isLiveTracked = false,
    this.trackingStatus = 'not_started',
    this.trackingStartedAt,
    this.liveCoordinates,
    this.liveMetrics,
  });

  factory FitnessActivity.fromJson(Map<String, dynamic> json) {
    return FitnessActivity(
      id: json['id'] ?? 0,
      // Handle nested activity_type object or direct string
      activityType: json['activity_type'] is Map 
          ? json['activity_type']['name'] ?? json['activity_type']['slug'] ?? 'Unknown'
          : (json['activity_type'] ?? 'Unknown'),
      name: json['name'],
      // Handle duration - could be in different formats
      durationMinutes: _parseDuration(json['duration']) ?? json['duration_minutes'] ?? 0,
      distanceKm: json['distance_km']?.toDouble() ?? (json['distance'] != null ? (json['distance'] / 1000.0) : null),
      caloriesBurned: json['calories'] ?? json['calories_burned'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      // Handle location fields - backend uses different names
      startLocation: json['start_location'] ?? json['start_location_name'],
      endLocation: json['end_location'] ?? json['end_location_name'],
      startLatitude: json['start_latitude']?.toDouble(),
      startLongitude: json['start_longitude']?.toDouble(),
      endLatitude: json['end_latitude']?.toDouble(),
      endLongitude: json['end_longitude']?.toDouble(),
      routeData: json['route_data'],
      isCompleted: json['is_completed'] ?? true,
      
      // Goal linking fields
      linkedGoalIds: _parseLinkedGoalIds(json['linked_goal_ids']),
      
      // Live tracking fields
      isLiveTracked: json['is_live_tracked'] ?? false,
      trackingStatus: json['tracking_status'] ?? 'not_started',
      trackingStartedAt: json['tracking_started_at'] != null 
          ? DateTime.parse(json['tracking_started_at']) 
          : null,
      liveCoordinates: _parseLiveCoordinates(json['live_coordinates']),
      liveMetrics: json['live_metrics'] is Map<String, dynamic> 
          ? Map<String, dynamic>.from(json['live_metrics']) 
          : null,
    );
  }

  // Helper method to parse duration from Django format
  static int? _parseDuration(dynamic duration) {
    if (duration == null) return null;
    if (duration is int) return duration;
    if (duration is String) {
      // Django TimeDelta format: "01:30:00" or similar
      final parts = duration.split(':');
      if (parts.length >= 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = int.tryParse(parts[2].split('.')[0]) ?? 0;
        return (hours * 60) + minutes + (seconds > 30 ? 1 : 0); // Round seconds to minutes
      }
    }
    return null;
  }

  // Helper method to parse linked goal IDs
  static List<int> _parseLinkedGoalIds(dynamic goalIds) {
    if (goalIds == null) return [];
    if (goalIds is List) {
      return goalIds.map<int>((id) => int.tryParse(id.toString()) ?? 0).toList();
    }
    return [];
  }

  // Helper method to parse live coordinates
  static List<Map<String, dynamic>>? _parseLiveCoordinates(dynamic coordinates) {
    if (coordinates == null) return null;
    if (coordinates is List) {
      return coordinates.map<Map<String, dynamic>>((coord) {
        if (coord is List && coord.length >= 3) {
          return {
            'lat': coord[0]?.toDouble() ?? 0.0,
            'lng': coord[1]?.toDouble() ?? 0.0,
            'timestamp': coord[2]?.toString() ?? '',
          };
        }
        return {'lat': 0.0, 'lng': 0.0, 'timestamp': ''};
      }).toList();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_type': activityType,
      'name': name,
      'duration_minutes': durationMinutes,
      'distance_km': distanceKm,
      'calories_burned': caloriesBurned,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'start_location': startLocation,
      'end_location': endLocation,
      'start_latitude': startLatitude,
      'start_longitude': startLongitude,
      'end_latitude': endLatitude,
      'end_longitude': endLongitude,
      'route_data': routeData,
      'is_completed': isCompleted,
      
      // Goal linking fields
      'linked_goal_ids': linkedGoalIds,
      
      // Live tracking fields
      'is_live_tracked': isLiveTracked,
      'tracking_status': trackingStatus,
      'tracking_started_at': trackingStartedAt?.toIso8601String(),
      'live_coordinates': liveCoordinates,
      'live_metrics': liveMetrics,
    };
  }

  String get locationSummary {
    if (startLocation != null && endLocation != null) {
      return '$startLocation → $endLocation';
    } else if (startLocation != null) {
      return 'From $startLocation';
    } else if (endLocation != null) {
      return 'To $endLocation';
    }
    return '';
  }

  String get durationDisplay {
    if (durationMinutes < 60) {
      return '${durationMinutes}m';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }
  
  // Goal-related helper methods
  bool get hasLinkedGoals => linkedGoalIds.isNotEmpty;
  
  bool isLinkedToGoal(int goalId) => linkedGoalIds.contains(goalId);
  
  // Live tracking helper methods
  bool get isCurrentlyTracking => isLiveTracked && trackingStatus == 'in_progress';
  
  bool get isTrackingPaused => isLiveTracked && trackingStatus == 'paused';
  
  bool get isTrackingCompleted => trackingStatus == 'completed';
  
  // Get current live distance in km
  double? get currentLiveDistance {
    if (liveMetrics != null && liveMetrics!.containsKey('distance')) {
      return liveMetrics!['distance']?.toDouble();
    }
    return null;
  }
  
  // Get current live pace (minutes per km)
  double? get currentLivePace {
    if (liveMetrics != null && liveMetrics!.containsKey('pace')) {
      return liveMetrics!['pace']?.toDouble();
    }
    return null;
  }
  
  // Get current live speed (km/h)
  double? get currentLiveSpeed {
    if (liveMetrics != null && liveMetrics!.containsKey('speed')) {
      return liveMetrics!['speed']?.toDouble();
    }
    return null;
  }
  
  // Get tracking duration in minutes
  int get trackingDurationMinutes {
    if (trackingStartedAt != null) {
      final now = DateTime.now();
      return now.difference(trackingStartedAt!).inMinutes;
    }
    return 0;
  }
}