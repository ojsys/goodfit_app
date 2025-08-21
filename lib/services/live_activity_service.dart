import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/fitness_activity.dart';
import '../models/fitness_goal.dart';
import 'gps_tracking_service.dart';
import 'api_service.dart';

class LiveActivityService extends ChangeNotifier {
  static final LiveActivityService _instance = LiveActivityService._internal();
  factory LiveActivityService() => _instance;
  LiveActivityService._internal();

  final GPSTrackingService _gpsService = GPSTrackingService();
  final ApiService _apiService = ApiService();
  
  // Current live activity
  String? _currentActivityId;
  String? _activityType;
  String? _activityName;
  List<int> _linkedGoalIds = [];
  
  // Update timers
  Timer? _metricsUpdateTimer;
  Timer? _backendSyncTimer;
  
  // State
  bool _isLiveActivityActive = false;
  DateTime? _activityStartTime;
  
  // Milestone tracking
  Map<String, bool> _milestonesReached = {};
  
  // Getters
  bool get isLiveActivityActive => _isLiveActivityActive;
  String? get currentActivityId => _currentActivityId;
  String? get activityType => _activityType;
  String? get activityName => _activityName;
  List<int> get linkedGoalIds => List.unmodifiable(_linkedGoalIds);
  GPSTrackingService get gpsService => _gpsService;

  /// Start a live tracked activity
  Future<bool> startLiveActivity({
    required String activityType,
    required String activityName,
    List<int> linkedGoalIds = const [],
    Map<String, dynamic>? initialData,
  }) async {
    if (_isLiveActivityActive) {
      debugPrint('Live activity already active');
      return false;
    }

    try {
      // Start GPS tracking
      final gpsStarted = await _gpsService.startTracking();
      if (!gpsStarted) {
        debugPrint('Failed to start GPS tracking');
        return false;
      }

      // Create activity on backend
      final activityData = {
        'activity_type': activityType,
        'name': activityName,
        'start_time': DateTime.now().toIso8601String(),
        'duration': '00:00:00',
        'distance': 0,
        'linked_goal_ids': linkedGoalIds,
        if (initialData != null) ...initialData,
      };

      final response = await _apiService.post('/fitness/activities/start-live/', activityData);
      
      if (response.success && response.data != null) {
        _currentActivityId = response.data['activity_id'];
        _activityType = activityType;
        _activityName = activityName;
        _linkedGoalIds = List.from(linkedGoalIds);
        _isLiveActivityActive = true;
        _activityStartTime = DateTime.now();
        _milestonesReached.clear();

        // Start periodic updates
        _startPeriodicUpdates();
        
        notifyListeners();
        debugPrint('Live activity started: $_currentActivityId');
        return true;
      } else {
        // Stop GPS if backend failed
        await _gpsService.stopTracking();
        debugPrint('Failed to create live activity on backend');
        return false;
      }
    } catch (e) {
      debugPrint('Error starting live activity: $e');
      await _gpsService.stopTracking();
      return false;
    }
  }

  /// Pause the current live activity
  Future<bool> pauseLiveActivity() async {
    if (!_isLiveActivityActive || _currentActivityId == null) return false;

    try {
      _gpsService.pauseTracking();
      
      final response = await _apiService.post('/fitness/activities/$_currentActivityId/pause-live/', {});
      
      if (response.success) {
        _stopPeriodicUpdates();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error pausing live activity: $e');
      return false;
    }
  }

  /// Resume the current live activity
  Future<bool> resumeLiveActivity() async {
    if (!_isLiveActivityActive || _currentActivityId == null) return false;

    try {
      _gpsService.resumeTracking();
      
      // Update backend with current metrics
      await _syncWithBackend();
      
      _startPeriodicUpdates();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error resuming live activity: $e');
      return false;
    }
  }

  /// Complete and save the current live activity
  Future<FitnessActivity?> completeLiveActivity() async {
    if (!_isLiveActivityActive || _currentActivityId == null) return null;

    try {
      // Stop GPS tracking and get final metrics
      final finalMetrics = await _gpsService.stopTracking();
      
      // Stop periodic updates
      _stopPeriodicUpdates();

      // Send final data to backend
      final finalData = {
        'final_data': {
          'distance': finalMetrics['distance_km'],
          'duration': finalMetrics['duration_seconds'],
          'moving_time': finalMetrics['duration_seconds'], // TODO: calculate actual moving time
          'calories': _gpsService.getEstimatedCalories(),
          'average_speed_kmh': finalMetrics['average_speed_kmh'],
          'elevation_gain': finalMetrics['elevation_gain'],
          'elevation_loss': finalMetrics['elevation_loss'],
          'coordinates': finalMetrics['coordinates'],
        }
      };

      final response = await _apiService.post('/fitness/activities/$_currentActivityId/complete-live/', finalData);
      
      if (response.success && response.data != null) {
        final completedActivity = FitnessActivity.fromJson(response.data['activity']);
        
        // Reset state
        _resetState();
        
        notifyListeners();
        return completedActivity;
      } else {
        debugPrint('Failed to complete activity on backend');
        _resetState();
        return null;
      }
    } catch (e) {
      debugPrint('Error completing live activity: $e');
      _resetState();
      return null;
    }
  }

  /// Get current live metrics
  Map<String, dynamic> getCurrentLiveMetrics() {
    if (!_isLiveActivityActive) return {};
    
    final gpsMetrics = _gpsService.getCurrentMetrics();
    
    return {
      ...gpsMetrics,
      'activity_id': _currentActivityId,
      'activity_type': _activityType,
      'activity_name': _activityName,
      'start_time': _activityStartTime?.toIso8601String(),
      'linked_goals': _linkedGoalIds,
      'milestones_reached': _milestonesReached,
    };
  }

  /// Check and trigger milestone notifications
  void _checkMilestones() {
    if (!_isLiveActivityActive) return;
    
    final metrics = _gpsService.getCurrentMetrics();
    final distance = metrics['distance'] as double;
    final duration = metrics['duration'] as int;
    
    // Distance milestones (every 1km)
    final kmMilestones = [1, 2, 3, 5, 10, 15, 20, 25, 30];
    for (final km in kmMilestones) {
      final milestoneKey = 'distance_${km}km';
      if (distance >= km && !_milestonesReached.containsKey(milestoneKey)) {
        _milestonesReached[milestoneKey] = true;
        _triggerMilestoneNotification('Distance Milestone', '${km}km completed! 🎉');
      }
    }
    
    // Time milestones (every 10 minutes)
    final timeMilestones = [10, 20, 30, 45, 60, 90, 120]; // minutes
    for (final minutes in timeMilestones) {
      final milestoneKey = 'time_${minutes}min';
      if (duration >= minutes * 60 && !_milestonesReached.containsKey(milestoneKey)) {
        _milestonesReached[milestoneKey] = true;
        _triggerMilestoneNotification('Time Milestone', '${minutes} minutes completed! ⏱️');
      }
    }
  }

  /// Trigger milestone notification (override in UI layer)
  void _triggerMilestoneNotification(String title, String message) {
    debugPrint('Milestone reached: $title - $message');
    // This can be overridden by the UI layer to show actual notifications
    notifyListeners();
  }

  /// Start periodic updates to backend and milestone checking
  void _startPeriodicUpdates() {
    // Update metrics every 10 seconds
    _metricsUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkMilestones();
      notifyListeners();
    });

    // Sync with backend every 30 seconds
    _backendSyncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _syncWithBackend();
    });
  }

  /// Stop periodic updates
  void _stopPeriodicUpdates() {
    _metricsUpdateTimer?.cancel();
    _backendSyncTimer?.cancel();
    _metricsUpdateTimer = null;
    _backendSyncTimer = null;
  }

  /// Sync current metrics with backend
  Future<void> _syncWithBackend() async {
    if (!_isLiveActivityActive || _currentActivityId == null) return;

    try {
      final currentMetrics = _gpsService.getCurrentMetrics();
      final coordinates = _gpsService.trackingPoints
          .map((p) => [p.latitude, p.longitude, p.timestamp?.millisecondsSinceEpoch])
          .toList();

      final updateData = {
        'live_coordinates': coordinates,
        'live_metrics': currentMetrics,
      };

      await _apiService.patch('/fitness/activities/$_currentActivityId/update-live/', updateData);
    } catch (e) {
      debugPrint('Error syncing with backend: $e');
    }
  }

  /// Reset internal state
  void _resetState() {
    _currentActivityId = null;
    _activityType = null;
    _activityName = null;
    _linkedGoalIds.clear();
    _isLiveActivityActive = false;
    _activityStartTime = null;
    _milestonesReached.clear();
    _stopPeriodicUpdates();
  }

  /// Get progress towards linked goals
  Future<Map<int, Map<String, dynamic>>> getGoalProgress() async {
    if (_linkedGoalIds.isEmpty) return {};

    try {
      final goalProgress = <int, Map<String, dynamic>>{};
      
      for (final goalId in _linkedGoalIds) {
        final response = await _apiService.get('/fitness/goals/$goalId/');
        if (response.success && response.data != null) {
          final goal = FitnessGoal.fromJson(response.data);
          final currentMetrics = _gpsService.getCurrentMetrics();
          
          // Calculate how much this activity would contribute
          double contributionValue = 0.0;
          switch (goal.goalType) {
            case 'distance':
              contributionValue = currentMetrics['distance'] ?? 0.0;
              break;
            case 'duration':
              contributionValue = (currentMetrics['duration'] ?? 0) / 60.0; // Convert to minutes
              break;
            case 'frequency':
              contributionValue = 1.0; // This activity counts as 1
              break;
            case 'calories':
              contributionValue = _gpsService.getEstimatedCalories().toDouble();
              break;
          }
          
          goalProgress[goalId] = {
            'goal': goal,
            'current_contribution': contributionValue,
            'projected_progress': goal.currentProgress + contributionValue,
            'projected_percentage': ((goal.currentProgress + contributionValue) / goal.targetValue * 100).clamp(0.0, 100.0),
          };
        }
      }
      
      return goalProgress;
    } catch (e) {
      debugPrint('Error getting goal progress: $e');
      return {};
    }
  }

  /// Force stop (emergency stop)
  Future<void> forceStop() async {
    await _gpsService.stopTracking();
    _stopPeriodicUpdates();
    _resetState();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPeriodicUpdates();
    super.dispose();
  }
}