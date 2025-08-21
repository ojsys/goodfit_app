import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Notification state
  bool _isInitialized = false;
  bool _permissionsGranted = false;
  final Map<String, PendingNotification> _pendingNotifications = {};
  final List<AppNotification> _notificationHistory = <AppNotification>[];
  
  // Background sync
  Timer? _backgroundSyncTimer;
  Timer? _reminderTimer;
  
  // Settings
  bool _notificationsEnabled = true;
  bool _goalReminders = true;
  bool _activityReminders = true;
  bool _achievementNotifications = true;
  bool _socialNotifications = true;
  bool _weeklyReports = true;
  String _reminderTime = '18:00';
  List<int> _reminderDays = [1, 2, 3, 4, 5]; // Monday to Friday
  bool _quietHours = true;
  String _quietStart = '22:00';
  String _quietEnd = '07:00';

  // Storage keys
  static const String _settingsKey = 'notification_settings';
  static const String _historyKey = 'notification_history';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get permissionsGranted => _permissionsGranted;
  bool get notificationsEnabled => _notificationsEnabled;
  List<AppNotification> get notificationHistory => List.unmodifiable(_notificationHistory);

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load settings
      await _loadSettings();
      
      // Load notification history
      await _loadNotificationHistory();
      
      // Request permissions
      await _requestPermissions();
      
      // Setup background sync
      _setupBackgroundSync();
      
      // Setup reminder timer
      _setupReminderTimer();
      
      _isInitialized = true;
      debugPrint('Notification service initialized');
      
    } catch (e) {
      debugPrint('Failed to initialize notification service: $e');
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    return await _requestPermissions();
  }

  /// Schedule a local notification
  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    DateTime? scheduledTime,
    Map<String, dynamic>? data,
    NotificationType type = NotificationType.general,
  }) async {
    if (!_permissionsGranted || !_notificationsEnabled) {
      debugPrint('Notifications not enabled or permissions not granted');
      return;
    }

    // Check if notification should be shown based on settings
    if (!_shouldShowNotification(type)) {
      return;
    }

    // Check quiet hours
    if (_isQuietHours()) {
      // Schedule for later if in quiet hours
      scheduledTime ??= _getNextAllowedTime();
    }

    final notification = PendingNotification(
      id: id,
      title: title,
      body: body,
      scheduledTime: scheduledTime ?? DateTime.now(),
      data: data ?? {},
      type: type,
    );

    _pendingNotifications[id] = notification;

    // For immediate notifications
    if (scheduledTime == null || scheduledTime.isBefore(DateTime.now().add(const Duration(seconds: 5)))) {
      await _showImmediateNotification(notification);
    } else {
      await _scheduleDelayedNotification(notification);
    }

    _addToHistory(AppNotification.fromPending(notification));
    notifyListeners();
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(String id) async {
    _pendingNotifications.remove(id);
    // TODO: Cancel actual platform notification
    debugPrint('Cancelled notification: $id');
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    _pendingNotifications.clear();
    // TODO: Clear all platform notifications
    debugPrint('Cleared all notifications');
  }

  /// Schedule goal reminder
  Future<void> scheduleGoalReminder({
    required String goalId,
    required String goalName,
    DateTime? reminderTime,
  }) async {
    if (!_goalReminders) return;

    await scheduleNotification(
      id: 'goal_reminder_$goalId',
      title: 'Goal Reminder',
      body: 'Don\'t forget to work on your goal: $goalName',
      scheduledTime: reminderTime,
      data: {
        'goal_id': goalId,
        'action': 'open_goal',
      },
      type: NotificationType.goalReminder,
    );
  }

  /// Schedule activity reminder
  Future<void> scheduleActivityReminder({
    required String message,
    DateTime? reminderTime,
  }) async {
    if (!_activityReminders) return;

    await scheduleNotification(
      id: 'activity_reminder_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Activity Reminder',
      body: message,
      scheduledTime: reminderTime,
      data: {
        'action': 'start_activity',
      },
      type: NotificationType.activityReminder,
    );
  }

  /// Show achievement notification
  Future<void> showAchievementNotification({
    required String title,
    required String description,
    String? achievementId,
  }) async {
    if (!_achievementNotifications) return;

    await scheduleNotification(
      id: 'achievement_${achievementId ?? DateTime.now().millisecondsSinceEpoch}',
      title: '🎉 $title',
      body: description,
      data: {
        'achievement_id': achievementId,
        'action': 'view_achievement',
      },
      type: NotificationType.achievement,
    );
  }

  /// Schedule weekly report
  Future<void> scheduleWeeklyReport({
    required Map<String, dynamic> reportData,
  }) async {
    if (!_weeklyReports) return;

    final nextWeekly = _getNextWeeklyReportTime();
    
    await scheduleNotification(
      id: 'weekly_report_${nextWeekly.millisecondsSinceEpoch}',
      title: 'Your Weekly Fitness Report',
      body: 'Check out your progress from this week!',
      scheduledTime: nextWeekly,
      data: {
        'report_data': reportData,
        'action': 'view_report',
      },
      type: NotificationType.weeklyReport,
    );
  }

  /// Update notification settings
  Future<void> updateSettings({
    bool? notificationsEnabled,
    bool? goalReminders,
    bool? activityReminders,
    bool? achievementNotifications,
    bool? socialNotifications,
    bool? weeklyReports,
    String? reminderTime,
    List<int>? reminderDays,
    bool? quietHours,
    String? quietStart,
    String? quietEnd,
  }) async {
    _notificationsEnabled = notificationsEnabled ?? _notificationsEnabled;
    _goalReminders = goalReminders ?? _goalReminders;
    _activityReminders = activityReminders ?? _activityReminders;
    _achievementNotifications = achievementNotifications ?? _achievementNotifications;
    _socialNotifications = socialNotifications ?? _socialNotifications;
    _weeklyReports = weeklyReports ?? _weeklyReports;
    _reminderTime = reminderTime ?? _reminderTime;
    _reminderDays = reminderDays ?? _reminderDays;
    _quietHours = quietHours ?? _quietHours;
    _quietStart = quietStart ?? _quietStart;
    _quietEnd = quietEnd ?? _quietEnd;

    await _saveSettings();
    _setupReminderTimer(); // Restart timer with new settings
    notifyListeners();
  }

  /// Get notification statistics
  Map<String, dynamic> getNotificationStatistics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = now.subtract(Duration(days: now.weekday - 1));

    final todayNotifications = _notificationHistory
        .where((n) => n.timestamp.isAfter(today))
        .toList();
    
    final weeklyNotifications = _notificationHistory
        .where((n) => n.timestamp.isAfter(thisWeek))
        .toList();

    return {
      'total_notifications': _notificationHistory.length,
      'today_notifications': todayNotifications.length,
      'weekly_notifications': weeklyNotifications.length,
      'pending_notifications': _pendingNotifications.length,
      'notifications_by_type': _getNotificationsByType(),
      'most_common_type': _getMostCommonNotificationType(),
    };
  }

  /// Start background sync
  void startBackgroundSync() {
    _setupBackgroundSync();
  }

  /// Stop background sync
  void stopBackgroundSync() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = null;
  }

  /// Perform sync operation
  Future<void> performSync() async {
    try {
      debugPrint('Performing background sync...');
      
      // Sync notification preferences from server
      await _syncNotificationPreferences();
      
      // Sync notification history
      await _syncNotificationHistory();
      
      // Schedule pending server notifications
      await _schedulePendingServerNotifications();
      
      // Clean up old notifications
      _cleanupOldNotifications();
      
      debugPrint('Background sync completed');
      
    } catch (e) {
      debugPrint('Background sync failed: $e');
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    // TODO: Implement platform-specific permission requests
    // For now, simulate permission granted
    _permissionsGranted = true;
    debugPrint('Notification permissions granted');
    return true;
  }

  /// Show immediate notification
  Future<void> _showImmediateNotification(PendingNotification notification) async {
    // TODO: Implement platform-specific notification display
    debugPrint('Showing notification: ${notification.title}');
    
    // For demo purposes, we'll just log it
    debugPrint('📱 ${notification.title}: ${notification.body}');
  }

  /// Schedule delayed notification
  Future<void> _scheduleDelayedNotification(PendingNotification notification) async {
    // TODO: Implement platform-specific notification scheduling
    debugPrint('Scheduling notification for: ${notification.scheduledTime}');
    
    // For demo, we'll use a timer for short delays
    final delay = notification.scheduledTime.difference(DateTime.now());
    if (delay.inMinutes < 60) {
      Timer(delay, () => _showImmediateNotification(notification));
    }
  }

  /// Check if notification should be shown based on type and settings
  bool _shouldShowNotification(NotificationType type) {
    switch (type) {
      case NotificationType.goalReminder:
        return _goalReminders;
      case NotificationType.activityReminder:
        return _activityReminders;
      case NotificationType.achievement:
        return _achievementNotifications;
      case NotificationType.social:
        return _socialNotifications;
      case NotificationType.weeklyReport:
        return _weeklyReports;
      case NotificationType.general:
        return true;
    }
  }

  /// Check if current time is in quiet hours
  bool _isQuietHours() {
    if (!_quietHours) return false;

    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    // Handle overnight quiet hours (e.g., 22:00 to 07:00)
    if (_quietStart.compareTo(_quietEnd) > 0) {
      return currentTime.compareTo(_quietStart) >= 0 || currentTime.compareTo(_quietEnd) <= 0;
    } else {
      return currentTime.compareTo(_quietStart) >= 0 && currentTime.compareTo(_quietEnd) <= 0;
    }
  }

  /// Get next allowed time outside quiet hours
  DateTime _getNextAllowedTime() {
    final now = DateTime.now();
    
    if (!_quietHours) return now;

    final quietEndParts = _quietEnd.split(':');
    final quietEndHour = int.parse(quietEndParts[0]);
    final quietEndMinute = int.parse(quietEndParts[1]);

    var nextAllowed = DateTime(now.year, now.month, now.day, quietEndHour, quietEndMinute);
    
    // If quiet end is tomorrow (overnight quiet hours)
    if (_quietStart.compareTo(_quietEnd) > 0 && now.hour >= int.parse(_quietStart.split(':')[0])) {
      nextAllowed = nextAllowed.add(const Duration(days: 1));
    }
    
    // If next allowed time is in the past, move to next day
    if (nextAllowed.isBefore(now)) {
      nextAllowed = nextAllowed.add(const Duration(days: 1));
    }

    return nextAllowed;
  }

  /// Get next weekly report time
  DateTime _getNextWeeklyReportTime() {
    final now = DateTime.now();
    final reminderParts = _reminderTime.split(':');
    final hour = int.parse(reminderParts[0]);
    final minute = int.parse(reminderParts[1]);

    // Schedule for next Monday at reminder time
    var nextMonday = now.add(Duration(days: 8 - now.weekday));
    nextMonday = DateTime(nextMonday.year, nextMonday.month, nextMonday.day, hour, minute);

    return nextMonday;
  }

  /// Setup background sync timer
  void _setupBackgroundSync() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = Timer.periodic(const Duration(hours: 1), (_) {
      performSync();
    });
    
    // Perform initial sync
    performSync();
  }

  /// Setup reminder timer
  void _setupReminderTimer() {
    _reminderTimer?.cancel();
    
    if (!_notificationsEnabled) return;

    _reminderTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkDailyReminders();
    });
  }

  /// Check and send daily reminders
  void _checkDailyReminders() {
    final now = DateTime.now();
    final currentDay = now.weekday;
    
    if (!_reminderDays.contains(currentDay)) return;

    final reminderParts = _reminderTime.split(':');
    final reminderHour = int.parse(reminderParts[0]);
    final reminderMinute = int.parse(reminderParts[1]);

    if (now.hour == reminderHour && now.minute <= reminderMinute + 5) {
      scheduleActivityReminder(
        message: 'Time for your daily fitness activity! 💪',
        reminderTime: DateTime.now(),
      );
    }
  }

  /// Sync notification preferences from server
  Future<void> _syncNotificationPreferences() async {
    // TODO: Implement server sync
    debugPrint('Syncing notification preferences...');
  }

  /// Sync notification history to server
  Future<void> _syncNotificationHistory() async {
    // TODO: Implement server sync
    debugPrint('Syncing notification history...');
  }

  /// Schedule pending server notifications
  Future<void> _schedulePendingServerNotifications() async {
    // TODO: Fetch and schedule server notifications
    debugPrint('Scheduling server notifications...');
  }

  /// Clean up old notifications
  void _cleanupOldNotifications() {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    _notificationHistory.removeWhere((notification) => 
        notification.timestamp.isBefore(cutoff));
    
    _saveNotificationHistory();
  }

  /// Add notification to history
  void _addToHistory(AppNotification notification) {
    _notificationHistory.add(notification);
    
    // Keep only last 1000 notifications
    if (_notificationHistory.length > 1000) {
      _notificationHistory.removeAt(0);
    }
    
    _saveNotificationHistory();
  }

  /// Get notifications grouped by type
  Map<String, int> _getNotificationsByType() {
    final typeCount = <String, int>{};
    
    for (final notification in _notificationHistory) {
      final type = notification.type.name;
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }
    
    return typeCount;
  }

  /// Get most common notification type
  String? _getMostCommonNotificationType() {
    final typeCount = _getNotificationsByType();
    if (typeCount.isEmpty) return null;
    
    return typeCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        final settings = jsonDecode(settingsJson);
        _notificationsEnabled = settings['notifications_enabled'] ?? true;
        _goalReminders = settings['goal_reminders'] ?? true;
        _activityReminders = settings['activity_reminders'] ?? true;
        _achievementNotifications = settings['achievement_notifications'] ?? true;
        _socialNotifications = settings['social_notifications'] ?? true;
        _weeklyReports = settings['weekly_reports'] ?? true;
        _reminderTime = settings['reminder_time'] ?? '18:00';
        _reminderDays = List<int>.from(settings['reminder_days'] ?? [1, 2, 3, 4, 5]);
        _quietHours = settings['quiet_hours'] ?? true;
        _quietStart = settings['quiet_start'] ?? '22:00';
        _quietEnd = settings['quiet_end'] ?? '07:00';
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = {
        'notifications_enabled': _notificationsEnabled,
        'goal_reminders': _goalReminders,
        'activity_reminders': _activityReminders,
        'achievement_notifications': _achievementNotifications,
        'social_notifications': _socialNotifications,
        'weekly_reports': _weeklyReports,
        'reminder_time': _reminderTime,
        'reminder_days': _reminderDays,
        'quiet_hours': _quietHours,
        'quiet_start': _quietStart,
        'quiet_end': _quietEnd,
      };
      
      await prefs.setString(_settingsKey, jsonEncode(settings));
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  /// Load notification history from storage
  Future<void> _loadNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson != null) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        _notificationHistory.clear();
        _notificationHistory.addAll(
          historyList.map((data) => AppNotification.fromJson(data)).toList(),
        );
      }
    } catch (e) {
      debugPrint('Error loading notification history: $e');
    }
  }

  /// Save notification history to storage
  Future<void> _saveNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyData = _notificationHistory.map((n) => n.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(historyData));
    } catch (e) {
      debugPrint('Error saving notification history: $e');
    }
  }

  @override
  void dispose() {
    _backgroundSyncTimer?.cancel();
    _reminderTimer?.cancel();
    super.dispose();
  }
}

enum NotificationType {
  general,
  goalReminder,
  activityReminder,
  achievement,
  social,
  weeklyReport,
}

class PendingNotification {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final Map<String, dynamic> data;
  final NotificationType type;

  const PendingNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.data,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'scheduled_time': scheduledTime.toIso8601String(),
      'data': data,
      'type': type.name,
    };
  }

  factory PendingNotification.fromJson(Map<String, dynamic> json) {
    return PendingNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      scheduledTime: DateTime.parse(json['scheduled_time']),
      data: Map<String, dynamic>.from(json['data']),
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.general,
      ),
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final NotificationType type;
  final bool wasShown;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.data,
    required this.type,
    this.wasShown = true,
  });

  factory AppNotification.fromPending(PendingNotification pending) {
    return AppNotification(
      id: pending.id,
      title: pending.title,
      body: pending.body,
      timestamp: DateTime.now(),
      data: pending.data,
      type: pending.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'type': type.name,
      'was_shown': wasShown,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      timestamp: DateTime.parse(json['timestamp']),
      data: Map<String, dynamic>.from(json['data']),
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.general,
      ),
      wasShown: json['was_shown'] ?? true,
    );
  }
}