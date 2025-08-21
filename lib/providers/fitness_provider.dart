import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../models/fitness_activity.dart';
import '../models/user.dart';
import '../utils/logger.dart';
import '../utils/distance_calculator.dart';

class FitnessProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<FitnessActivity> _activities = [];
  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  List<FitnessActivity> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  // Today's stats computed from activities
  int get todaysSteps => _calculateTodaysSteps();
  int get todaysCalories => _calculateTodaysCalories();
  int get todaysMinutes => _calculateTodaysMinutes();
  int get averageHeartRate => _calculateAverageHeartRate();

  void _setLoading(bool loading) {
    _isLoading = loading;
    
    // Safe state update - defer until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _setError(String? error) {
    _errorMessage = error;
    
    // Safe state update - defer until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> loadActivities() async {
    _setLoading(true);
    _setError(null);

    try {
      // Try to load from API first
      final result = await _apiService.getFitnessActivities();
      
      if (result.success && result.data != null) {
        _activities = result.data!;
        AppLogger.info('Loaded ${_activities.length} fitness activities from API', 'FitnessProvider');
      } else {
        // API failed, fallback to local storage
        AppLogger.info('API failed (${result.error}), falling back to local storage', 'FitnessProvider');
        _activities = await LocalStorageService.getActivities();
        AppLogger.info('Loaded ${_activities.length} fitness activities from local storage', 'FitnessProvider');
      }
    } catch (e) {
      // If both fail, try local storage as final fallback
      try {
        _activities = await LocalStorageService.getActivities();
        AppLogger.info('Loaded ${_activities.length} fitness activities from local storage fallback', 'FitnessProvider');
      } catch (localError) {
        _setError('Error loading activities');
        AppLogger.error('Error loading activities from both API and local storage', 'FitnessProvider', e);
        _activities = []; // Ensure activities is never null
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createActivity({
    required String activityType,
    required int durationMinutes,
    double? distanceKm,
    int? caloriesBurned,
    String? activityName,
    String? startLocation,
    String? endLocation,
    double? startLatitude,
    double? startLongitude,
    double? endLatitude,
    double? endLongitude,
    List<int> linkedGoalIds = const [],
  }) async {
    _setError(null);
    
    AppLogger.info('Creating activity: $activityType, Duration: $durationMinutes min, Name: $activityName', 'FitnessProvider');

    // Calculate distance if coordinates are provided but distance is not
    double? finalDistance = distanceKm;
    if (finalDistance == null && 
        startLatitude != null && startLongitude != null &&
        endLatitude != null && endLongitude != null) {
      finalDistance = DistanceCalculator.calculateDistance(
        startLatitude, startLongitude, endLatitude, endLongitude,
      );
    }

    // Estimate calories if not provided
    int finalCalories = caloriesBurned ?? DistanceCalculator.estimateCalories(
      activityType: activityType,
      durationMinutes: durationMinutes,
      distanceKm: finalDistance,
    );

    final activity = FitnessActivity(
      id: 0, // Will be assigned by local storage
      activityType: activityType,
      name: activityName,
      durationMinutes: durationMinutes,
      distanceKm: finalDistance,
      caloriesBurned: finalCalories,
      startTime: DateTime.now(),
      startLocation: startLocation,
      endLocation: endLocation,
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      endLatitude: endLatitude,
      endLongitude: endLongitude,
      linkedGoalIds: linkedGoalIds,
    );

    try {
      // Try API first
      final result = await _apiService.createActivity(
        activityType: activityType,
        durationMinutes: durationMinutes,
        distanceKm: finalDistance,
        caloriesBurned: finalCalories,
        activityName: activityName,
        startLocation: startLocation,
        endLocation: endLocation,
        startLatitude: startLatitude,
        startLongitude: startLongitude,
        endLatitude: endLatitude,
        endLongitude: endLongitude,
      );
      
      if (result.success && result.data != null) {
        _activities.insert(0, result.data!);
        AppLogger.info('Activity added to list. Total activities: ${_activities.length}, Today\'s activities: ${todaysActivities.length}', 'FitnessProvider');
        
        // Safe state update - defer until after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        
        AppLogger.info('Created new activity via API: $activityType', 'FitnessProvider');
        return true;
      } else {
        // Fallback to local storage
        final localSuccess = await LocalStorageService.saveActivity(activity);
        if (localSuccess) {
          await loadActivities(); // Reload to get the activity with proper ID
          AppLogger.info('Created new activity via local storage: $activityType', 'FitnessProvider');
          return true;
        } else {
          _setError('Failed to create activity');
          return false;
        }
      }
    } catch (e) {
      // Fallback to local storage
      final localSuccess = await LocalStorageService.saveActivity(activity);
      if (localSuccess) {
        await loadActivities(); // Reload to get the activity with proper ID
        AppLogger.info('Created new activity via local storage fallback: $activityType', 'FitnessProvider');
        return true;
      } else {
        _setError('Error creating activity');
        AppLogger.error('Error creating activity', 'FitnessProvider', e);
        return false;
      }
    }
  }

  List<FitnessActivity> get todaysActivities {
    final today = DateTime.now();
    return _activities.where((activity) {
      return activity.startTime.year == today.year &&
             activity.startTime.month == today.month &&
             activity.startTime.day == today.day;
    }).toList();
  }

  int _calculateTodaysSteps() {
    // For demo purposes, estimate steps based on activities
    int totalSteps = 0;
    for (final activity in todaysActivities) {
      if (activity.activityType.toLowerCase().contains('walk') ||
          activity.activityType.toLowerCase().contains('run')) {
        // Rough estimate: 100 steps per minute for walking/running
        totalSteps += activity.durationMinutes * 100;
      }
    }
    return totalSteps > 0 ? totalSteps : 2345; // Default demo value
  }

  int _calculateTodaysCalories() {
    int totalCalories = 0;
    for (final activity in todaysActivities) {
      totalCalories += activity.caloriesBurned ?? 0;
    }
    return totalCalories > 0 ? totalCalories : 280; // Default demo value
  }

  int _calculateTodaysMinutes() {
    int totalMinutes = 0;
    for (final activity in todaysActivities) {
      totalMinutes += activity.durationMinutes;
    }
    return totalMinutes > 0 ? totalMinutes : 45; // Default demo value
  }

  int _calculateAverageHeartRate() {
    // This would come from heart rate data in a real app
    // For now, return a demo value
    return 75;
  }

  void setCurrentUser(User? user) {
    if (_currentUser?.id != user?.id) {
      _currentUser = user;
      // Clear activities when user changes to ensure fresh data
      if (user == null) {
        _activities = [];
        AppLogger.info('User logged out, cleared activities', 'FitnessProvider');
      } else {
        AppLogger.info('User changed, will reload activities for user: ${user.email}', 'FitnessProvider');
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void clearError() {
    _errorMessage = null;
    
    // Safe state update - defer until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}