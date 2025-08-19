class LeaderboardEntry {
  final int userId;
  final String userName;
  final String? userAvatar;
  final int rank;
  final double value;
  final String unit;
  final String metricType; // 'distance', 'duration', 'calories', 'activities_count'
  final String timeFrame; // 'weekly', 'monthly', 'yearly', 'all_time'
  final String? activityType;
  final bool isCurrentUser;
  final int totalActivities;
  final DateTime lastActivityDate;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rank,
    required this.value,
    required this.unit,
    required this.metricType,
    required this.timeFrame,
    this.activityType,
    required this.isCurrentUser,
    required this.totalActivities,
    required this.lastActivityDate,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'],
      userName: json['user_name'],
      userAvatar: json['user_avatar'],
      rank: json['rank'],
      value: json['value']?.toDouble() ?? 0.0,
      unit: json['unit'],
      metricType: json['metric_type'],
      timeFrame: json['time_frame'],
      activityType: json['activity_type'],
      isCurrentUser: json['is_current_user'] ?? false,
      totalActivities: json['total_activities'] ?? 0,
      lastActivityDate: DateTime.parse(json['last_activity_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'rank': rank,
      'value': value,
      'unit': unit,
      'metric_type': metricType,
      'time_frame': timeFrame,
      'activity_type': activityType,
      'is_current_user': isCurrentUser,
      'total_activities': totalActivities,
      'last_activity_date': lastActivityDate.toIso8601String(),
    };
  }

  String get valueDisplay {
    switch (metricType.toLowerCase()) {
      case 'distance':
        return '${value.toStringAsFixed(1)} $unit';
      case 'duration':
        return _formatDuration(value.toInt());
      case 'calories':
        return '${value.toInt()} $unit';
      case 'activities_count':
        return '${value.toInt()} ${value.toInt() == 1 ? 'activity' : 'activities'}';
      default:
        return '${value.toStringAsFixed(1)} $unit';
    }
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${remainingMinutes}m';
    }
  }

  String get metricTypeDisplay {
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

  String get timeFrameDisplay {
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

  String get activityTypeDisplay {
    if (activityType == null) return 'All Activities';
    
    switch (activityType!.toLowerCase()) {
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
        return activityType!;
    }
  }

  String get lastActivityDisplay {
    final now = DateTime.now();
    final difference = now.difference(lastActivityDate);

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

  String get rankDisplay {
    if (rank == 1) return '1st';
    if (rank == 2) return '2nd';
    if (rank == 3) return '3rd';
    return '${rank}th';
  }
}