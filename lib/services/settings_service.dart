import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // App settings
  AppSettings _appSettings = AppSettings();
  TrackingSettings _trackingSettings = TrackingSettings();
  NotificationSettings _notificationSettings = NotificationSettings();
  PrivacySettings _privacySettings = PrivacySettings();
  AccessibilitySettings _accessibilitySettings = AccessibilitySettings();

  // Storage keys
  static const String _appSettingsKey = 'app_settings';
  static const String _trackingSettingsKey = 'tracking_settings';
  static const String _notificationSettingsKey = 'notification_settings';
  static const String _privacySettingsKey = 'privacy_settings';
  static const String _accessibilitySettingsKey = 'accessibility_settings';

  // Getters
  AppSettings get appSettings => _appSettings;
  TrackingSettings get trackingSettings => _trackingSettings;
  NotificationSettings get notificationSettings => _notificationSettings;
  PrivacySettings get privacySettings => _privacySettings;
  AccessibilitySettings get accessibilitySettings => _accessibilitySettings;

  /// Initialize settings service
  Future<void> initialize() async {
    await _loadAllSettings();
    notifyListeners();
  }

  /// Update app settings
  Future<void> updateAppSettings(AppSettings settings) async {
    _appSettings = settings;
    await _saveAppSettings();
    notifyListeners();
  }

  /// Update tracking settings
  Future<void> updateTrackingSettings(TrackingSettings settings) async {
    _trackingSettings = settings;
    await _saveTrackingSettings();
    notifyListeners();
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    _notificationSettings = settings;
    await _saveNotificationSettings();
    notifyListeners();
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(PrivacySettings settings) async {
    _privacySettings = settings;
    await _savePrivacySettings();
    notifyListeners();
  }

  /// Update accessibility settings
  Future<void> updateAccessibilitySettings(AccessibilitySettings settings) async {
    _accessibilitySettings = settings;
    await _saveAccessibilitySettings();
    notifyListeners();
  }

  /// Get theme mode
  ThemeMode get themeMode {
    switch (_appSettings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    String themeModeString;
    switch (mode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      default:
        themeModeString = 'system';
    }
    
    final updatedSettings = _appSettings.copyWith(themeMode: themeModeString);
    await updateAppSettings(updatedSettings);
  }

  /// Export all settings
  Map<String, dynamic> exportSettings() {
    return {
      'app_settings': _appSettings.toJson(),
      'tracking_settings': _trackingSettings.toJson(),
      'notification_settings': _notificationSettings.toJson(),
      'privacy_settings': _privacySettings.toJson(),
      'accessibility_settings': _accessibilitySettings.toJson(),
      'exported_at': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  /// Import settings
  Future<bool> importSettings(Map<String, dynamic> settingsData) async {
    try {
      if (settingsData['app_settings'] != null) {
        _appSettings = AppSettings.fromJson(settingsData['app_settings']);
      }
      if (settingsData['tracking_settings'] != null) {
        _trackingSettings = TrackingSettings.fromJson(settingsData['tracking_settings']);
      }
      if (settingsData['notification_settings'] != null) {
        _notificationSettings = NotificationSettings.fromJson(settingsData['notification_settings']);
      }
      if (settingsData['privacy_settings'] != null) {
        _privacySettings = PrivacySettings.fromJson(settingsData['privacy_settings']);
      }
      if (settingsData['accessibility_settings'] != null) {
        _accessibilitySettings = AccessibilitySettings.fromJson(settingsData['accessibility_settings']);
      }

      await _saveAllSettings();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error importing settings: $e');
      return false;
    }
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _appSettings = AppSettings();
    _trackingSettings = TrackingSettings();
    _notificationSettings = NotificationSettings();
    _privacySettings = PrivacySettings();
    _accessibilitySettings = AccessibilitySettings();

    await _saveAllSettings();
    notifyListeners();
  }

  /// Load all settings
  Future<void> _loadAllSettings() async {
    await Future.wait([
      _loadAppSettings(),
      _loadTrackingSettings(),
      _loadNotificationSettings(),
      _loadPrivacySettings(),
      _loadAccessibilitySettings(),
    ]);
  }

  /// Save all settings
  Future<void> _saveAllSettings() async {
    await Future.wait([
      _saveAppSettings(),
      _saveTrackingSettings(),
      _saveNotificationSettings(),
      _savePrivacySettings(),
      _saveAccessibilitySettings(),
    ]);
  }

  /// Load app settings
  Future<void> _loadAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_appSettingsKey);
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson);
        _appSettings = AppSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('Error loading app settings: $e');
    }
  }

  /// Save app settings
  Future<void> _saveAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(_appSettings.toJson());
      await prefs.setString(_appSettingsKey, settingsJson);
    } catch (e) {
      debugPrint('Error saving app settings: $e');
    }
  }

  /// Load tracking settings
  Future<void> _loadTrackingSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_trackingSettingsKey);
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson);
        _trackingSettings = TrackingSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('Error loading tracking settings: $e');
    }
  }

  /// Save tracking settings
  Future<void> _saveTrackingSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(_trackingSettings.toJson());
      await prefs.setString(_trackingSettingsKey, settingsJson);
    } catch (e) {
      debugPrint('Error saving tracking settings: $e');
    }
  }

  /// Load notification settings
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_notificationSettingsKey);
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson);
        _notificationSettings = NotificationSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  /// Save notification settings
  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(_notificationSettings.toJson());
      await prefs.setString(_notificationSettingsKey, settingsJson);
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  /// Load privacy settings
  Future<void> _loadPrivacySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_privacySettingsKey);
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson);
        _privacySettings = PrivacySettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('Error loading privacy settings: $e');
    }
  }

  /// Save privacy settings
  Future<void> _savePrivacySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(_privacySettings.toJson());
      await prefs.setString(_privacySettingsKey, settingsJson);
    } catch (e) {
      debugPrint('Error saving privacy settings: $e');
    }
  }

  /// Load accessibility settings
  Future<void> _loadAccessibilitySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_accessibilitySettingsKey);
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson);
        _accessibilitySettings = AccessibilitySettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('Error loading accessibility settings: $e');
    }
  }

  /// Save accessibility settings
  Future<void> _saveAccessibilitySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(_accessibilitySettings.toJson());
      await prefs.setString(_accessibilitySettingsKey, settingsJson);
    } catch (e) {
      debugPrint('Error saving accessibility settings: $e');
    }
  }
}

class AppSettings {
  final String themeMode; // 'light', 'dark', 'system'
  final String language; // 'en', 'es', 'fr', etc.
  final String units; // 'metric', 'imperial'
  final bool enableAnimations;
  final bool enableHapticFeedback;
  final bool enableSounds;
  final double uiScale; // 0.8 to 1.5
  final String fontFamily; // 'default', 'poppins', etc.

  const AppSettings({
    this.themeMode = 'system',
    this.language = 'en',
    this.units = 'metric',
    this.enableAnimations = true,
    this.enableHapticFeedback = true,
    this.enableSounds = true,
    this.uiScale = 1.0,
    this.fontFamily = 'poppins',
  });

  AppSettings copyWith({
    String? themeMode,
    String? language,
    String? units,
    bool? enableAnimations,
    bool? enableHapticFeedback,
    bool? enableSounds,
    double? uiScale,
    String? fontFamily,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      units: units ?? this.units,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      enableSounds: enableSounds ?? this.enableSounds,
      uiScale: uiScale ?? this.uiScale,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: json['theme_mode'] ?? 'system',
      language: json['language'] ?? 'en',
      units: json['units'] ?? 'metric',
      enableAnimations: json['enable_animations'] ?? true,
      enableHapticFeedback: json['enable_haptic_feedback'] ?? true,
      enableSounds: json['enable_sounds'] ?? true,
      uiScale: (json['ui_scale'] ?? 1.0).toDouble(),
      fontFamily: json['font_family'] ?? 'poppins',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme_mode': themeMode,
      'language': language,
      'units': units,
      'enable_animations': enableAnimations,
      'enable_haptic_feedback': enableHapticFeedback,
      'enable_sounds': enableSounds,
      'ui_scale': uiScale,
      'font_family': fontFamily,
    };
  }
}

class TrackingSettings {
  final bool autoStartTracking;
  final bool backgroundTracking;
  final int gpsUpdateInterval; // in seconds
  final double gpsAccuracy; // in meters
  final bool enableVoiceGuidance;
  final bool enableAudioCues;
  final bool pauseOnLowBattery;
  final int autoPauseThreshold; // in seconds of no movement
  final bool saveTrackingData;
  final bool uploadToCloud;

  const TrackingSettings({
    this.autoStartTracking = false,
    this.backgroundTracking = true,
    this.gpsUpdateInterval = 5,
    this.gpsAccuracy = 10.0,
    this.enableVoiceGuidance = true,
    this.enableAudioCues = true,
    this.pauseOnLowBattery = true,
    this.autoPauseThreshold = 30,
    this.saveTrackingData = true,
    this.uploadToCloud = true,
  });

  TrackingSettings copyWith({
    bool? autoStartTracking,
    bool? backgroundTracking,
    int? gpsUpdateInterval,
    double? gpsAccuracy,
    bool? enableVoiceGuidance,
    bool? enableAudioCues,
    bool? pauseOnLowBattery,
    int? autoPauseThreshold,
    bool? saveTrackingData,
    bool? uploadToCloud,
  }) {
    return TrackingSettings(
      autoStartTracking: autoStartTracking ?? this.autoStartTracking,
      backgroundTracking: backgroundTracking ?? this.backgroundTracking,
      gpsUpdateInterval: gpsUpdateInterval ?? this.gpsUpdateInterval,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      enableVoiceGuidance: enableVoiceGuidance ?? this.enableVoiceGuidance,
      enableAudioCues: enableAudioCues ?? this.enableAudioCues,
      pauseOnLowBattery: pauseOnLowBattery ?? this.pauseOnLowBattery,
      autoPauseThreshold: autoPauseThreshold ?? this.autoPauseThreshold,
      saveTrackingData: saveTrackingData ?? this.saveTrackingData,
      uploadToCloud: uploadToCloud ?? this.uploadToCloud,
    );
  }

  factory TrackingSettings.fromJson(Map<String, dynamic> json) {
    return TrackingSettings(
      autoStartTracking: json['auto_start_tracking'] ?? false,
      backgroundTracking: json['background_tracking'] ?? true,
      gpsUpdateInterval: json['gps_update_interval'] ?? 5,
      gpsAccuracy: (json['gps_accuracy'] ?? 10.0).toDouble(),
      enableVoiceGuidance: json['enable_voice_guidance'] ?? true,
      enableAudioCues: json['enable_audio_cues'] ?? true,
      pauseOnLowBattery: json['pause_on_low_battery'] ?? true,
      autoPauseThreshold: json['auto_pause_threshold'] ?? 30,
      saveTrackingData: json['save_tracking_data'] ?? true,
      uploadToCloud: json['upload_to_cloud'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auto_start_tracking': autoStartTracking,
      'background_tracking': backgroundTracking,
      'gps_update_interval': gpsUpdateInterval,
      'gps_accuracy': gpsAccuracy,
      'enable_voice_guidance': enableVoiceGuidance,
      'enable_audio_cues': enableAudioCues,
      'pause_on_low_battery': pauseOnLowBattery,
      'auto_pause_threshold': autoPauseThreshold,
      'save_tracking_data': saveTrackingData,
      'upload_to_cloud': uploadToCloud,
    };
  }
}

class NotificationSettings {
  final bool enableNotifications;
  final bool goalReminders;
  final bool activityReminders;
  final bool achievementNotifications;
  final bool socialNotifications;
  final bool weeklyReports;
  final String reminderTime; // HH:MM format
  final List<int> reminderDays; // 1-7 for Monday-Sunday
  final bool quietHours;
  final String quietStart; // HH:MM format
  final String quietEnd; // HH:MM format

  const NotificationSettings({
    this.enableNotifications = true,
    this.goalReminders = true,
    this.activityReminders = true,
    this.achievementNotifications = true,
    this.socialNotifications = true,
    this.weeklyReports = true,
    this.reminderTime = '18:00',
    this.reminderDays = const [1, 2, 3, 4, 5], // Monday to Friday
    this.quietHours = true,
    this.quietStart = '22:00',
    this.quietEnd = '07:00',
  });

  NotificationSettings copyWith({
    bool? enableNotifications,
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
  }) {
    return NotificationSettings(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      goalReminders: goalReminders ?? this.goalReminders,
      activityReminders: activityReminders ?? this.activityReminders,
      achievementNotifications: achievementNotifications ?? this.achievementNotifications,
      socialNotifications: socialNotifications ?? this.socialNotifications,
      weeklyReports: weeklyReports ?? this.weeklyReports,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderDays: reminderDays ?? this.reminderDays,
      quietHours: quietHours ?? this.quietHours,
      quietStart: quietStart ?? this.quietStart,
      quietEnd: quietEnd ?? this.quietEnd,
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enableNotifications: json['enable_notifications'] ?? true,
      goalReminders: json['goal_reminders'] ?? true,
      activityReminders: json['activity_reminders'] ?? true,
      achievementNotifications: json['achievement_notifications'] ?? true,
      socialNotifications: json['social_notifications'] ?? true,
      weeklyReports: json['weekly_reports'] ?? true,
      reminderTime: json['reminder_time'] ?? '18:00',
      reminderDays: List<int>.from(json['reminder_days'] ?? [1, 2, 3, 4, 5]),
      quietHours: json['quiet_hours'] ?? true,
      quietStart: json['quiet_start'] ?? '22:00',
      quietEnd: json['quiet_end'] ?? '07:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enable_notifications': enableNotifications,
      'goal_reminders': goalReminders,
      'activity_reminders': activityReminders,
      'achievement_notifications': achievementNotifications,
      'social_notifications': socialNotifications,
      'weekly_reports': weeklyReports,
      'reminder_time': reminderTime,
      'reminder_days': reminderDays,
      'quiet_hours': quietHours,
      'quiet_start': quietStart,
      'quiet_end': quietEnd,
    };
  }
}

class PrivacySettings {
  final bool shareDataWithApps;
  final bool allowAnalytics;
  final bool allowCrashReporting;
  final bool shareLocationData;
  final bool allowPersonalization;
  final bool showInPublicLeaderboards;
  final bool allowFriendRequests;
  final bool shareActivitiesPublicly;
  final bool allowDataExport;
  final bool enableDataEncryption;

  const PrivacySettings({
    this.shareDataWithApps = false,
    this.allowAnalytics = true,
    this.allowCrashReporting = true,
    this.shareLocationData = false,
    this.allowPersonalization = true,
    this.showInPublicLeaderboards = false,
    this.allowFriendRequests = true,
    this.shareActivitiesPublicly = false,
    this.allowDataExport = true,
    this.enableDataEncryption = true,
  });

  PrivacySettings copyWith({
    bool? shareDataWithApps,
    bool? allowAnalytics,
    bool? allowCrashReporting,
    bool? shareLocationData,
    bool? allowPersonalization,
    bool? showInPublicLeaderboards,
    bool? allowFriendRequests,
    bool? shareActivitiesPublicly,
    bool? allowDataExport,
    bool? enableDataEncryption,
  }) {
    return PrivacySettings(
      shareDataWithApps: shareDataWithApps ?? this.shareDataWithApps,
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      allowCrashReporting: allowCrashReporting ?? this.allowCrashReporting,
      shareLocationData: shareLocationData ?? this.shareLocationData,
      allowPersonalization: allowPersonalization ?? this.allowPersonalization,
      showInPublicLeaderboards: showInPublicLeaderboards ?? this.showInPublicLeaderboards,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
      shareActivitiesPublicly: shareActivitiesPublicly ?? this.shareActivitiesPublicly,
      allowDataExport: allowDataExport ?? this.allowDataExport,
      enableDataEncryption: enableDataEncryption ?? this.enableDataEncryption,
    );
  }

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      shareDataWithApps: json['share_data_with_apps'] ?? false,
      allowAnalytics: json['allow_analytics'] ?? true,
      allowCrashReporting: json['allow_crash_reporting'] ?? true,
      shareLocationData: json['share_location_data'] ?? false,
      allowPersonalization: json['allow_personalization'] ?? true,
      showInPublicLeaderboards: json['show_in_public_leaderboards'] ?? false,
      allowFriendRequests: json['allow_friend_requests'] ?? true,
      shareActivitiesPublicly: json['share_activities_publicly'] ?? false,
      allowDataExport: json['allow_data_export'] ?? true,
      enableDataEncryption: json['enable_data_encryption'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'share_data_with_apps': shareDataWithApps,
      'allow_analytics': allowAnalytics,
      'allow_crash_reporting': allowCrashReporting,
      'share_location_data': shareLocationData,
      'allow_personalization': allowPersonalization,
      'show_in_public_leaderboards': showInPublicLeaderboards,
      'allow_friend_requests': allowFriendRequests,
      'share_activities_publicly': shareActivitiesPublicly,
      'allow_data_export': allowDataExport,
      'enable_data_encryption': enableDataEncryption,
    };
  }
}

class AccessibilitySettings {
  final bool enableScreenReader;
  final bool enableHighContrast;
  final bool enableLargeText;
  final bool enableVoiceControl;
  final bool reduceMotion;
  final bool increaseTouchTargets;
  final bool enableColorBlindSupport;
  final double textScaleFactor; // 1.0 to 2.0
  final bool enableHapticNavigation;
  final bool announceNotifications;

  const AccessibilitySettings({
    this.enableScreenReader = false,
    this.enableHighContrast = false,
    this.enableLargeText = false,
    this.enableVoiceControl = false,
    this.reduceMotion = false,
    this.increaseTouchTargets = false,
    this.enableColorBlindSupport = false,
    this.textScaleFactor = 1.0,
    this.enableHapticNavigation = false,
    this.announceNotifications = false,
  });

  AccessibilitySettings copyWith({
    bool? enableScreenReader,
    bool? enableHighContrast,
    bool? enableLargeText,
    bool? enableVoiceControl,
    bool? reduceMotion,
    bool? increaseTouchTargets,
    bool? enableColorBlindSupport,
    double? textScaleFactor,
    bool? enableHapticNavigation,
    bool? announceNotifications,
  }) {
    return AccessibilitySettings(
      enableScreenReader: enableScreenReader ?? this.enableScreenReader,
      enableHighContrast: enableHighContrast ?? this.enableHighContrast,
      enableLargeText: enableLargeText ?? this.enableLargeText,
      enableVoiceControl: enableVoiceControl ?? this.enableVoiceControl,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      increaseTouchTargets: increaseTouchTargets ?? this.increaseTouchTargets,
      enableColorBlindSupport: enableColorBlindSupport ?? this.enableColorBlindSupport,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      enableHapticNavigation: enableHapticNavigation ?? this.enableHapticNavigation,
      announceNotifications: announceNotifications ?? this.announceNotifications,
    );
  }

  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return AccessibilitySettings(
      enableScreenReader: json['enable_screen_reader'] ?? false,
      enableHighContrast: json['enable_high_contrast'] ?? false,
      enableLargeText: json['enable_large_text'] ?? false,
      enableVoiceControl: json['enable_voice_control'] ?? false,
      reduceMotion: json['reduce_motion'] ?? false,
      increaseTouchTargets: json['increase_touch_targets'] ?? false,
      enableColorBlindSupport: json['enable_color_blind_support'] ?? false,
      textScaleFactor: (json['text_scale_factor'] ?? 1.0).toDouble(),
      enableHapticNavigation: json['enable_haptic_navigation'] ?? false,
      announceNotifications: json['announce_notifications'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enable_screen_reader': enableScreenReader,
      'enable_high_contrast': enableHighContrast,
      'enable_large_text': enableLargeText,
      'enable_voice_control': enableVoiceControl,
      'reduce_motion': reduceMotion,
      'increase_touch_targets': increaseTouchTargets,
      'enable_color_blind_support': enableColorBlindSupport,
      'text_scale_factor': textScaleFactor,
      'enable_haptic_navigation': enableHapticNavigation,
      'announce_notifications': announceNotifications,
    };
  }
}