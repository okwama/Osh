import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'performance_monitor.dart';

/// Startup monitoring utility to track app initialization performance
class StartupMonitor {
  static final Map<String, Stopwatch> _startupTimers = {};
  static final List<String> _startupSteps = [];
  static final List<String> _startupErrors = [];
  static bool _isInitialized = false;

  /// Start monitoring a startup step
  static void startStep(String stepName) {
    _startupTimers[stepName] = Stopwatch()..start();
    _startupSteps.add(stepName);

    if (kDebugMode) {
      print('🚀 Starting: $stepName');
    }
  }

  /// End monitoring a startup step
  static void endStep(String stepName) {
    final timer = _startupTimers[stepName];
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsed;

      if (kDebugMode) {
        print('✅ Completed: $stepName (${duration.inMilliseconds}ms)');
      }

      // Track slow startup steps
      if (duration.inMilliseconds > 1000) {
        print('🐌 Slow startup step: $stepName (${duration.inMilliseconds}ms)');
      }
    }
  }

  /// Track startup error
  static void trackError(String stepName, dynamic error) {
    _startupErrors.add('$stepName: $error');
    print('❌ Startup error in $stepName: $error');
  }

  /// Mark startup as complete
  static void markInitialized() {
    _isInitialized = true;
    _printStartupReport();
  }

  /// Check if startup is complete
  static bool get isInitialized => _isInitialized;

  /// Get startup performance summary
  static Map<String, dynamic> getStartupSummary() {
    final summary = <String, dynamic>{};

    for (final entry in _startupTimers.entries) {
      final stepName = entry.key;
      final timer = entry.value;

      if (timer.isRunning) {
        timer.stop();
      }

      summary[stepName] = {
        'duration_ms': timer.elapsed.inMilliseconds,
        'completed': true,
      };
    }

    summary['total_steps'] = _startupSteps.length;
    summary['errors'] = _startupErrors;
    summary['is_initialized'] = _isInitialized;

    return summary;
  }

  /// Print startup performance report
  static void _printStartupReport() {
    if (!kDebugMode) return;

    print('\n🚀 STARTUP PERFORMANCE REPORT');
    print('=' * 50);

    final summary = getStartupSummary();
    int totalTime = 0;

    for (final entry in summary.entries) {
      if (entry.key == 'total_steps' ||
          entry.key == 'errors' ||
          entry.key == 'is_initialized') continue;

      final data = entry.value as Map<String, dynamic>;
      final duration = data['duration_ms'] as int;
      totalTime += duration;

      print('${entry.key}: ${duration}ms');
    }

    print('\n📊 Summary:');
    print('  Total Steps: ${summary['total_steps']}');
    print('  Total Time: ${totalTime}ms');
    print('  Errors: ${summary['errors'].length}');
    print('  Initialized: ${summary['is_initialized']}');

    if (summary['errors'].isNotEmpty) {
      print('\n❌ Errors:');
      for (final error in summary['errors']) {
        print('  - $error');
      }
    }

    print('=' * 50);
  }

  /// Clear all startup monitoring data
  static void clear() {
    _startupTimers.clear();
    _startupSteps.clear();
    _startupErrors.clear();
    _isInitialized = false;
  }
}

/// Extension for easy startup monitoring
extension StartupMonitoring on Future {
  /// Monitor the startup performance of a Future
  Future<T> monitorStartup<T>(String stepName) async {
    StartupMonitor.startStep(stepName);

    try {
      final result = await this as T;
      StartupMonitor.endStep(stepName);
      return result;
    } catch (e) {
      StartupMonitor.trackError(stepName, e);
      StartupMonitor.endStep(stepName);
      rethrow;
    }
  }
}

/// Optimized startup wrapper
class OptimizedStartup {
  static Future<void> initialize({
    required Future<void> Function() initialization,
    String? stepName,
  }) async {
    final name = stepName ?? 'app_initialization';

    return initialization().monitorStartup(name);
  }

  /// Initialize with timeout and fallback
  static Future<T> initializeWithTimeout<T>({
    required Future<T> Function() operation,
    Duration timeout = const Duration(seconds: 10),
    T? fallbackValue,
    String? stepName,
  }) async {
    final name = stepName ?? 'timeout_operation';

    try {
      return await operation().timeout(timeout).monitorStartup(name);
    } catch (e) {
      if (e is TimeoutException) {
        print('⏰ Operation timed out: $name');
        if (fallbackValue != null) {
          return fallbackValue;
        }
      }
      rethrow;
    }
  }

  /// Initialize services in parallel
  static Future<List<T>> initializeParallel<T>({
    required List<Future<T> Function()> operations,
    List<String>? stepNames,
  }) async {
    final names = stepNames ??
        List.generate(operations.length, (i) => 'parallel_operation_$i');

    final futures = <Future<T>>[];

    for (int i = 0; i < operations.length; i++) {
      futures.add(operations[i]().monitorStartup(names[i]));
    }

    return await Future.wait(futures);
  }
}
