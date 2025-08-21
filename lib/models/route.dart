import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Route {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String polyline;
  final List<LatLng>? coordinates;
  final double distance; // in meters
  final double elevationGain;
  final double elevationLoss;
  final String surfaceType;
  final int? difficultyLevel;
  final List<String> activityTypes;
  final LatLng? startLocation;
  final LatLng? endLocation;
  final String startLocationName;
  final String endLocationName;
  final double? averagePace; // in minutes per km
  final Duration? estimatedDuration;
  final int safetyRating; // 1-5
  final int scenicRating; // 1-5
  final int timesUsed;
  final double averageRating;
  final int totalRatings;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Route({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.polyline,
    this.coordinates,
    required this.distance,
    required this.elevationGain,
    required this.elevationLoss,
    required this.surfaceType,
    this.difficultyLevel,
    required this.activityTypes,
    this.startLocation,
    this.endLocation,
    required this.startLocationName,
    required this.endLocationName,
    this.averagePace,
    this.estimatedDuration,
    required this.safetyRating,
    required this.scenicRating,
    required this.timesUsed,
    required this.averageRating,
    required this.totalRatings,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper getters
  double get distanceKm => distance / 1000;
  
  String get formattedDistance => 
      distanceKm < 1 ? '${distance.round()}m' : '${distanceKm.toStringAsFixed(1)}km';
  
  String get difficultyDescription {
    switch (difficultyLevel) {
      case 1: return 'Beginner - Easy and accessible';
      case 2: return 'Easy - Suitable for most fitness levels';
      case 3: return 'Moderate - Some challenge required';
      case 4: return 'Hard - Good fitness level needed';
      case 5: return 'Expert - Very challenging route';
      default: return 'Unknown difficulty';
    }
  }
  
  String get elevationProfile {
    final total = elevationGain + elevationLoss;
    if (total < 100) return 'Flat';
    if (total < 300) return 'Rolling';
    return 'Hilly';
  }
  
  String get formattedElevationGain => '${elevationGain.round()}m';
  
  String get formattedEstimatedDuration {
    if (estimatedDuration == null) return 'Unknown';
    final hours = estimatedDuration!.inHours;
    final minutes = estimatedDuration!.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'] ?? '',
      userId: json['user'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      polyline: json['polyline'] ?? '',
      coordinates: _parseCoordinates(json['coordinates_json']),
      distance: (json['distance'] ?? 0).toDouble(),
      elevationGain: (json['elevation_gain'] ?? 0).toDouble(),
      elevationLoss: (json['elevation_loss'] ?? 0).toDouble(),
      surfaceType: json['surface_type'] ?? '',
      difficultyLevel: json['difficulty_level'],
      activityTypes: _parseActivityTypes(json['activity_types']),
      startLocation: _parseLatLng(json['start_latitude'], json['start_longitude']),
      endLocation: _parseLatLng(json['end_latitude'], json['end_longitude']),
      startLocationName: json['start_location_name'] ?? '',
      endLocationName: json['end_location_name'] ?? '',
      averagePace: json['average_pace']?.toDouble(),
      estimatedDuration: _parseDuration(json['estimated_duration']),
      safetyRating: json['safety_rating'] ?? 3,
      scenicRating: json['scenic_rating'] ?? 3,
      timesUsed: json['times_used'] ?? 0,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalRatings: json['total_ratings'] ?? 0,
      isPublic: json['is_public'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'name': name,
      'description': description,
      'polyline': polyline,
      'coordinates_json': coordinates?.map((c) => [c.latitude, c.longitude]).toList(),
      'distance': distance,
      'elevation_gain': elevationGain,
      'elevation_loss': elevationLoss,
      'surface_type': surfaceType,
      'difficulty_level': difficultyLevel,
      'activity_types': activityTypes,
      'start_latitude': startLocation?.latitude,
      'start_longitude': startLocation?.longitude,
      'end_latitude': endLocation?.latitude,
      'end_longitude': endLocation?.longitude,
      'start_location_name': startLocationName,
      'end_location_name': endLocationName,
      'average_pace': averagePace,
      'estimated_duration': estimatedDuration?.inSeconds,
      'safety_rating': safetyRating,
      'scenic_rating': scenicRating,
      'times_used': timesUsed,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Route copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? polyline,
    List<LatLng>? coordinates,
    double? distance,
    double? elevationGain,
    double? elevationLoss,
    String? surfaceType,
    int? difficultyLevel,
    List<String>? activityTypes,
    LatLng? startLocation,
    LatLng? endLocation,
    String? startLocationName,
    String? endLocationName,
    double? averagePace,
    Duration? estimatedDuration,
    int? safetyRating,
    int? scenicRating,
    int? timesUsed,
    double? averageRating,
    int? totalRatings,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Route(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      polyline: polyline ?? this.polyline,
      coordinates: coordinates ?? this.coordinates,
      distance: distance ?? this.distance,
      elevationGain: elevationGain ?? this.elevationGain,
      elevationLoss: elevationLoss ?? this.elevationLoss,
      surfaceType: surfaceType ?? this.surfaceType,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      activityTypes: activityTypes ?? this.activityTypes,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      startLocationName: startLocationName ?? this.startLocationName,
      endLocationName: endLocationName ?? this.endLocationName,
      averagePace: averagePace ?? this.averagePace,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      safetyRating: safetyRating ?? this.safetyRating,
      scenicRating: scenicRating ?? this.scenicRating,
      timesUsed: timesUsed ?? this.timesUsed,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<LatLng>? _parseCoordinates(dynamic coordinatesJson) {
    if (coordinatesJson == null) return null;
    
    try {
      final List<dynamic> coords = coordinatesJson is String 
          ? jsonDecode(coordinatesJson) 
          : coordinatesJson;
      
      return coords.map((coord) => LatLng(
        coord[0].toDouble(), 
        coord[1].toDouble()
      )).toList();
    } catch (e) {
      return null;
    }
  }
  
  static List<String> _parseActivityTypes(dynamic activityTypes) {
    if (activityTypes == null) return [];
    
    if (activityTypes is List) {
      return activityTypes.map((type) => type.toString()).toList();
    }
    
    return [];
  }
  
  static LatLng? _parseLatLng(dynamic lat, dynamic lng) {
    if (lat == null || lng == null) return null;
    
    try {
      return LatLng(
        double.parse(lat.toString()), 
        double.parse(lng.toString())
      );
    } catch (e) {
      return null;
    }
  }
  
  static Duration? _parseDuration(dynamic duration) {
    if (duration == null) return null;
    
    try {
      if (duration is int) {
        return Duration(seconds: duration);
      }
      
      if (duration is String) {
        // Parse Django duration format (HH:MM:SS)
        final parts = duration.split(':');
        if (parts.length == 3) {
          final hours = int.parse(parts[0]);
          final minutes = int.parse(parts[1]);
          final seconds = int.parse(parts[2]);
          return Duration(hours: hours, minutes: minutes, seconds: seconds);
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Route && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Route{id: $id, name: $name, distance: $formattedDistance}';
}