import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'performance_monitor.dart';

/// Performance optimization utility that provides automatic performance improvements
class PerformanceOptimizer {
  static final Map<String, Timer> _debounceTimers = {};
  static final Map<String, DateTime> _lastOperationTimes = {};
  static final List<String> _slowOperations = [];

  // Configuration
  static const int _defaultDebounceMs = 300;
  static const int _slowOperationThresholdMs = 1000;
  static const int _maxCacheSize = 100;

  /// Debounce function calls to prevent excessive executions
  static void debounce(String key, VoidCallback callback,
      {int delayMs = _defaultDebounceMs}) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(Duration(milliseconds: delayMs), () {
      callback();
      _debounceTimers.remove(key);
    });
  }

  /// Throttle function calls to limit execution frequency
  static bool throttle(String key, {int minIntervalMs = 1000}) {
    final now = DateTime.now();
    final lastTime = _lastOperationTimes[key];

    if (lastTime == null ||
        now.difference(lastTime).inMilliseconds >= minIntervalMs) {
      _lastOperationTimes[key] = now;
      return true;
    }
    return false;
  }

  /// Monitor and track slow operations
  static Future<T> monitorSlowOperation<T>(
      String operation, Future<T> Function() callback) async {
    PerformanceMonitor.startTimer(operation);

    try {
      final result = await callback();
      final duration = PerformanceMonitor.endTimer(operation);

      if (duration.inMilliseconds > _slowOperationThresholdMs) {
        _slowOperations.add(operation);
        if (kDebugMode) {
          print(
              '🐌 Slow operation detected: $operation (${duration.inMilliseconds}ms)');
        }
      }

      return result;
    } catch (e) {
      PerformanceMonitor.endTimer(operation);
      rethrow;
    }
  }

  /// Optimize list rendering with pagination
  static List<T> paginateList<T>(List<T> items,
      {int pageSize = 20, int currentPage = 0}) {
    final startIndex = currentPage * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, items.length);
    return items.sublist(startIndex, endIndex);
  }

  /// Cache expensive computations
  static final Map<String, dynamic> _computationCache = {};

  static T cachedComputation<T>(String key, T Function() computation,
      {Duration? ttl}) {
    final cacheEntry = _computationCache[key];
    if (cacheEntry != null) {
      final entry = cacheEntry as Map<String, dynamic>;
      final timestamp = entry['timestamp'] as DateTime;
      final value = entry['value'] as T;

      if (ttl == null || DateTime.now().difference(timestamp) < ttl) {
        return value;
      }
    }

    final result = computation();
    _computationCache[key] = {
      'value': result,
      'timestamp': DateTime.now(),
    };

    // Clean up old cache entries if cache is too large
    if (_computationCache.length > _maxCacheSize) {
      final oldestKey = _computationCache.keys.first;
      _computationCache.remove(oldestKey);
    }

    return result;
  }

  /// Optimize image loading
  static Widget optimizedImage({
    required String imageUrl,
    required Widget placeholder,
    required Widget errorWidget,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder;
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget;
      },
    );
  }

  /// Optimize search with debouncing
  static void debouncedSearch(String query, Function(String) onSearch,
      {int delayMs = 500}) {
    debounce('search', () => onSearch(query), delayMs: delayMs);
  }

  /// Get performance insights
  static Map<String, dynamic> getPerformanceInsights() {
    final summary = PerformanceMonitor.getPerformanceSummary();
    final insights = <String, dynamic>{
      'slow_operations': _slowOperations,
      'cache_size': _computationCache.length,
      'active_debounce_timers': _debounceTimers.length,
      'performance_summary': summary,
    };

    return insights;
  }

  /// Clear all optimizations
  static void clear() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _lastOperationTimes.clear();
    _slowOperations.clear();
    _computationCache.clear();
  }

  /// Print performance insights
  static void printPerformanceInsights() {
    if (!kDebugMode) return;

    final insights = getPerformanceInsights();

    print('\n🚀 PERFORMANCE INSIGHTS');
    print('=' * 50);
    print('Slow Operations: ${insights['slow_operations'].length}');
    print('Cache Size: ${insights['cache_size']}');
    print('Active Debounce Timers: ${insights['active_debounce_timers']}');

    if (insights['slow_operations'].isNotEmpty) {
      print('\n🐌 Slow Operations:');
      for (final op in insights['slow_operations']) {
        print('  - $op');
      }
    }

    print('=' * 50);
  }
}

/// Extension for easy performance optimization
extension PerformanceOptimization on Widget {
  /// Wrap widget with performance monitoring
  Widget withPerformanceMonitoring(String operation) {
    PerformanceMonitor.startTimer(operation);
    return this;
  }
}

/// Optimized list widget with built-in performance features
class OptimizedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final int pageSize;
  final bool enablePagination;
  final Widget? emptyWidget;
  final Widget? loadingWidget;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.pageSize = 20,
    this.enablePagination = true,
    this.emptyWidget,
    this.loadingWidget,
  });

  @override
  State<OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<OptimizedListView<T>> {
  int _currentPage = 0;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.enablePagination) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _currentPage++;
          _isLoadingMore = false;
        });
      }
    });
  }

  List<T> get _displayedItems {
    if (!widget.enablePagination) return widget.items;
    return PerformanceOptimizer.paginateList(
      widget.items,
      pageSize: widget.pageSize,
      currentPage: _currentPage,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return widget.emptyWidget ?? const Center(child: Text('No items found'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _displayedItems.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _displayedItems.length) {
          return widget.loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        return widget.itemBuilder(context, _displayedItems[index], index);
      },
    );
  }
}
