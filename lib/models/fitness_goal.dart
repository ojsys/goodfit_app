class FitnessGoal {
  final int id;
  final String title;
  final String description;
  final String goalType; // 'distance', 'duration', 'calories', 'frequency'
  final double targetValue;
  final String unit;
  final DateTime startDate;
  final DateTime endDate;
  final double currentProgress;
  final bool isActive;
  final bool isCompleted;
  final DateTime? completedDate;
  final String? activityType;

  FitnessGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.goalType,
    required this.targetValue,
    required this.unit,
    required this.startDate,
    required this.endDate,
    required this.currentProgress,
    required this.isActive,
    required this.isCompleted,
    this.completedDate,
    this.activityType,
  });

  factory FitnessGoal.fromJson(Map<String, dynamic> json) {
    return FitnessGoal(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      goalType: json['goal_type'],
      targetValue: json['target_value']?.toDouble() ?? 0.0,
      unit: json['unit'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      currentProgress: json['current_progress']?.toDouble() ?? 0.0,
      isActive: json['is_active'] ?? false,
      isCompleted: json['is_completed'] ?? false,
      completedDate: json['completed_date'] != null 
          ? DateTime.parse(json['completed_date']) 
          : null,
      activityType: json['activity_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Don't send id: 0 for new goals - let backend assign ID
      if (id > 0) 'id': id,
      'title': title,
      // Don't send empty description, send null instead or omit it
      if (description.isNotEmpty) 'description': description,
      // Map Flutter goal types to backend accepted values
      'goal_type': _mapGoalTypeToBackend(goalType),
      'target_value': targetValue,
      'unit': unit,
      // Backend expects YYYY-MM-DD format for dates
      'start_date': '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'end_date': '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      'current_progress': currentProgress,
      'is_active': isActive,
      'is_completed': isCompleted,
      'completed_date': completedDate != null ? 
        '${completedDate!.year.toString().padLeft(4, '0')}-${completedDate!.month.toString().padLeft(2, '0')}-${completedDate!.day.toString().padLeft(2, '0')}' : null,
      // Backend expects activity_type_id instead of activity_type
      'activity_type_id': activityType != null ? int.tryParse(activityType!) : null,
    };
  }

  // Map Flutter goal types to backend accepted values
  String _mapGoalTypeToBackend(String goalType) {
    // Django backend now accepts lowercase values
    switch (goalType.toLowerCase()) {
      case 'distance':
        return 'distance';
      case 'duration':
        return 'duration';
      case 'calories':
        return 'calories';
      case 'frequency':
        return 'frequency';
      default:
        return 'distance'; // Default fallback
    }
  }

  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (currentProgress / targetValue * 100).clamp(0.0, 100.0);
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  String get progressDisplay {
    switch (goalType) {
      case 'distance':
        return '${currentProgress.toStringAsFixed(1)}/${targetValue.toStringAsFixed(1)} $unit';
      case 'duration':
        return '${currentProgress.toInt()}/${targetValue.toInt()} $unit';
      case 'calories':
        return '${currentProgress.toInt()}/${targetValue.toInt()} $unit';
      case 'frequency':
        return '${currentProgress.toInt()}/${targetValue.toInt()} $unit';
      default:
        return '${currentProgress.toStringAsFixed(1)}/${targetValue.toStringAsFixed(1)} $unit';
    }
  }
}