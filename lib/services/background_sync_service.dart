import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'performance_service.dart';
import 'error_handling_service.dart';

class BackgroundSyncService extends ChangeNotifier {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  // Sync state
  bool _isInitialized = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _syncInterval = 30; // minutes
  Timer? _syncTimer;
  
  // Background isolate
  Isolate? _backgroundIsolate;
  ReceivePort? _receivePort;
  
  // Sync queues
  final List<SyncTask> _pendingSyncTasks = [];
  final Map<String, DateTime> _lastSyncTimes = {};
  
  // Services
  late NotificationService _notificationService;
  late PerformanceService _performanceService;
  late ErrorHandlingService _errorService;
  
  // Settings
  bool _backgroundSyncEnabled = true;
  bool _wifiOnlySync = false;
  bool _syncUserData = true;
  bool _syncActivities = true;
  bool _syncRoutes = true;
  bool _syncGoals = true;
  bool _syncSettings = true;
  int _maxRetryAttempts = 3;
  Duration _retryDelay = const Duration(minutes: 5);

  // Storage keys
  static const String _settingsKey = 'background_sync_settings';
  static const String _syncDataKey = 'sync_data';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingTasksCount => _pendingSyncTasks.length;
  bool get backgroundSyncEnabled => _backgroundSyncEnabled;

  /// Initialize background sync service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize services
      _notificationService = NotificationService();
      _performanceService = PerformanceService();
      _errorService = ErrorHandlingService();

      // Load settings and sync data
      await _loadSettings();
      await _loadSyncData();
      
      // Setup background sync timer
      _setupSyncTimer();
      
      // Initialize background isolate
      await _initializeBackgroundIsolate();
      
      _isInitialized = true;
      debugPrint('Background sync service initialized');
      
      // Perform initial sync
      scheduleSyncTask(SyncTask(
        id: 'initial_sync',
        type: SyncType.full,
        priority: SyncPriority.high,
      ));
      
    } catch (e) {
      await _errorService.handleError(
        e,
        context: 'background_sync_init',
        severity: ErrorSeverity.high,
      );
    }
  }

  /// Schedule a sync task
  void scheduleSyncTask(SyncTask task) {
    // Check if task already exists
    final existingIndex = _pendingSyncTasks.indexWhere((t) => t.id == task.id);
    if (existingIndex != -1) {
      // Update existing task with higher priority
      if (task.priority.index > _pendingSyncTasks[existingIndex].priority.index) {
        _pendingSyncTasks[existingIndex] = task;
      }
      return;
    }

    _pendingSyncTasks.add(task);
    _sortTasksByPriority();
    
    // Trigger immediate sync for high priority tasks
    if (task.priority == SyncPriority.high && !_isSyncing) {
      _performSync();
    }
    
    notifyListeners();
  }

  /// Perform manual sync
  Future<void> performManualSync() async {
    scheduleSyncTask(SyncTask(
      id: 'manual_sync_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncType.full,
      priority: SyncPriority.high,
    ));
  }

  /// Update sync settings
  Future<void> updateSettings({
    bool? backgroundSyncEnabled,
    bool? wifiOnlySync,
    bool? syncUserData,
    bool? syncActivities,
    bool? syncRoutes,
    bool? syncGoals,
    bool? syncSettings,
    int? syncInterval,
    int? maxRetryAttempts,
    Duration? retryDelay,
  }) async {
    _backgroundSyncEnabled = backgroundSyncEnabled ?? _backgroundSyncEnabled;
    _wifiOnlySync = wifiOnlySync ?? _wifiOnlySync;
    _syncUserData = syncUserData ?? _syncUserData;
    _syncActivities = syncActivities ?? _syncActivities;
    _syncRoutes = syncRoutes ?? _syncRoutes;
    _syncGoals = syncGoals ?? _syncGoals;
    _syncSettings = syncSettings ?? _syncSettings;
    _syncInterval = syncInterval ?? _syncInterval;
    _maxRetryAttempts = maxRetryAttempts ?? _maxRetryAttempts;
    _retryDelay = retryDelay ?? _retryDelay;

    await _saveSettings();
    
    // Restart sync timer with new interval
    _setupSyncTimer();
    
    notifyListeners();
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    final now = DateTime.now();
    final dayAgo = now.subtract(const Duration(days: 1));

    return {
      'last_sync_time': _lastSyncTime?.toIso8601String(),
      'pending_tasks': _pendingSyncTasks.length,
      'sync_interval_minutes': _syncInterval,
      'background_sync_enabled': _backgroundSyncEnabled,
      'wifi_only': _wifiOnlySync,
      'last_sync_times': _lastSyncTimes.map((k, v) => MapEntry(k, v.toIso8601String())),
      'sync_health': _calculateSyncHealth(),
    };
  }

  /// Force sync specific data type
  Future<void> forceSyncDataType(String dataType) async {
    scheduleSyncTask(SyncTask(
      id: 'force_sync_${dataType}_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncType.partial,
      priority: SyncPriority.high,
      dataTypes: [dataType],
    ));
  }

  /// Stop background sync
  void stopBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    
    _backgroundIsolate?.kill();
    _backgroundIsolate = null;
    
    _receivePort?.close();
    _receivePort = null;
  }

  /// Resume background sync
  void resumeBackgroundSync() {
    if (_backgroundSyncEnabled) {
      _setupSyncTimer();
      _initializeBackgroundIsolate();
    }
  }

  /// Perform sync operation
  Future<void> _performSync() async {
    if (_isSyncing || !_backgroundSyncEnabled) return;
    
    _isSyncing = true;
    notifyListeners();

    _performanceService.startTimer('background_sync');

    try {
      debugPrint('Starting background sync...');

      // Check network connectivity
      if (!await _checkConnectivity()) {
        throw Exception('No network connectivity');
      }

      // Process pending tasks
      await _processPendingTasks();
      
      // Update last sync time
      _lastSyncTime = DateTime.now();
      await _saveSyncData();
      
      debugPrint('Background sync completed successfully');
      
      // Schedule next sync notification if needed
      await _notificationService.scheduleNotification(
        id: 'sync_complete',
        title: 'Sync Complete',
        body: 'Your data has been synchronized successfully',
        type: NotificationType.general,
      );

    } catch (e) {
      await _errorService.handleError(
        e,
        context: 'background_sync',
        severity: ErrorSeverity.medium,
        metadata: {
          'pending_tasks': _pendingSyncTasks.length,
          'last_sync': _lastSyncTime?.toIso8601String(),
        },
      );

      // Reschedule failed tasks with retry delay
      _reschedulePendingTasks();
      
    } finally {
      _isSyncing = false;
      _performanceService.stopTimer('background_sync');
      notifyListeners();
    }
  }

  /// Process pending sync tasks
  Future<void> _processPendingTasks() async {
    final tasks = List<SyncTask>.from(_pendingSyncTasks);
    _pendingSyncTasks.clear();

    for (final task in tasks) {
      try {
        await _executeSyncTask(task);
        _lastSyncTimes[task.type.name] = DateTime.now();
        
      } catch (e) {
        // Re-add failed task with retry logic
        if (task.retryCount < _maxRetryAttempts) {
          final retryTask = task.copyWith(
            retryCount: task.retryCount + 1,
            scheduledTime: DateTime.now().add(_retryDelay),
          );
          _pendingSyncTasks.add(retryTask);
        } else {
          debugPrint('Task ${task.id} failed after ${task.retryCount} retries');
        }
      }
    }
  }

  /// Execute a specific sync task
  Future<void> _executeSyncTask(SyncTask task) async {
    debugPrint('Executing sync task: ${task.id} (${task.type.name})');

    switch (task.type) {
      case SyncType.full:
        await _performFullSync();
        break;
      case SyncType.partial:
        await _performPartialSync(task.dataTypes);
        break;
      case SyncType.userDataOnly:
        await _performUserDataSync();
        break;
      case SyncType.activitiesOnly:
        await _performActivitiesSync();
        break;
      case SyncType.routesOnly:
        await _performRoutesSync();
        break;
      case SyncType.goalsOnly:
        await _performGoalsSync();
        break;
      case SyncType.settingsOnly:
        await _performSettingsSync();
        break;
    }
  }

  /// Perform full sync
  Future<void> _performFullSync() async {
    if (_syncUserData) await _performUserDataSync();
    if (_syncActivities) await _performActivitiesSync();
    if (_syncRoutes) await _performRoutesSync();
    if (_syncGoals) await _performGoalsSync();
    if (_syncSettings) await _performSettingsSync();
  }

  /// Perform partial sync
  Future<void> _performPartialSync(List<String> dataTypes) async {
    for (final dataType in dataTypes) {
      switch (dataType) {
        case 'user_data':
          if (_syncUserData) await _performUserDataSync();
          break;
        case 'activities':
          if (_syncActivities) await _performActivitiesSync();
          break;
        case 'routes':
          if (_syncRoutes) await _performRoutesSync();
          break;
        case 'goals':
          if (_syncGoals) await _performGoalsSync();
          break;
        case 'settings':
          if (_syncSettings) await _performSettingsSync();
          break;
      }
    }
  }

  /// Sync user data
  Future<void> _performUserDataSync() async {
    debugPrint('Syncing user data...');
    // TODO: Implement actual user data sync
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Sync activities
  Future<void> _performActivitiesSync() async {
    debugPrint('Syncing activities...');
    // TODO: Implement actual activities sync
    await Future.delayed(const Duration(milliseconds: 800));
  }

  /// Sync routes
  Future<void> _performRoutesSync() async {
    debugPrint('Syncing routes...');
    // TODO: Implement actual routes sync
    await Future.delayed(const Duration(milliseconds: 600));
  }

  /// Sync goals
  Future<void> _performGoalsSync() async {
    debugPrint('Syncing goals...');
    // TODO: Implement actual goals sync
    await Future.delayed(const Duration(milliseconds: 400));
  }

  /// Sync settings
  Future<void> _performSettingsSync() async {
    debugPrint('Syncing settings...');
    // TODO: Implement actual settings sync
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Check network connectivity
  Future<bool> _checkConnectivity() async {
    // TODO: Implement actual connectivity check
    // For now, simulate connectivity
    return true;
  }

  /// Setup sync timer
  void _setupSyncTimer() {
    _syncTimer?.cancel();
    
    if (!_backgroundSyncEnabled) return;

    _syncTimer = Timer.periodic(Duration(minutes: _syncInterval), (_) {
      if (!_isSyncing) {
        scheduleSyncTask(SyncTask(
          id: 'scheduled_sync_${DateTime.now().millisecondsSinceEpoch}',
          type: SyncType.full,
          priority: SyncPriority.normal,
        ));
      }
    });
  }

  /// Initialize background isolate
  Future<void> _initializeBackgroundIsolate() async {
    try {
      _receivePort = ReceivePort();
      
      _backgroundIsolate = await Isolate.spawn(
        _backgroundIsolateEntryPoint,
        _receivePort!.sendPort,
      );

      _receivePort!.listen((data) {
        if (data is Map<String, dynamic>) {
          _handleBackgroundMessage(data);
        }
      });

      debugPrint('Background isolate initialized');
      
    } catch (e) {
      debugPrint('Failed to initialize background isolate: $e');
    }
  }

  /// Background isolate entry point
  static void _backgroundIsolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((data) {
      // Handle messages from main isolate
      if (data is Map<String, dynamic>) {
        // Perform background work here
        _performBackgroundWork(data, sendPort);
      }
    });
  }

  /// Perform background work in isolate
  static void _performBackgroundWork(Map<String, dynamic> data, SendPort sendPort) {
    try {
      // Simulate background work
      final workType = data['type'] as String;
      debugPrint('Performing background work: $workType');
      
      // Send result back to main isolate
      sendPort.send({
        'type': 'work_complete',
        'result': 'success',
        'work_type': workType,
      });
      
    } catch (e) {
      sendPort.send({
        'type': 'work_error',
        'error': e.toString(),
      });
    }
  }

  /// Handle message from background isolate
  void _handleBackgroundMessage(Map<String, dynamic> data) {
    final type = data['type'] as String;
    
    switch (type) {
      case 'work_complete':
        debugPrint('Background work completed: ${data['work_type']}');
        break;
      case 'work_error':
        debugPrint('Background work error: ${data['error']}');
        break;
    }
  }

  /// Sort tasks by priority
  void _sortTasksByPriority() {
    _pendingSyncTasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
  }

  /// Reschedule pending tasks with retry delay
  void _reschedulePendingTasks() {
    for (int i = 0; i < _pendingSyncTasks.length; i++) {
      final task = _pendingSyncTasks[i];
      if (task.retryCount < _maxRetryAttempts) {
        _pendingSyncTasks[i] = task.copyWith(
          scheduledTime: DateTime.now().add(_retryDelay),
        );
      }
    }
  }

  /// Calculate sync health score
  double _calculateSyncHealth() {
    if (_lastSyncTime == null) return 0.0;

    final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
    final expectedInterval = Duration(minutes: _syncInterval);
    
    if (timeSinceLastSync <= expectedInterval) {
      return 1.0; // Excellent
    } else if (timeSinceLastSync <= expectedInterval * 2) {
      return 0.7; // Good
    } else if (timeSinceLastSync <= expectedInterval * 4) {
      return 0.4; // Fair
    } else {
      return 0.1; // Poor
    }
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        final settings = jsonDecode(settingsJson);
        _backgroundSyncEnabled = settings['background_sync_enabled'] ?? true;
        _wifiOnlySync = settings['wifi_only_sync'] ?? false;
        _syncUserData = settings['sync_user_data'] ?? true;
        _syncActivities = settings['sync_activities'] ?? true;
        _syncRoutes = settings['sync_routes'] ?? true;
        _syncGoals = settings['sync_goals'] ?? true;
        _syncSettings = settings['sync_settings'] ?? true;
        _syncInterval = settings['sync_interval'] ?? 30;
        _maxRetryAttempts = settings['max_retry_attempts'] ?? 3;
        _retryDelay = Duration(minutes: settings['retry_delay_minutes'] ?? 5);
      }
    } catch (e) {
      debugPrint('Error loading sync settings: $e');
    }
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = {
        'background_sync_enabled': _backgroundSyncEnabled,
        'wifi_only_sync': _wifiOnlySync,
        'sync_user_data': _syncUserData,
        'sync_activities': _syncActivities,
        'sync_routes': _syncRoutes,
        'sync_goals': _syncGoals,
        'sync_settings': _syncSettings,
        'sync_interval': _syncInterval,
        'max_retry_attempts': _maxRetryAttempts,
        'retry_delay_minutes': _retryDelay.inMinutes,
      };
      
      await prefs.setString(_settingsKey, jsonEncode(settings));
    } catch (e) {
      debugPrint('Error saving sync settings: $e');
    }
  }

  /// Load sync data from storage
  Future<void> _loadSyncData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncDataJson = prefs.getString(_syncDataKey);
      
      if (syncDataJson != null) {
        final syncData = jsonDecode(syncDataJson);
        
        if (syncData['last_sync_time'] != null) {
          _lastSyncTime = DateTime.parse(syncData['last_sync_time']);
        }
        
        if (syncData['last_sync_times'] != null) {
          final lastSyncTimes = Map<String, dynamic>.from(syncData['last_sync_times']);
          _lastSyncTimes.clear();
          lastSyncTimes.forEach((key, value) {
            _lastSyncTimes[key] = DateTime.parse(value);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading sync data: $e');
    }
  }

  /// Save sync data to storage
  Future<void> _saveSyncData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncData = {
        'last_sync_time': _lastSyncTime?.toIso8601String(),
        'last_sync_times': _lastSyncTimes.map((k, v) => MapEntry(k, v.toIso8601String())),
      };
      
      await prefs.setString(_syncDataKey, jsonEncode(syncData));
    } catch (e) {
      debugPrint('Error saving sync data: $e');
    }
  }

  @override
  void dispose() {
    stopBackgroundSync();
    super.dispose();
  }
}

enum SyncType {
  full,
  partial,
  userDataOnly,
  activitiesOnly,
  routesOnly,
  goalsOnly,
  settingsOnly,
}

enum SyncPriority {
  low,
  normal,
  high,
  critical,
}

class SyncTask {
  final String id;
  final SyncType type;
  final SyncPriority priority;
  final List<String> dataTypes;
  final DateTime scheduledTime;
  final int retryCount;
  final Map<String, dynamic> metadata;

  SyncTask({
    required this.id,
    required this.type,
    required this.priority,
    this.dataTypes = const [],
    DateTime? scheduledTime,
    this.retryCount = 0,
    this.metadata = const {},
  }) : scheduledTime = scheduledTime ?? DateTime.now();

  SyncTask copyWith({
    String? id,
    SyncType? type,
    SyncPriority? priority,
    List<String>? dataTypes,
    DateTime? scheduledTime,
    int? retryCount,
    Map<String, dynamic>? metadata,
  }) {
    return SyncTask(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      dataTypes: dataTypes ?? this.dataTypes,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      retryCount: retryCount ?? this.retryCount,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'priority': priority.name,
      'data_types': dataTypes,
      'scheduled_time': scheduledTime.toIso8601String(),
      'retry_count': retryCount,
      'metadata': metadata,
    };
  }

  factory SyncTask.fromJson(Map<String, dynamic> json) {
    return SyncTask(
      id: json['id'],
      type: SyncType.values.firstWhere((t) => t.name == json['type']),
      priority: SyncPriority.values.firstWhere((p) => p.name == json['priority']),
      dataTypes: List<String>.from(json['data_types'] ?? []),
      scheduledTime: DateTime.parse(json['scheduled_time']),
      retryCount: json['retry_count'] ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}