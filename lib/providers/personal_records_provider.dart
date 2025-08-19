import 'package:flutter/material.dart';
import '../models/personal_record.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

class PersonalRecordsProvider with ChangeNotifier {
  final ApiService _apiService;
  static const String _logTag = 'PersonalRecordsProvider';

  List<PersonalRecord> _personalRecords = [];
  bool _isLoading = false;
  String? _error;

  PersonalRecordsProvider({required ApiService apiService}) : _apiService = apiService;

  List<PersonalRecord> get personalRecords => _personalRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<PersonalRecord> get recentRecords {
    final sortedRecords = List<PersonalRecord>.from(_personalRecords);
    sortedRecords.sort((a, b) => b.achievedDate.compareTo(a.achievedDate));
    return sortedRecords.take(5).toList();
  }

  Future<void> loadPersonalRecords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final recordsData = await _apiService.getPersonalRecords();
      
      if (recordsData.success && recordsData.data != null) {
        _personalRecords = (recordsData.data as List)
            .map((json) => PersonalRecord.fromJson(json))
            .toList();
        AppLogger.info('Loaded ${_personalRecords.length} personal records successfully', _logTag);
      } else {
        AppLogger.warning('Failed to load personal records from API, using empty list', _logTag);
        _personalRecords = [];
      }
    } catch (e) {
      AppLogger.error('Error loading personal records: $e', _logTag);
      _error = 'Failed to load personal records';
      _personalRecords = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<PersonalRecord> getRecordsByActivityType(String activityType) {
    return _personalRecords.where((record) => 
        record.activityType.toLowerCase() == activityType.toLowerCase()).toList();
  }

  List<PersonalRecord> getRecordsByType(String recordType) {
    return _personalRecords.where((record) => 
        record.recordType.toLowerCase() == recordType.toLowerCase()).toList();
  }

  PersonalRecord? getBestRecord(String activityType, String recordType) {
    final records = _personalRecords.where((record) => 
        record.activityType.toLowerCase() == activityType.toLowerCase() &&
        record.recordType.toLowerCase() == recordType.toLowerCase()).toList();
    
    if (records.isEmpty) return null;
    
    records.sort((a, b) {
      switch (recordType.toLowerCase()) {
        case 'fastest_time':
        case 'best_pace':
          return a.value.compareTo(b.value);
        case 'longest_distance':
        case 'highest_calories':
          return b.value.compareTo(a.value);
        default:
          return b.value.compareTo(a.value);
      }
    });
    
    return records.first;
  }

  Map<String, List<PersonalRecord>> getRecordsByActivity() {
    final Map<String, List<PersonalRecord>> grouped = {};
    
    for (final record in _personalRecords) {
      final activity = record.activityTypeDisplay;
      if (!grouped.containsKey(activity)) {
        grouped[activity] = [];
      }
      grouped[activity]!.add(record);
    }
    
    return grouped;
  }

  Map<String, PersonalRecord?> getLatestRecords() {
    final Map<String, PersonalRecord?> latest = {};
    final activityTypes = _personalRecords.map((r) => r.activityType).toSet();
    
    for (final activityType in activityTypes) {
      final activityRecords = getRecordsByActivityType(activityType);
      if (activityRecords.isNotEmpty) {
        activityRecords.sort((a, b) => b.achievedDate.compareTo(a.achievedDate));
        latest[activityType] = activityRecords.first;
      }
    }
    
    return latest;
  }

  int getTotalRecords() => _personalRecords.length;

  int getNewRecordsCount({int days = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _personalRecords.where((record) => 
        record.achievedDate.isAfter(cutoffDate)).length;
  }

  List<PersonalRecord> getImprovementsOnly() {
    return _personalRecords.where((record) => 
        record.previousRecord != null).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}