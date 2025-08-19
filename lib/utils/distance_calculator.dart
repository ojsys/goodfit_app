import 'dart:math';

class DistanceCalculator {
  static const double _earthRadius = 6371.0; // Earth's radius in kilometers

  /// Calculate the distance between two points using the Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = _earthRadius * c;

    return distance;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceKm.round()}km';
    }
  }

  /// Estimate calories burned based on activity type, duration, and distance
  static int estimateCalories({
    required String activityType,
    required int durationMinutes,
    double? distanceKm,
    double weightKg = 70.0, // Default weight
  }) {
    // MET (Metabolic Equivalent of Task) values for different activities
    double met;
    
    switch (activityType.toLowerCase()) {
      case 'running':
      case 'jogging':
        // Calculate MET based on pace if distance is available
        if (distanceKm != null && durationMinutes > 0) {
          final paceMinPerKm = durationMinutes / distanceKm;
          if (paceMinPerKm < 4) { // Very fast pace
            met = 15.0;
          } else if (paceMinPerKm < 5) { // Fast pace
            met = 12.0;
          } else if (paceMinPerKm < 6) { // Moderate pace
            met = 9.5;
          } else { // Slow pace
            met = 7.0;
          }
        } else {
          met = 9.5; // Default running MET
        }
        break;
      case 'cycling':
      case 'biking':
        if (distanceKm != null && durationMinutes > 0) {
          final speedKmh = (distanceKm / durationMinutes) * 60;
          if (speedKmh > 25) { // Fast cycling
            met = 12.0;
          } else if (speedKmh > 20) { // Moderate cycling
            met = 8.0;
          } else { // Leisure cycling
            met = 6.0;
          }
        } else {
          met = 8.0; // Default cycling MET
        }
        break;
      case 'walking':
        met = 3.8;
        break;
      case 'hiking':
        met = 6.0;
        break;
      case 'swimming':
        met = 8.0;
        break;
      case 'yoga':
        met = 3.0;
        break;
      case 'strength training':
      case 'weight lifting':
        met = 6.0;
        break;
      default:
        met = 5.0; // Default moderate activity
    }

    // Formula: Calories = MET × weight(kg) × time(hours)
    final hours = durationMinutes / 60.0;
    return (met * weightKg * hours).round();
  }

  /// Estimate steps based on activity type and distance
  static int estimateSteps({
    required String activityType,
    required int durationMinutes,
    double? distanceKm,
  }) {
    if (distanceKm != null) {
      // Approximate steps per kilometer
      switch (activityType.toLowerCase()) {
        case 'running':
        case 'jogging':
          return (distanceKm * 1250).round(); // ~1250 steps per km running
        case 'walking':
          return (distanceKm * 1300).round(); // ~1300 steps per km walking
        default:
          return (distanceKm * 1000).round(); // General estimate
      }
    } else {
      // Estimate based on duration for activities without distance
      switch (activityType.toLowerCase()) {
        case 'running':
        case 'jogging':
          return durationMinutes * 150; // ~150 steps per minute running
        case 'walking':
          return durationMinutes * 100; // ~100 steps per minute walking
        default:
          return durationMinutes * 50; // General estimate for other activities
      }
    }
  }
}