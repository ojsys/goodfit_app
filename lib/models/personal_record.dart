class PersonalRecord {
  final int id;
  final String activityType;
  final String recordType; // 'fastest_time', 'longest_distance', 'highest_calories', 'best_pace'
  final double value;
  final String unit;
  final DateTime achievedDate;
  final int? activityId;
  final String? activityName;
  final String? location;
  final double? previousRecord;

  PersonalRecord({
    required this.id,
    required this.activityType,
    required this.recordType,
    required this.value,
    required this.unit,
    required this.achievedDate,
    this.activityId,
    this.activityName,
    this.location,
    this.previousRecord,
  });

  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    return PersonalRecord(
      id: json['id'],
      activityType: json['activity_type'],
      recordType: json['record_type'],
      value: json['value']?.toDouble() ?? 0.0,
      unit: json['unit'],
      achievedDate: DateTime.parse(json['achieved_date']),
      activityId: json['activity_id'],
      activityName: json['activity_name'],
      location: json['location'],
      previousRecord: json['previous_record']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_type': activityType,
      'record_type': recordType,
      'value': value,
      'unit': unit,
      'achieved_date': achievedDate.toIso8601String(),
      'activity_id': activityId,
      'activity_name': activityName,
      'location': location,
      'previous_record': previousRecord,
    };
  }

  String get recordTypeDisplay {
    switch (recordType.toLowerCase()) {
      case 'fastest_time':
        return 'Fastest Time';
      case 'longest_distance':
        return 'Longest Distance';
      case 'highest_calories':
        return 'Most Calories';
      case 'best_pace':
        return 'Best Pace';
      default:
        return recordType.replaceAll('_', ' ').toUpperCase();
    }
  }

  String get activityTypeDisplay {
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

  String get valueDisplay {
    switch (recordType) {
      case 'fastest_time':
        return _formatDuration(value.toInt());
      case 'longest_distance':
        return '${value.toStringAsFixed(1)} $unit';
      case 'highest_calories':
        return '${value.toInt()} $unit';
      case 'best_pace':
        return '${value.toStringAsFixed(2)} $unit';
      default:
        return '${value.toStringAsFixed(1)} $unit';
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${remainingSeconds.toString().padLeft(2, '0')}s';
    } else if (minutes > 0) {
      return '${minutes}m ${remainingSeconds.toString().padLeft(2, '0')}s';
    } else {
      return '${remainingSeconds}s';
    }
  }

  double? get improvement {
    if (previousRecord == null) return null;
    
    switch (recordType) {
      case 'fastest_time':
        // For time, lower is better
        return previousRecord! - value;
      case 'longest_distance':
      case 'highest_calories':
        // For distance and calories, higher is better
        return value - previousRecord!;
      case 'best_pace':
        // For pace, lower is usually better (faster pace)
        return previousRecord! - value;
      default:
        return value - previousRecord!;
    }
  }

  String? get improvementDisplay {
    final imp = improvement;
    if (imp == null) return null;
    
    final isPositive = imp > 0;
    final prefix = isPositive ? '+' : '';
    
    switch (recordType) {
      case 'fastest_time':
        return '${prefix}${_formatDuration(imp.abs().toInt())}';
      case 'longest_distance':
        return '${prefix}${imp.toStringAsFixed(1)} $unit';
      case 'highest_calories':
        return '${prefix}${imp.toInt()} $unit';
      case 'best_pace':
        return '${prefix}${imp.toStringAsFixed(2)} $unit';
      default:
        return '${prefix}${imp.toStringAsFixed(1)} $unit';
    }
  }

  bool get isNewRecord => previousRecord == null;

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(achievedDate);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}