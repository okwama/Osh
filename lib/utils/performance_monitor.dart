import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performance monitoring utility for tracking app startup and operation times
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<Duration>> _measurements = {};
  static final List<String> _startupSteps = [];

  /// Start timing an operation
  static void startTimer(String operation) {
    _timers[operation] = Stopwatch()..start();
    if (kDebugMode) {
      print('⏱️ Started timing: $operation');
    }
  }

  /// End timing an operation
  static Duration endTimer(String operation) {
    final timer = _timers[operation];
    if (timer == null) {
      print('⚠️ No timer found for operation: $operation');
      return Duration.zero;
    }

    timer.stop();
    final duration = timer.elapsed;

    // Store measurement
    _measurements.putIfAbsent(operation, () => []).add(duration);

    if (kDebugMode) {
      print('⏱️ $operation completed in ${duration.inMilliseconds}ms');
    }

    _timers.remove(operation);
    return duration;
  }

  /// Track startup step
  static void trackStartupStep(String step) {
    _startupSteps.add(step);
    if (kDebugMode) {
      print('🚀 Startup step: $step');
    }
  }

  /// Get performance summary
  static Map<String, dynamic> getPerformanceSummary() {
    final summary = <String, dynamic>{};

    for (final entry in _measurements.entries) {
      final operation = entry.key;
      final measurements = entry.value;

      if (measurements.isNotEmpty) {
        final avgDuration =
            measurements.map((d) => d.inMilliseconds).reduce((a, b) => a + b) /
                measurements.length;

        summary[operation] = {
          'average_ms': avgDuration.round(),
          'count': measurements.length,
          'total_ms':
              measurements.map((d) => d.inMilliseconds).reduce((a, b) => a + b),
        };
      }
    }

    summary['startup_steps'] = _startupSteps;
    return summary;
  }

  /// Check if operation is taking too long
  static bool isOperationSlow(String operation, {int thresholdMs = 1000}) {
    final timer = _timers[operation];
    if (timer == null) return false;

    return timer.elapsed.inMilliseconds > thresholdMs;
  }

  /// Get slow operations
  static List<String> getSlowOperations({int thresholdMs = 1000}) {
    final slowOperations = <String>[];

    for (final entry in _measurements.entries) {
      final operation = entry.key;
      final measurements = entry.value;

      if (measurements.isNotEmpty) {
        final avgDuration =
            measurements.map((d) => d.inMilliseconds).reduce((a, b) => a + b) /
                measurements.length;

        if (avgDuration > thresholdMs) {
          slowOperations.add(operation);
        }
      }
    }

    return slowOperations;
  }

  /// Clear all measurements
  static void clear() {
    _timers.clear();
    _measurements.clear();
    _startupSteps.clear();
  }

  /// Print performance report
  static void printPerformanceReport() {
    if (!kDebugMode) return;

    print('\n📊 PERFORMANCE REPORT');
    print('=' * 50);

    final summary = getPerformanceSummary();

    for (final entry in summary.entries) {
      if (entry.key == 'startup_steps') continue;

      final data = entry.value as Map<String, dynamic>;
      print('${entry.key}:');
      print('  Average: ${data['average_ms']}ms');
      print('  Count: ${data['count']}');
      print('  Total: ${data['total_ms']}ms');
    }

    print('\n🚀 Startup Steps:');
    for (final step in _startupSteps) {
      print('  - $step');
    }

    final slowOps = getSlowOperations();
    if (slowOps.isNotEmpty) {
      print('\n🐌 Slow Operations:');
      for (final op in slowOps) {
        print('  - $op');
      }
    }

    print('=' * 50);
  }
}

/// Extension for easy performance monitoring
extension PerformanceMonitoring on Future {
  /// Monitor the performance of a Future
  Future<T> monitor<T>(String operation) async {
    PerformanceMonitor.startTimer(operation);
    try {
      final result = await this as T;
      PerformanceMonitor.endTimer(operation);
      return result;
    } catch (e) {
      PerformanceMonitor.endTimer(operation);
      rethrow;
    }
  }
}
