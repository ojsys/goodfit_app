import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

class LeaderboardProvider with ChangeNotifier {
  final ApiService _apiService;
  static const String _logTag = 'LeaderboardProvider';

  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoading = false;
  String? _error;
  String _currentMetricType = 'distance';
  String _currentTimeFrame = 'weekly';
  String? _currentActivityType;

  LeaderboardProvider({required ApiService apiService}) : _apiService = apiService;

  List<LeaderboardEntry> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentMetricType => _currentMetricType;
  String get currentTimeFrame => _currentTimeFrame;
  String? get currentActivityType => _currentActivityType;

  LeaderboardEntry? get currentUserEntry => 
      _leaderboard.where((entry) => entry.isCurrentUser).isNotEmpty
          ? _leaderboard.firstWhere((entry) => entry.isCurrentUser)
          : null;

  List<LeaderboardEntry> get topThree => 
      _leaderboard.take(3).toList();

  Future<void> loadLeaderboard({
    String? metricType,
    String? timeFrame,
    String? activityType,
  }) async {
    _isLoading = true;
    _error = null;
    
    // Update current filters
    if (metricType != null) _currentMetricType = metricType;
    if (timeFrame != null) _currentTimeFrame = timeFrame;
    if (activityType != null) _currentActivityType = activityType;
    
    notifyListeners();

    try {
      final leaderboardData = await _apiService.getLeaderboard(
        timeframe: _currentTimeFrame,
        activityType: _currentActivityType,
      );
      
      if (leaderboardData.success && leaderboardData.data != null) {
        _leaderboard = (leaderboardData.data as List)
            .map((json) => LeaderboardEntry.fromJson(json))
            .toList();
        AppLogger.info('Loaded ${_leaderboard.length} leaderboard entries successfully', _logTag);
      } else {
        AppLogger.warning('Failed to load leaderboard from API, using empty list', _logTag);
        _leaderboard = [];
      }
    } catch (e) {
      AppLogger.error('Error loading leaderboard: $e', _logTag);
      _error = 'Failed to load leaderboard';
      _leaderboard = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshLeaderboard() async {
    await loadLeaderboard();
  }

  LeaderboardEntry? getUserRank(int userId) {
    try {
      return _leaderboard.firstWhere((entry) => entry.userId == userId);
    } catch (e) {
      return null;
    }
  }

  List<LeaderboardEntry> getUsersAroundRank(int targetRank, {int range = 2}) {
    final startIndex = (targetRank - range - 1).clamp(0, _leaderboard.length);
    final endIndex = (targetRank + range).clamp(0, _leaderboard.length);
    
    return _leaderboard.sublist(startIndex, endIndex);
  }

  List<String> get availableMetricTypes => [
    'distance',
    'duration',
    'calories',
    'activities_count',
  ];

  List<String> get availableTimeFrames => [
    'weekly',
    'monthly',
    'yearly',
    'all_time',
  ];

  List<String> get availableActivityTypes => [
    'running',
    'cycling',
    'walking',
    'swimming',
    'hiking',
  ];

  String getMetricTypeDisplay(String metricType) {
    switch (metricType.toLowerCase()) {
      case 'distance':
        return 'Distance';
      case 'duration':
        return 'Duration';
      case 'calories':
        return 'Calories';
      case 'activities_count':
        return 'Activities';
      default:
        return metricType;
    }
  }

  String getTimeFrameDisplay(String timeFrame) {
    switch (timeFrame.toLowerCase()) {
      case 'weekly':
        return 'This Week';
      case 'monthly':
        return 'This Month';
      case 'yearly':
        return 'This Year';
      case 'all_time':
        return 'All Time';
      default:
        return timeFrame;
    }
  }

  String getActivityTypeDisplay(String? activityType) {
    if (activityType == null) return 'All Activities';
    
    switch (activityType.toLowerCase()) {
      case 'running':
        return 'Running';
      case 'cycling':
        return 'Cycling';
      case 'walking':
        return 'Walking';
      case 'swimming':
        return 'Swimming';
      case 'hiking':
        return 'Hiking';
      default:
        return activityType;
    }
  }

  Map<String, dynamic> getLeaderboardStats() {
    if (_leaderboard.isEmpty) {
      return {
        'total_participants': 0,
        'current_user_rank': null,
        'top_performer': null,
        'average_value': 0.0,
      };
    }

    final currentUser = currentUserEntry;
    final topPerformer = _leaderboard.first;
    final totalValue = _leaderboard.fold<double>(0.0, (sum, entry) => sum + entry.value);
    final averageValue = totalValue / _leaderboard.length;

    return {
      'total_participants': _leaderboard.length,
      'current_user_rank': currentUser?.rank,
      'top_performer': topPerformer,
      'average_value': averageValue,
    };
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetFilters() {
    _currentMetricType = 'distance';
    _currentTimeFrame = 'weekly';
    _currentActivityType = null;
    loadLeaderboard();
  }
}