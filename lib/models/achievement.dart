class Achievement {
  final int id;
  final String title;
  final String description;
  final String category; // 'distance', 'duration', 'frequency', 'streak', 'milestone'
  final String achievementType; // 'bronze', 'silver', 'gold', 'platinum'
  final double targetValue;
  final String unit;
  final String iconName;
  final bool isUnlocked;
  final DateTime? unlockedDate;
  final double currentProgress;
  final int pointsValue;
  final String? activityType;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.achievementType,
    required this.targetValue,
    required this.unit,
    required this.iconName,
    required this.isUnlocked,
    this.unlockedDate,
    required this.currentProgress,
    required this.pointsValue,
    this.activityType,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      achievementType: json['achievement_type'],
      targetValue: json['target_value']?.toDouble() ?? 0.0,
      unit: json['unit'],
      iconName: json['icon_name'],
      isUnlocked: json['is_unlocked'] ?? false,
      unlockedDate: json['unlocked_date'] != null 
          ? DateTime.parse(json['unlocked_date']) 
          : null,
      currentProgress: json['current_progress']?.toDouble() ?? 0.0,
      pointsValue: json['points_value'] ?? 0,
      activityType: json['activity_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'achievement_type': achievementType,
      'target_value': targetValue,
      'unit': unit,
      'icon_name': iconName,
      'is_unlocked': isUnlocked,
      'unlocked_date': unlockedDate?.toIso8601String(),
      'current_progress': currentProgress,
      'points_value': pointsValue,
      'activity_type': activityType,
    };
  }

  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (currentProgress / targetValue * 100).clamp(0.0, 100.0);
  }

  String get progressDisplay {
    if (isUnlocked) {
      return 'Unlocked';
    }
    
    switch (category) {
      case 'distance':
        return '${currentProgress.toStringAsFixed(1)}/${targetValue.toStringAsFixed(1)} $unit';
      case 'duration':
        return '${currentProgress.toInt()}/${targetValue.toInt()} $unit';
      case 'frequency':
        return '${currentProgress.toInt()}/${targetValue.toInt()} $unit';
      case 'streak':
        return '${currentProgress.toInt()}/${targetValue.toInt()} $unit';
      default:
        return '${currentProgress.toStringAsFixed(1)}/${targetValue.toStringAsFixed(1)} $unit';
    }
  }

  String get typeDisplay {
    switch (achievementType.toLowerCase()) {
      case 'bronze':
        return 'Bronze';
      case 'silver':
        return 'Silver';
      case 'gold':
        return 'Gold';
      case 'platinum':
        return 'Platinum';
      default:
        return achievementType;
    }
  }

  String get categoryDisplay {
    switch (category.toLowerCase()) {
      case 'distance':
        return 'Distance';
      case 'duration':
        return 'Duration';
      case 'frequency':
        return 'Frequency';
      case 'streak':
        return 'Streak';
      case 'milestone':
        return 'Milestone';
      default:
        return category;
    }
  }
}