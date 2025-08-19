import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

class AchievementsProvider with ChangeNotifier {
  final ApiService _apiService;
  static const String _logTag = 'AchievementsProvider';

  List<Achievement> _achievements = [];
  List<Achievement> _userAchievements = [];
  List<Achievement> _recentAchievements = [];
  bool _isLoading = false;
  String? _error;

  AchievementsProvider({required ApiService apiService}) : _apiService = apiService;

  List<Achievement> get achievements => _achievements;
  List<Achievement> get userAchievements => _userAchievements;
  List<Achievement> get recentAchievements => _recentAchievements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Achievement> get unlockedAchievements => 
      _userAchievements.where((achievement) => achievement.isUnlocked).toList();
  
  List<Achievement> get inProgressAchievements => 
      _userAchievements.where((achievement) => !achievement.isUnlocked).toList();

  int get totalPoints => _userAchievements
      .where((achievement) => achievement.isUnlocked)
      .fold(0, (sum, achievement) => sum + achievement.pointsValue);

  double get overallProgress {
    if (_userAchievements.isEmpty) return 0.0;
    
    final totalProgress = _userAchievements.fold<double>(
        0.0, (sum, achievement) => sum + achievement.progressPercentage);
    
    return totalProgress / _userAchievements.length;
  }

  Future<void> loadAchievements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final achievementsData = await _apiService.getAchievements();
      
      if (achievementsData.success && achievementsData.data != null) {
        _achievements = (achievementsData.data as List)
            .map((json) => Achievement.fromJson(json))
            .toList();
        AppLogger.info('Loaded ${_achievements.length} achievements successfully', _logTag);
      } else {
        AppLogger.warning('Failed to load achievements from API, using empty list', _logTag);
        _achievements = [];
      }
    } catch (e) {
      AppLogger.error('Error loading achievements: $e', _logTag);
      _error = 'Failed to load achievements';
      _achievements = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserAchievements() async {
    try {
      final userAchievementsData = await _apiService.getUserAchievements();
      
      if (userAchievementsData.success && userAchievementsData.data != null) {
        _userAchievements = (userAchievementsData.data as List)
            .map((json) => Achievement.fromJson(json))
            .toList();
        AppLogger.info('Loaded ${_userAchievements.length} user achievements', _logTag);
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Error loading user achievements: $e', _logTag);
      _userAchievements = [];
      notifyListeners();
    }
  }

  Future<void> loadRecentAchievements() async {
    try {
      final recentData = await _apiService.getRecentAchievements();
      
      if (recentData.success && recentData.data != null) {
        _recentAchievements = (recentData.data as List)
            .map((json) => Achievement.fromJson(json))
            .toList();
        AppLogger.info('Loaded ${_recentAchievements.length} recent achievements', _logTag);
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Error loading recent achievements: $e', _logTag);
      _recentAchievements = [];
      notifyListeners();
    }
  }

  List<Achievement> getAchievementsByCategory(String category) {
    return _userAchievements.where((achievement) => 
        achievement.category.toLowerCase() == category.toLowerCase()).toList();
  }

  List<Achievement> getAchievementsByType(String achievementType) {
    return _userAchievements.where((achievement) => 
        achievement.achievementType.toLowerCase() == achievementType.toLowerCase()).toList();
  }

  List<Achievement> getAchievementsByActivityType(String activityType) {
    return _userAchievements.where((achievement) => 
        achievement.activityType?.toLowerCase() == activityType.toLowerCase()).toList();
  }

  List<Achievement> getCloseToUnlockAchievements({double threshold = 80.0}) {
    return _userAchievements.where((achievement) => 
        !achievement.isUnlocked && 
        achievement.progressPercentage >= threshold).toList();
  }

  Map<String, List<Achievement>> getGroupedAchievementsByCategory() {
    final Map<String, List<Achievement>> categorized = {};
    
    for (final achievement in _userAchievements) {
      final category = achievement.categoryDisplay;
      if (!categorized.containsKey(category)) {
        categorized[category] = [];
      }
      categorized[category]!.add(achievement);
    }
    
    return categorized;
  }

  Map<String, int> getAchievementStats() {
    final stats = {
      'total': _userAchievements.length,
      'unlocked': unlockedAchievements.length,
      'in_progress': inProgressAchievements.length,
      'bronze': getAchievementsByType('bronze').where((a) => a.isUnlocked).length,
      'silver': getAchievementsByType('silver').where((a) => a.isUnlocked).length,
      'gold': getAchievementsByType('gold').where((a) => a.isUnlocked).length,
      'platinum': getAchievementsByType('platinum').where((a) => a.isUnlocked).length,
      'total_points': totalPoints,
    };
    
    return stats;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}