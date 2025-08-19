import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/fitness_goal.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

class GoalsProvider with ChangeNotifier {
  final ApiService _apiService;
  static const String _logTag = 'GoalsProvider';

  List<FitnessGoal> _goals = [];
  List<FitnessGoal> _activeGoals = [];
  bool _isLoading = false;
  String? _error;

  GoalsProvider({required ApiService apiService}) : _apiService = apiService;

  List<FitnessGoal> get goals => _goals;
  List<FitnessGoal> get activeGoals => _activeGoals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<FitnessGoal> get completedGoals => 
      _goals.where((goal) => goal.isCompleted).toList();
  
  List<FitnessGoal> get inProgressGoals => 
      _goals.where((goal) => goal.isActive && !goal.isCompleted).toList();

  Future<void> loadGoals() async {
    _isLoading = true;
    _error = null;
    
    // Safe state update - defer until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final goalsData = await _apiService.getGoals();
      
      if (goalsData.success && goalsData.data != null) {
        _goals = (goalsData.data as List)
            .map((json) => FitnessGoal.fromJson(json))
            .toList();
        AppLogger.info('Loaded ${_goals.length} goals successfully', _logTag);
      } else {
        AppLogger.warning('Failed to load goals from API, using empty list', _logTag);
        _goals = [];
      }
    } catch (e) {
      AppLogger.error('Error loading goals: $e', _logTag);
      _error = 'Failed to load goals';
      _goals = [];
    } finally {
      _isLoading = false;
      
      // Safe state update - defer until after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> loadActiveGoals() async {
    try {
      final activeData = await _apiService.getActiveGoals();
      
      if (activeData.success && activeData.data != null) {
        _activeGoals = (activeData.data as List)
            .map((json) => FitnessGoal.fromJson(json))
            .toList();
        AppLogger.info('Loaded ${_activeGoals.length} active goals', _logTag);
        
        // Safe state update - defer until after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    } catch (e) {
      AppLogger.error('Error loading active goals: $e', _logTag);
      _activeGoals = [];
      
      // Safe state update - defer until after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<bool> createGoal(FitnessGoal goal) async {
    try {
      final result = await _apiService.createGoal(goal.toJson());
      
      if (result.success) {
        AppLogger.info('Goal created successfully', _logTag);
        await loadGoals(); // Refresh goals list
        await loadActiveGoals(); // Refresh active goals
        return true;
      } else {
        AppLogger.warning('Failed to create goal: ${result.error}', _logTag);
        _error = result.error ?? 'Failed to create goal';
        
        // Safe state update - defer until after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        return false;
      }
    } catch (e) {
      AppLogger.error('Error creating goal: $e', _logTag);
      _error = 'Failed to create goal';
      
      // Safe state update - defer until after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  List<FitnessGoal> getGoalsByType(String goalType) {
    return _goals.where((goal) => 
        goal.goalType.toLowerCase() == goalType.toLowerCase()).toList();
  }

  List<FitnessGoal> getGoalsByActivityType(String activityType) {
    return _goals.where((goal) => 
        goal.activityType?.toLowerCase() == activityType.toLowerCase()).toList();
  }

  List<FitnessGoal> getGoalsEndingSoon({int days = 7}) {
    final now = DateTime.now();
    final cutoffDate = now.add(Duration(days: days));
    
    return _goals.where((goal) => 
        goal.isActive && 
        !goal.isCompleted && 
        goal.endDate.isBefore(cutoffDate)).toList();
  }

  double getOverallProgress() {
    if (_activeGoals.isEmpty) return 0.0;
    
    final totalProgress = _activeGoals.fold<double>(
        0.0, (sum, goal) => sum + goal.progressPercentage);
    
    return totalProgress / _activeGoals.length;
  }

  void clearError() {
    _error = null;
    
    // Safe state update - defer until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}