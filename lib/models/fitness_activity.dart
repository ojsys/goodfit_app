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
  });

  factory FitnessActivity.fromJson(Map<String, dynamic> json) {
    return FitnessActivity(
      id: json['id'],
      activityType: json['activity_type'],
      name: json['name'],
      durationMinutes: json['duration_minutes'],
      distanceKm: json['distance_km']?.toDouble(),
      caloriesBurned: json['calories_burned'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      startLocation: json['start_location'],
      endLocation: json['end_location'],
      startLatitude: json['start_latitude']?.toDouble(),
      startLongitude: json['start_longitude']?.toDouble(),
      endLatitude: json['end_latitude']?.toDouble(),
      endLongitude: json['end_longitude']?.toDouble(),
      routeData: json['route_data'],
      isCompleted: json['is_completed'] ?? true,
    );
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
}