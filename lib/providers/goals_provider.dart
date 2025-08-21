import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/fitness_goal.dart';
import '../models/fitness_activity.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

class GoalsProvider with ChangeNotifier {
  final ApiService _apiService;
  static const String _logTag = 'GoalsProvider';

  List<FitnessGoal> _goals = [];
  List<FitnessGoal> _activeGoals = [];
  bool _isLoading = false;
  String? _error;
  User? _currentUser;

  GoalsProvider({required ApiService apiService}) : _apiService = apiService;

  List<FitnessGoal> get goals => _goals;
  List<FitnessGoal> get activeGoals => _activeGoals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _currentUser;

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
        // Log raw API response for debugging
        AppLogger.info('Raw goals API response: ${goalsData.data}', _logTag);
        
        _goals = (goalsData.data as List)
            .map((json) {
              AppLogger.info('Raw goal JSON: $json', _logTag);
              final goal = FitnessGoal.fromJson(json);
              AppLogger.info('Parsed goal: ${goal.title} - Active: ${goal.isActive}, Completed: ${goal.isCompleted}', _logTag);
              return goal;
            })
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
        // Log raw active goals API response for debugging
        AppLogger.info('Raw active goals API response: ${activeData.data}', _logTag);
        
        _activeGoals = (activeData.data as List)
            .map((json) {
              AppLogger.info('Raw active goal JSON: $json', _logTag);
              final goal = FitnessGoal.fromJson(json);
              AppLogger.info('Parsed active goal: ${goal.title} - Active: ${goal.isActive}, Completed: ${goal.isCompleted}', _logTag);
              return goal;
            })
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

  void setCurrentUser(User? user) {
    if (_currentUser?.id != user?.id) {
      _currentUser = user;
      // Clear goals when user changes to ensure fresh data
      if (user == null) {
        _goals = [];
        _activeGoals = [];
        AppLogger.info('User logged out, cleared goals', _logTag);
      } else {
        AppLogger.info('User changed, will reload goals for user: ${user.email}', _logTag);
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void clearError() {
    _error = null;
    
    // Safe state update - defer until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Get goals that are linked to a specific activity
  List<FitnessGoal> getGoalsLinkedToActivity(FitnessActivity activity) {
    if (activity.linkedGoalIds.isEmpty) return [];
    
    return _goals.where((goal) => 
        activity.linkedGoalIds.contains(goal.id)).toList();
  }

  /// Get goals compatible with a specific activity type
  List<FitnessGoal> getCompatibleGoals(String activityType) {
    // Use active goals directly since they're already filtered to be active
    AppLogger.info('Searching for compatible goals in ${_activeGoals.length} active goals for activity: $activityType', _logTag);
    
    final compatible = _activeGoals.where((goal) => 
        !goal.isCompleted &&
        (goal.activityType == null || 
         goal.activityType!.toLowerCase() == activityType.toLowerCase() ||
         _isActivityTypeCompatible(goal.goalType, activityType))).toList();
         
    AppLogger.info('Found ${compatible.length} compatible goals for $activityType', _logTag);
    for (final goal in compatible) {
      AppLogger.info('Compatible: ${goal.title} (${goal.goalType}) - Active: ${goal.isActive}, Completed: ${goal.isCompleted}', _logTag);
    }
    
    return compatible;
  }

  /// Check if an activity type is compatible with a goal type
  bool _isActivityTypeCompatible(String goalType, String activityType) {
    switch (goalType.toLowerCase()) {
      case 'distance':
        return ['running', 'cycling', 'walking', 'hiking'].contains(activityType.toLowerCase());
      case 'duration':
        return true; // All activities have duration
      case 'calories':
        return true; // All activities can burn calories
      case 'frequency':
        return true; // Any activity counts toward frequency
      default:
        return false;
    }
  }

  /// Update goal progress based on a completed activity
  Future<bool> updateGoalProgress(FitnessActivity activity) async {
    if (!activity.isCompleted || activity.linkedGoalIds.isEmpty) {
      return true; // Nothing to update
    }

    AppLogger.info('Updating goal progress for activity: ${activity.id}', _logTag);
    
    bool allUpdatesSuccessful = true;
    List<FitnessGoal> updatedGoals = [];

    for (final goalId in activity.linkedGoalIds) {
      final goal = _goals.firstWhere(
        (g) => g.id == goalId,
        orElse: () => FitnessGoal(
          id: -1, title: '', description: '', goalType: '', 
          targetValue: 0, unit: '', startDate: DateTime.now(), 
          endDate: DateTime.now(), currentProgress: 0, 
          isActive: false, isCompleted: false
        ),
      );

      if (goal.id == -1 || goal.isCompleted) continue;

      double progressToAdd = _calculateProgressContribution(goal, activity);
      if (progressToAdd <= 0) continue;

      double newProgress = goal.currentProgress + progressToAdd;
      bool isNowCompleted = newProgress >= goal.targetValue;
      
      // Create updated goal
      final updatedGoal = FitnessGoal(
        id: goal.id,
        title: goal.title,
        description: goal.description,
        goalType: goal.goalType,
        targetValue: goal.targetValue,
        unit: goal.unit,
        startDate: goal.startDate,
        endDate: goal.endDate,
        currentProgress: newProgress.clamp(0, goal.targetValue),
        isActive: goal.isActive,
        isCompleted: isNowCompleted,
        completedDate: isNowCompleted ? DateTime.now() : goal.completedDate,
        activityType: goal.activityType,
      );

      // Update goal via API
      try {
        final result = await _apiService.updateGoal(goal.id, updatedGoal.toJson());
        
        if (result.success) {
          updatedGoals.add(updatedGoal);
          AppLogger.info('Updated goal ${goal.id} progress: ${goal.currentProgress} → $newProgress', _logTag);
          
          if (isNowCompleted) {
            AppLogger.info('Goal "${goal.title}" completed!', _logTag);
          }
        } else {
          AppLogger.error('Failed to update goal ${goal.id}: ${result.error}', _logTag);
          allUpdatesSuccessful = false;
        }
      } catch (e) {
        AppLogger.error('Error updating goal ${goal.id}: $e', _logTag);
        allUpdatesSuccessful = false;
      }
    }

    // Update local goals list with successful updates
    if (updatedGoals.isNotEmpty) {
      for (final updatedGoal in updatedGoals) {
        final index = _goals.indexWhere((g) => g.id == updatedGoal.id);
        if (index != -1) {
          _goals[index] = updatedGoal;
        }
        
        final activeIndex = _activeGoals.indexWhere((g) => g.id == updatedGoal.id);
        if (activeIndex != -1) {
          if (updatedGoal.isCompleted) {
            _activeGoals.removeAt(activeIndex);
          } else {
            _activeGoals[activeIndex] = updatedGoal;
          }
        }
      }
      
      // Notify listeners of progress updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }

    return allUpdatesSuccessful;
  }

  /// Calculate how much progress an activity contributes to a goal
  double _calculateProgressContribution(FitnessGoal goal, FitnessActivity activity) {
    switch (goal.goalType.toLowerCase()) {
      case 'distance':
        return activity.distanceKm ?? 0.0;
      case 'duration':
        return activity.durationMinutes.toDouble();
      case 'calories':
        return (activity.caloriesBurned ?? 0).toDouble();
      case 'frequency':
        return 1.0; // Each completed activity counts as 1
      default:
        return 0.0;
    }
  }

  /// Get recently updated goals (goals that had progress in last N days)
  List<FitnessGoal> getRecentlyUpdatedGoals({int days = 3}) {
    // This would need activity history to determine recent updates
    // For now, return goals with recent progress (this is a placeholder)
    return _goals.where((goal) => 
        goal.currentProgress > 0 && 
        !goal.isCompleted).toList();
  }

  /// Get progress summary for dashboard
  Map<String, dynamic> getProgressSummary() {
    final activeGoals = inProgressGoals;
    
    return {
      'totalActiveGoals': activeGoals.length,
      'completedGoals': completedGoals.length,
      'overallProgress': getOverallProgress(),
      'goalsEndingSoon': getGoalsEndingSoon().length,
      'goalsByType': {
        'distance': activeGoals.where((g) => g.goalType == 'distance').length,
        'duration': activeGoals.where((g) => g.goalType == 'duration').length,
        'calories': activeGoals.where((g) => g.goalType == 'calories').length,
        'frequency': activeGoals.where((g) => g.goalType == 'frequency').length,
      },
    };
  }
}