class FitnessRoute {
  final int id;
  final String name;
  final String description;
  final String activityType;
  final double distanceKm;
  final int elevationGain;
  final String difficulty; // 'easy', 'moderate', 'hard'
  final double rating;
  final int ratingCount;
  final String? routeData; // Encoded polyline or GPS coordinates
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;
  final String? startLocation;
  final String? endLocation;
  final int createdByUserId;
  final String? createdByUserName;
  final DateTime createdDate;
  final bool isPublic;
  final bool isFavorite;
  final int timesUsed;

  FitnessRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.activityType,
    required this.distanceKm,
    required this.elevationGain,
    required this.difficulty,
    required this.rating,
    required this.ratingCount,
    this.routeData,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
    this.startLocation,
    this.endLocation,
    required this.createdByUserId,
    this.createdByUserName,
    required this.createdDate,
    required this.isPublic,
    required this.isFavorite,
    required this.timesUsed,
  });

  factory FitnessRoute.fromJson(Map<String, dynamic> json) {
    return FitnessRoute(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      activityType: json['activity_type'],
      distanceKm: json['distance_km']?.toDouble() ?? 0.0,
      elevationGain: json['elevation_gain'] ?? 0,
      difficulty: json['difficulty'],
      rating: json['rating']?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] ?? 0,
      routeData: json['route_data'],
      startLatitude: json['start_latitude']?.toDouble() ?? 0.0,
      startLongitude: json['start_longitude']?.toDouble() ?? 0.0,
      endLatitude: json['end_latitude']?.toDouble() ?? 0.0,
      endLongitude: json['end_longitude']?.toDouble() ?? 0.0,
      startLocation: json['start_location'],
      endLocation: json['end_location'],
      createdByUserId: json['created_by_user_id'],
      createdByUserName: json['created_by_user_name'],
      createdDate: DateTime.parse(json['created_date']),
      isPublic: json['is_public'] ?? false,
      isFavorite: json['is_favorite'] ?? false,
      timesUsed: json['times_used'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'activity_type': activityType,
      'distance_km': distanceKm,
      'elevation_gain': elevationGain,
      'difficulty': difficulty,
      'rating': rating,
      'rating_count': ratingCount,
      'route_data': routeData,
      'start_latitude': startLatitude,
      'start_longitude': startLongitude,
      'end_latitude': endLatitude,
      'end_longitude': endLongitude,
      'start_location': startLocation,
      'end_location': endLocation,
      'created_by_user_id': createdByUserId,
      'created_by_user_name': createdByUserName,
      'created_date': createdDate.toIso8601String(),
      'is_public': isPublic,
      'is_favorite': isFavorite,
      'times_used': timesUsed,
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
    return '${distanceKm.toStringAsFixed(1)}km route';
  }

  String get difficultyDisplay {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'Easy';
      case 'moderate':
        return 'Moderate';
      case 'hard':
        return 'Hard';
      default:
        return difficulty;
    }
  }

  String get estimatedDuration {
    // Rough estimation based on activity type and distance
    double hoursEstimate = 0;
    switch (activityType.toLowerCase()) {
      case 'running':
        hoursEstimate = distanceKm / 10; // ~10 km/h average
        break;
      case 'cycling':
        hoursEstimate = distanceKm / 20; // ~20 km/h average
        break;
      case 'walking':
      case 'hiking':
        hoursEstimate = distanceKm / 5; // ~5 km/h average
        break;
      default:
        hoursEstimate = distanceKm / 8; // Default estimate
    }

    if (hoursEstimate < 1) {
      return '${(hoursEstimate * 60).round()} min';
    } else if (hoursEstimate < 2) {
      final minutes = ((hoursEstimate % 1) * 60).round();
      return minutes > 0 ? '1h ${minutes}min' : '1h';
    } else {
      return '${hoursEstimate.round()}h';
    }
  }
}