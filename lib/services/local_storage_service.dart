import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fitness_activity.dart';
import '../utils/logger.dart';

class LocalStorageService {
  static const String _activitiesKey = 'fitness_activities';
  static int _nextId = 1;

  static Future<void> init() async {
    final activities = await getActivities();
    if (activities.isNotEmpty) {
      _nextId = activities.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
    }
  }

  static Future<List<FitnessActivity>> getActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = prefs.getString(_activitiesKey);
      
      if (activitiesJson != null) {
        final List<dynamic> activitiesList = jsonDecode(activitiesJson);
        return activitiesList
            .map((json) => FitnessActivity.fromJson(json))
            .toList();
      }
    } catch (e) {
      AppLogger.error('Error getting activities from local storage', 'LocalStorage', e);
    }
    
    return [];
  }

  static Future<bool> saveActivity(FitnessActivity activity) async {
    try {
      final activities = await getActivities();
      
      // Create a new activity with the next available ID if it's a new one
      final activityToSave = activity.id == 0 
          ? FitnessActivity(
              id: _nextId++,
              activityType: activity.activityType,
              name: activity.name,
              durationMinutes: activity.durationMinutes,
              distanceKm: activity.distanceKm,
              caloriesBurned: activity.caloriesBurned,
              startTime: activity.startTime,
              endTime: activity.endTime,
              startLocation: activity.startLocation,
              endLocation: activity.endLocation,
              startLatitude: activity.startLatitude,
              startLongitude: activity.startLongitude,
              endLatitude: activity.endLatitude,
              endLongitude: activity.endLongitude,
              routeData: activity.routeData,
              isCompleted: activity.isCompleted,
            )
          : activity;
      
      activities.add(activityToSave);
      
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = jsonEncode(activities.map((a) => a.toJson()).toList());
      await prefs.setString(_activitiesKey, activitiesJson);
      
      AppLogger.info('Activity saved locally: ${activityToSave.activityType}', 'LocalStorage');
      return true;
    } catch (e) {
      AppLogger.error('Error saving activity to local storage', 'LocalStorage', e);
      return false;
    }
  }

  static Future<bool> updateActivity(FitnessActivity activity) async {
    try {
      final activities = await getActivities();
      final index = activities.indexWhere((a) => a.id == activity.id);
      
      if (index != -1) {
        activities[index] = activity;
        
        final prefs = await SharedPreferences.getInstance();
        final activitiesJson = jsonEncode(activities.map((a) => a.toJson()).toList());
        await prefs.setString(_activitiesKey, activitiesJson);
        
        AppLogger.info('Activity updated locally: ${activity.activityType}', 'LocalStorage');
        return true;
      }
      
      return false;
    } catch (e) {
      AppLogger.error('Error updating activity in local storage', 'LocalStorage', e);
      return false;
    }
  }

  static Future<bool> deleteActivity(int activityId) async {
    try {
      final activities = await getActivities();
      activities.removeWhere((a) => a.id == activityId);
      
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = jsonEncode(activities.map((a) => a.toJson()).toList());
      await prefs.setString(_activitiesKey, activitiesJson);
      
      AppLogger.info('Activity deleted locally: $activityId', 'LocalStorage');
      return true;
    } catch (e) {
      AppLogger.error('Error deleting activity from local storage', 'LocalStorage', e);
      return false;
    }
  }

  static Future<List<FitnessActivity>> getTodaysActivities() async {
    final activities = await getActivities();
    final today = DateTime.now();
    
    return activities.where((activity) {
      return activity.startTime.year == today.year &&
             activity.startTime.month == today.month &&
             activity.startTime.day == today.day;
    }).toList();
  }
}