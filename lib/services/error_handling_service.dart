import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ErrorHandlingService extends ChangeNotifier {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  // Error tracking
  final Queue<AppError> _errors = Queue<AppError>();
  final Map<String, int> _errorCounts = {};
  final Map<String, DateTime> _lastErrorTimes = {};
  
  // Recovery strategies
  final Map<String, RecoveryStrategy> _recoveryStrategies = {};
  
  // Settings
  static const int maxErrorHistory = 500;
  static const Duration errorCooldown = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;
  
  // Crash reporting
  String? _crashLogPath;
  bool _isInitialized = false;

  // Getters
  List<AppError> get recentErrors => _errors.toList();
  Map<String, int> get errorCounts => Map.unmodifiable(_errorCounts);
  bool get hasCriticalErrors => _hasCriticalErrors();

  /// Initialize error handling
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set up crash log directory
      final documentsDir = await getApplicationDocumentsDirectory();
      _crashLogPath = '${documentsDir.path}/crash_logs';
      
      final logDir = Directory(_crashLogPath!);
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // Set up global error handling
      _setupGlobalErrorHandling();
      
      // Register default recovery strategies
      _registerDefaultRecoveryStrategies();
      
      // Load previous crash logs
      await _loadPreviousCrashLogs();
      
      _isInitialized = true;
      debugPrint('Error handling service initialized');
      
    } catch (e) {
      debugPrint('Failed to initialize error handling: $e');
    }
  }

  /// Handle an error with automatic recovery
  Future<bool> handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    ErrorSeverity severity = ErrorSeverity.medium,
    Map<String, dynamic>? metadata,
    bool attemptRecovery = true,
  }) async {
    final appError = AppError(
      error: error,
      stackTrace: stackTrace,
      context: context ?? 'unknown',
      severity: severity,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    // Record the error
    _recordError(appError);
    
    // Log to crash file if critical
    if (severity == ErrorSeverity.critical) {
      await _logCrashToFile(appError);
    }

    // Attempt recovery if enabled
    if (attemptRecovery && _shouldAttemptRecovery(appError)) {
      return await _attemptRecovery(appError);
    }

    return false;
  }

  /// Register a custom recovery strategy
  void registerRecoveryStrategy(String errorType, RecoveryStrategy strategy) {
    _recoveryStrategies[errorType] = strategy;
  }

  /// Report error to external service (Analytics, Crashlytics, etc.)
  Future<void> reportError(AppError error) async {
    try {
      // This would integrate with external crash reporting services
      final errorReport = {
        'error_type': error.error.runtimeType.toString(),
        'error_message': error.error.toString(),
        'context': error.context,
        'severity': error.severity.name,
        'timestamp': error.timestamp.toIso8601String(),
        'stack_trace': error.stackTrace?.toString(),
        'metadata': error.metadata,
        'app_version': '1.0.0', // Would get from package info
        'platform': Platform.operatingSystem,
        'device_info': await _getDeviceInfo(),
      };

      // Send to external service
      debugPrint('Error reported: ${jsonEncode(errorReport)}');
      
    } catch (e) {
      debugPrint('Failed to report error: $e');
    }
  }

  /// Handle network errors with retry logic
  Future<T?> handleNetworkOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = maxRetryAttempts,
    Duration delay = const Duration(seconds: 1),
    String? context,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        attempts++;
        
        final isNetworkError = _isNetworkError(error);
        final shouldRetry = isNetworkError && attempts < maxRetries;
        
        await handleError(
          error,
          stackTrace: stackTrace,
          context: context ?? 'network_operation',
          severity: shouldRetry ? ErrorSeverity.low : ErrorSeverity.medium,
          metadata: {
            'attempt': attempts,
            'max_retries': maxRetries,
            'will_retry': shouldRetry,
          },
        );

        if (shouldRetry) {
          await Future.delayed(delay * attempts); // Exponential backoff
        } else {
          rethrow;
        }
      }
    }
    
    return null;
  }

  /// Handle UI errors gracefully
  Widget handleUIError(
    Widget child, {
    String? context,
    Widget? fallbackWidget,
  }) {
    return ErrorBoundary(
      context: context ?? 'ui_widget',
      fallbackWidget: fallbackWidget,
      onError: (error, stackTrace) {
        handleError(
          error,
          stackTrace: stackTrace,
          context: context,
          severity: ErrorSeverity.medium,
        );
      },
      child: child,
    );
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStatistics() {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    final oneDayAgo = now.subtract(const Duration(days: 1));
    
    final recentErrors = _errors.where((e) => e.timestamp.isAfter(oneHourAgo)).toList();
    final dailyErrors = _errors.where((e) => e.timestamp.isAfter(oneDayAgo)).toList();
    
    return {
      'total_errors': _errors.length,
      'errors_last_hour': recentErrors.length,
      'errors_last_day': dailyErrors.length,
      'error_types': _errorCounts,
      'critical_errors': _errors.where((e) => e.severity == ErrorSeverity.critical).length,
      'most_common_error': _getMostCommonError(),
      'error_trends': _calculateErrorTrends(),
    };
  }

  /// Clear old errors
  void clearOldErrors() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    _errors.removeWhere((error) => error.timestamp.isBefore(cutoff));
    
    // Clean up error counts for cleared errors
    final remainingErrorTypes = _errors.map((e) => e.error.runtimeType.toString()).toSet();
    _errorCounts.removeWhere((key, value) => !remainingErrorTypes.contains(key));
    
    notifyListeners();
  }

  /// Record error internally
  void _recordError(AppError error) {
    _errors.add(error);
    
    // Update error counts
    final errorType = error.error.runtimeType.toString();
    _errorCounts[errorType] = (_errorCounts[errorType] ?? 0) + 1;
    _lastErrorTimes[errorType] = error.timestamp;
    
    // Cleanup old errors
    if (_errors.length > maxErrorHistory) {
      _errors.removeFirst();
    }
    
    // Report critical errors immediately
    if (error.severity == ErrorSeverity.critical) {
      reportError(error);
    }
    
    notifyListeners();
  }

  /// Set up global error handling
  void _setupGlobalErrorHandling() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      handleError(
        details.exception,
        stackTrace: details.stack,
        context: 'flutter_framework',
        severity: ErrorSeverity.high,
        metadata: {
          'library': details.library,
          'information': details.informationCollector?.call().toString(),
        },
      );
    };

    // Handle platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      handleError(
        error,
        stackTrace: stack,
        context: 'platform_dispatcher',
        severity: ErrorSeverity.critical,
      );
      return true;
    };
  }

  /// Register default recovery strategies
  void _registerDefaultRecoveryStrategies() {
    // Network error recovery
    registerRecoveryStrategy('NetworkError', RecoveryStrategy(
      name: 'Network Recovery',
      canRecover: (error) => _isNetworkError(error.error),
      recover: (error) async {
        // Wait and retry network operations
        await Future.delayed(const Duration(seconds: 2));
        return true;
      },
    ));

    // Memory error recovery
    registerRecoveryStrategy('OutOfMemoryError', RecoveryStrategy(
      name: 'Memory Recovery',
      canRecover: (error) => _isMemoryError(error.error),
      recover: (error) async {
        // Clear caches and force garbage collection
        PaintingBinding.instance.imageCache.clear();
        return true;
      },
    ));

    // Storage error recovery
    registerRecoveryStrategy('StorageError', RecoveryStrategy(
      name: 'Storage Recovery',
      canRecover: (error) => _isStorageError(error.error),
      recover: (error) async {
        // Clean up temporary files
        try {
          final tempDir = await getTemporaryDirectory();
          if (await tempDir.exists()) {
            await for (final file in tempDir.list()) {
              if (file is File) {
                await file.delete();
              }
            }
          }
          return true;
        } catch (e) {
          return false;
        }
      },
    ));
  }

  /// Check if should attempt recovery
  bool _shouldAttemptRecovery(AppError error) {
    final errorType = error.error.runtimeType.toString();
    final lastErrorTime = _lastErrorTimes[errorType];
    
    // Don't retry if same error occurred recently
    if (lastErrorTime != null && 
        DateTime.now().difference(lastErrorTime) < errorCooldown) {
      return false;
    }
    
    // Don't retry critical errors
    if (error.severity == ErrorSeverity.critical) {
      return false;
    }
    
    return true;
  }

  /// Attempt recovery for an error
  Future<bool> _attemptRecovery(AppError error) async {
    final errorType = error.error.runtimeType.toString();
    final strategy = _recoveryStrategies[errorType];
    
    if (strategy == null || !strategy.canRecover(error)) {
      return false;
    }

    try {
      final recovered = await strategy.recover(error);
      
      await handleError(
        'Recovery ${recovered ? 'succeeded' : 'failed'}',
        context: 'error_recovery',
        severity: ErrorSeverity.low,
        metadata: {
          'original_error': errorType,
          'recovery_strategy': strategy.name,
          'success': recovered,
        },
      );
      
      return recovered;
    } catch (recoveryError) {
      await handleError(
        recoveryError,
        context: 'error_recovery_failed',
        severity: ErrorSeverity.medium,
        metadata: {
          'original_error': errorType,
          'recovery_strategy': strategy.name,
        },
      );
      
      return false;
    }
  }

  /// Log crash to file
  Future<void> _logCrashToFile(AppError error) async {
    if (_crashLogPath == null) return;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final logFile = File('$_crashLogPath/crash_$timestamp.log');
      
      final crashLog = {
        'timestamp': error.timestamp.toIso8601String(),
        'error_type': error.error.runtimeType.toString(),
        'error_message': error.error.toString(),
        'context': error.context,
        'severity': error.severity.name,
        'stack_trace': error.stackTrace?.toString(),
        'metadata': error.metadata,
        'device_info': await _getDeviceInfo(),
      };
      
      await logFile.writeAsString(jsonEncode(crashLog));
      
    } catch (e) {
      debugPrint('Failed to write crash log: $e');
    }
  }

  /// Load previous crash logs
  Future<void> _loadPreviousCrashLogs() async {
    if (_crashLogPath == null) return;

    try {
      final logDir = Directory(_crashLogPath!);
      if (!await logDir.exists()) return;

      final logFiles = await logDir.list().where((file) => 
          file is File && file.path.endsWith('.log')).toList();
      
      for (final file in logFiles.take(10)) { // Load last 10 crash logs
        try {
          final content = await (file as File).readAsString();
          final crashData = jsonDecode(content);
          
          // Add to error history (but don't trigger notifications)
          final error = AppError(
            error: Exception(crashData['error_message']),
            context: crashData['context'],
            severity: ErrorSeverity.values.firstWhere(
              (s) => s.name == crashData['severity'],
              orElse: () => ErrorSeverity.medium,
            ),
            timestamp: DateTime.parse(crashData['timestamp']),
            metadata: Map<String, dynamic>.from(crashData['metadata'] ?? {}),
          );
          
          _errors.add(error);
        } catch (e) {
          debugPrint('Failed to load crash log ${file.path}: $e');
        }
      }
      
    } catch (e) {
      debugPrint('Failed to load previous crash logs: $e');
    }
  }

  /// Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'is_physical_device': !kIsWeb && Platform.isAndroid || Platform.isIOS,
    };
  }

  /// Check if error is network-related
  bool _isNetworkError(dynamic error) {
    return error is SocketException ||
           error is TimeoutException ||
           error.toString().toLowerCase().contains('network') ||
           error.toString().toLowerCase().contains('connection');
  }

  /// Check if error is memory-related
  bool _isMemoryError(dynamic error) {
    return error.toString().toLowerCase().contains('memory') ||
           error.toString().toLowerCase().contains('heap');
  }

  /// Check if error is storage-related
  bool _isStorageError(dynamic error) {
    return error is FileSystemException ||
           error.toString().toLowerCase().contains('storage') ||
           error.toString().toLowerCase().contains('disk');
  }

  /// Check for critical errors
  bool _hasCriticalErrors() {
    final recentCritical = _errors.where((e) => 
        e.severity == ErrorSeverity.critical &&
        DateTime.now().difference(e.timestamp) < const Duration(hours: 1)
    );
    
    return recentCritical.isNotEmpty;
  }

  /// Get most common error
  String? _getMostCommonError() {
    if (_errorCounts.isEmpty) return null;
    
    return _errorCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Calculate error trends
  Map<String, dynamic> _calculateErrorTrends() {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    
    final recentErrors = _errors.where((e) => e.timestamp.isAfter(oneHourAgo));
    final errorsByType = <String, int>{};
    
    for (final error in recentErrors) {
      final type = error.error.runtimeType.toString();
      errorsByType[type] = (errorsByType[type] ?? 0) + 1;
    }
    
    return {
      'trending_errors': errorsByType,
      'error_rate': recentErrors.length, // errors per hour
    };
  }
}

enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

class AppError {
  final dynamic error;
  final StackTrace? stackTrace;
  final String context;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const AppError({
    required this.error,
    this.stackTrace,
    required this.context,
    required this.severity,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'error_type': error.runtimeType.toString(),
      'error_message': error.toString(),
      'context': context,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class RecoveryStrategy {
  final String name;
  final bool Function(AppError error) canRecover;
  final Future<bool> Function(AppError error) recover;

  const RecoveryStrategy({
    required this.name,
    required this.canRecover,
    required this.recover,
  });
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallbackWidget;
  final String context;
  final Function(dynamic error, StackTrace? stackTrace)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackWidget,
    required this.context,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  dynamic _error;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallbackWidget ?? _buildDefaultErrorWidget();
    }

    return ErrorWidget.builder = (FlutterErrorDetails details) {
      widget.onError?.call(details.exception, details.stack);
      
      if (mounted) {
        setState(() {
          _hasError = true;
          _error = details.exception;
        });
      }
      
      return widget.fallbackWidget ?? _buildDefaultErrorWidget();
    };
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 32),
          const SizedBox(height: 8),
          Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.red.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Context: ${widget.context}',
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _error = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}