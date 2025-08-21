import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PerformanceService extends ChangeNotifier {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // Performance metrics
  final Queue<PerformanceMetric> _metrics = Queue<PerformanceMetric>();
  final Map<String, Stopwatch> _activeTimers = {};
  final Map<String, int> _operationCounts = {};
  
  // Memory management
  Timer? _memoryCleanupTimer;
  Timer? _metricsCleanupTimer;
  
  // Settings
  static const int maxMetricsHistory = 1000;
  static const Duration metricsRetention = Duration(hours: 1);
  static const Duration memoryCleanupInterval = Duration(minutes: 5);

  // Getters
  List<PerformanceMetric> get recentMetrics => _metrics.toList();
  Map<String, double> get averageMetrics => _calculateAverageMetrics();
  bool get hasPerformanceIssues => _detectPerformanceIssues();

  /// Initialize performance monitoring
  void initialize() {
    // Start periodic cleanup
    _startPeriodicCleanup();
    
    // Monitor frame rendering
    _startFrameMonitoring();
    
    debugPrint('Performance monitoring initialized');
  }

  /// Start timing an operation
  void startTimer(String operationName) {
    if (_activeTimers.containsKey(operationName)) {
      debugPrint('Warning: Timer $operationName already running');
      return;
    }
    
    _activeTimers[operationName] = Stopwatch()..start();
  }

  /// Stop timing an operation and record metric
  void stopTimer(String operationName, {Map<String, dynamic>? metadata}) {
    final stopwatch = _activeTimers.remove(operationName);
    if (stopwatch == null) {
      debugPrint('Warning: Timer $operationName not found');
      return;
    }
    
    stopwatch.stop();
    
    // Record metric
    _recordMetric(PerformanceMetric(
      operationName: operationName,
      duration: stopwatch.elapsed,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    ));
    
    // Update operation count
    _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
  }

  /// Record a custom metric
  void recordMetric({
    required String operationName,
    required Duration duration,
    Map<String, dynamic>? metadata,
  }) {
    _recordMetric(PerformanceMetric(
      operationName: operationName,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    ));
  }

  /// Record memory usage
  void recordMemoryUsage(String context) {
    // This would typically integrate with platform-specific memory APIs
    _recordMetric(PerformanceMetric(
      operationName: 'memory_usage',
      duration: Duration.zero,
      timestamp: DateTime.now(),
      metadata: {
        'context': context,
        'heap_size': 'N/A', // Would get actual heap size
        'used_memory': 'N/A', // Would get actual used memory
      },
    ));
  }

  /// Optimize image loading
  Future<void> optimizeImageLoading() async {
    // Clear image cache if memory pressure is high
    if (hasPerformanceIssues) {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      _recordMetric(PerformanceMetric(
        operationName: 'image_cache_clear',
        duration: Duration.zero,
        timestamp: DateTime.now(),
        metadata: {'reason': 'memory_pressure'},
      ));
    }
    
    // Configure image cache size
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB
  }

  /// Optimize list performance
  Widget optimizeListBuilder({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    ScrollController? controller,
  }) {
    return ListView.builder(
      controller: controller,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Wrap items for performance monitoring
        return _PerformanceWrapper(
          operationName: 'list_item_build',
          metadata: {'index': index},
          child: itemBuilder(context, index),
        );
      },
      // Optimize for performance
      cacheExtent: 250.0, // Pre-build items slightly off-screen
      addAutomaticKeepAlives: false, // Don't keep items alive unnecessarily
      addRepaintBoundaries: true, // Isolate repaints
    );
  }

  /// Debounce function calls to reduce performance impact
  Timer? _debounceTimer;
  void debounce(VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// Batch API calls to reduce network overhead
  final Map<String, List<Function>> _batchedCalls = {};
  Timer? _batchTimer;
  
  void batchApiCall(String endpoint, Function call) {
    if (!_batchedCalls.containsKey(endpoint)) {
      _batchedCalls[endpoint] = [];
    }
    
    _batchedCalls[endpoint]!.add(call);
    
    // Execute batch after delay
    _batchTimer?.cancel();
    _batchTimer = Timer(const Duration(milliseconds: 100), () {
      _executeBatchedCalls();
    });
  }

  /// Preload critical data
  Future<void> preloadCriticalData() async {
    startTimer('preload_critical_data');
    
    try {
      // Preload would happen here - user profile, settings, etc.
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate
      
      stopTimer('preload_critical_data', metadata: {'success': true});
    } catch (e) {
      stopTimer('preload_critical_data', metadata: {'success': false, 'error': e.toString()});
    }
  }

  /// Reduce memory usage
  void optimizeMemoryUsage() {
    // Clear various caches
    optimizeImageLoading();
    
    // Force garbage collection (if available)
    _forceGarbageCollection();
    
    // Clear old metrics
    _cleanupOldMetrics();
    
    recordMemoryUsage('optimization_cycle');
  }

  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};
    
    // Average durations by operation
    final avgMetrics = _calculateAverageMetrics();
    report['average_durations'] = avgMetrics;
    
    // Operation counts
    report['operation_counts'] = Map.from(_operationCounts);
    
    // Performance issues
    report['has_issues'] = hasPerformanceIssues;
    report['slow_operations'] = _getSlowOperations();
    
    // Memory metrics
    report['memory_metrics'] = _getMemoryMetrics();
    
    // Recent performance trends
    report['trends'] = _calculatePerformanceTrends();
    
    return report;
  }

  /// Record metric internally
  void _recordMetric(PerformanceMetric metric) {
    _metrics.add(metric);
    
    // Cleanup old metrics
    if (_metrics.length > maxMetricsHistory) {
      _metrics.removeFirst();
    }
    
    // Log slow operations
    if (metric.duration.inMilliseconds > 1000) {
      debugPrint('Slow operation detected: ${metric.operationName} took ${metric.duration.inMilliseconds}ms');
    }
    
    notifyListeners();
  }

  /// Calculate average metrics
  Map<String, double> _calculateAverageMetrics() {
    final averages = <String, double>{};
    final operations = <String, List<Duration>>{};
    
    for (final metric in _metrics) {
      if (!operations.containsKey(metric.operationName)) {
        operations[metric.operationName] = [];
      }
      operations[metric.operationName]!.add(metric.duration);
    }
    
    for (final entry in operations.entries) {
      final durations = entry.value;
      final totalMs = durations.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
      averages[entry.key] = totalMs / durations.length;
    }
    
    return averages;
  }

  /// Detect performance issues
  bool _detectPerformanceIssues() {
    final avgMetrics = _calculateAverageMetrics();
    
    // Check for slow operations
    for (final entry in avgMetrics.entries) {
      if (entry.value > 500) { // > 500ms average
        return true;
      }
    }
    
    // Check for high operation frequency
    for (final count in _operationCounts.values) {
      if (count > 1000) { // > 1000 operations
        return true;
      }
    }
    
    return false;
  }

  /// Get slow operations
  List<String> _getSlowOperations() {
    final avgMetrics = _calculateAverageMetrics();
    return avgMetrics.entries
        .where((entry) => entry.value > 500)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get memory metrics
  Map<String, dynamic> _getMemoryMetrics() {
    final memoryMetrics = _metrics
        .where((m) => m.operationName == 'memory_usage')
        .toList();
    
    return {
      'memory_samples': memoryMetrics.length,
      'last_recorded': memoryMetrics.isNotEmpty 
          ? memoryMetrics.last.timestamp.toIso8601String() 
          : null,
    };
  }

  /// Calculate performance trends
  Map<String, dynamic> _calculatePerformanceTrends() {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));
    
    final recentMetrics = _metrics
        .where((m) => m.timestamp.isAfter(oneHourAgo))
        .toList();
    
    return {
      'metrics_last_hour': recentMetrics.length,
      'unique_operations': recentMetrics.map((m) => m.operationName).toSet().length,
      'avg_duration_trend': recentMetrics.isNotEmpty
          ? recentMetrics.fold<int>(0, (sum, m) => sum + m.duration.inMilliseconds) / recentMetrics.length
          : 0,
    };
  }

  /// Start periodic cleanup
  void _startPeriodicCleanup() {
    _memoryCleanupTimer = Timer.periodic(memoryCleanupInterval, (_) {
      optimizeMemoryUsage();
    });
    
    _metricsCleanupTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _cleanupOldMetrics();
    });
  }

  /// Start frame monitoring
  void _startFrameMonitoring() {
    WidgetsBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        if (timing.totalSpan.inMilliseconds > 16) { // > 16ms (60fps threshold)
          _recordMetric(PerformanceMetric(
            operationName: 'frame_render',
            duration: timing.totalSpan,
            timestamp: DateTime.now(),
            metadata: {
              'build_time': timing.buildDuration.inMicroseconds,
              'raster_time': timing.rasterDuration.inMicroseconds,
            },
          ));
        }
      }
    });
  }

  /// Execute batched API calls
  void _executeBatchedCalls() {
    for (final entry in _batchedCalls.entries) {
      final endpoint = entry.key;
      final calls = entry.value;
      
      startTimer('batch_api_$endpoint');
      
      // Execute all calls for this endpoint
      for (final call in calls) {
        try {
          call();
        } catch (e) {
          debugPrint('Batched call error: $e');
        }
      }
      
      stopTimer('batch_api_$endpoint', metadata: {'call_count': calls.length});
    }
    
    _batchedCalls.clear();
  }

  /// Force garbage collection (platform-specific implementation would go here)
  void _forceGarbageCollection() {
    // This would use platform-specific APIs to suggest GC
    // For now, we just record that we attempted it
    _recordMetric(PerformanceMetric(
      operationName: 'garbage_collection',
      duration: Duration.zero,
      timestamp: DateTime.now(),
      metadata: {'triggered': 'manual'},
    ));
  }

  /// Cleanup old metrics
  void _cleanupOldMetrics() {
    final cutoff = DateTime.now().subtract(metricsRetention);
    _metrics.removeWhere((metric) => metric.timestamp.isBefore(cutoff));
  }

  @override
  void dispose() {
    _memoryCleanupTimer?.cancel();
    _metricsCleanupTimer?.cancel();
    _debounceTimer?.cancel();
    _batchTimer?.cancel();
    super.dispose();
  }
}

class PerformanceMetric {
  final String operationName;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'operation_name': operationName,
      'duration_ms': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class _PerformanceWrapper extends StatelessWidget {
  final String operationName;
  final Map<String, dynamic>? metadata;
  final Widget child;

  const _PerformanceWrapper({
    required this.operationName,
    required this.child,
    this.metadata,
  });

  @override
  Widget build(BuildContext context) {
    final performanceService = PerformanceService();
    
    return RepaintBoundary(
      child: Builder(
        builder: (context) {
          performanceService.startTimer(operationName);
          
          return NotificationListener<LayoutChangedNotification>(
            onNotification: (notification) {
              performanceService.stopTimer(operationName, metadata: metadata);
              return false;
            },
            child: child,
          );
        },
      ),
    );
  }
}