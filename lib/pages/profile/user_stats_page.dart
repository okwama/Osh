import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:woosh/services/core/session_service.dart';
import 'package:woosh/services/core/target_service.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:woosh/utils/app_theme.dart' hide CreamGradientCard;
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/gradient_widgets.dart';
import 'package:woosh/widgets/cream_gradient_card.dart';
import 'package:woosh/controllers/profile_controller.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class UserStatsPage extends StatefulWidget {
  const UserStatsPage({super.key});

  @override
  State<UserStatsPage> createState() => _UserStatsPageState();
}

class _UserStatsPageState extends State<UserStatsPage> {
  final ProfileController _profileController = Get.find<ProfileController>();
  String _selectedPeriod = 'week';
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>>? _loginData;
  List<Map<String, dynamic>>? _journeyData;
  String? _userId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCustomDate = false;
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  final _cache = <String, Map<String, dynamic>>{};

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _scrollController.addListener(_onScroll);
    _precacheData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreData();
    }
  }

  Future<void> _precacheData() async {
    if (_userId == null) return;

    // Precache next period's data
    final periods = ['today', 'week', 'month'];
    for (final period in periods) {
      if (period != _selectedPeriod) {
        final dateRange = _getDateRangeForPeriod(period);
        final cacheKey = '${_userId}_${dateRange['start']}_${dateRange['end']}';
        if (!_cache.containsKey(cacheKey)) {
          await _fetchAndCacheData(dateRange['start'] as String,
              dateRange['end'] as String, cacheKey);
        }
      }
    }
  }

  Future<void> _fetchAndCacheData(
      String startDate, String endDate, String cacheKey) async {
    try {
      final loginResponse = await SessionService.getCurrentSession(
        int.parse(_userId!),
      );
      final journeyResponse = await TargetService.getDailyVisitTargets(
        userId: _userId!,
      );

      if (loginResponse != null) {
        _cache[cacheKey] = {
          'loginData': {
            'userId': _userId,
            'totalHours': 0,
            'totalMinutes': 0,
            'sessionCount': 0,
            'formattedDuration': '0h 0m',
            'averageSessionDuration': '0m'
          },
          'journeyData': {
            'userId': _userId,
            'totalPlans': 0,
            'completedVisits': 0,
            'pendingVisits': 0,
            'missedVisits': 0,
            'clientVisits': [],
            'completionRate': '0%'
          },
        };
      }
    } catch (e) {
      print('Error precaching data: $e');
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      // Simulate loading more data (replace with actual implementation)
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _hasMoreData = false; // Set to false if no more data
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  Map<String, String> _getDateRangeForPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'today':
        return {
          'start': DateFormat('yyyy-MM-dd').format(now),
          'end': DateFormat('yyyy-MM-dd').format(now),
        };
      case 'week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return {
          'start': DateFormat('yyyy-MM-dd').format(startOfWeek),
          'end': DateFormat('yyyy-MM-dd').format(now),
        };
      case 'month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return {
          'start': DateFormat('yyyy-MM-dd').format(startOfMonth),
          'end': DateFormat('yyyy-MM-dd').format(now),
        };
      default:
        return {
          'start': DateFormat('yyyy-MM-dd').format(now),
          'end': DateFormat('yyyy-MM-dd').format(now),
        };
    }
  }

  Widget _buildSkeletonCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonUI() {
    return Column(
      children: [
        _buildSkeletonCard(),
        const SizedBox(height: 6),
        _buildSkeletonCard(),
        const SizedBox(height: 6),
        _buildSkeletonCard(),
        const SizedBox(height: 6),
        _buildSkeletonCard(),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(
          valueColor:
              AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildSkeletonUI();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 11),
            GoldGradientButton(
              onPressed: _loadStats,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 12),
            _buildStatsCards(),
            if (_isLoadingMore) _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  void _loadUserId() {
    final userData = GetStorage().read('salesRep');
    if (userData != null && userData['id'] != null) {
      setState(() => _userId = userData['id'].toString());
      _loadStats();
    } else {
      setState(() => _error = 'User ID not found');
    }
  }

  Future<void> _loadStats() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String urlParams = '';
      if (_isCustomDate && _startDate != null && _endDate != null) {
        final format = DateFormat('yyyy-MM-dd');
        urlParams =
            '?startDate=${format.format(_startDate!)}&endDate=${format.format(_endDate!)}';
      } else {
        final dateRange = _getDateRange();
        urlParams =
            '?startDate=${dateRange['start']}&endDate=${dateRange['end']}';
      }

      print('Fetching stats for user $_userId with params: $urlParams');

      // Clear cache for this specific key
      final cacheKey = '${_userId}_$urlParams';
      _cache.remove(cacheKey);

      // Get date range for session history
      final dateRange = _getDateRange();

      // Load data in parallel
      final responses = await Future.wait([
        SessionService.getSessionHistory(_userId!,
            startDate: dateRange['start'], endDate: dateRange['end']),
        TargetService.getDailyVisitTargets(userId: _userId!),
      ]);

      final sessionHistoryResponse = responses[0];
      final journeyResponse = responses[1];

      print(
          'Session History Response Status: ${sessionHistoryResponse['success'] ? '200' : '404'}');
      print(
          'Journey Visits Response Status: ${journeyResponse != null ? '200' : '404'}');

      // Handle case where there's no journey data
      if (journeyResponse != null) {
        // Calculate session statistics from history
        final sessions =
            sessionHistoryResponse['sessions'] as List<dynamic>? ?? [];
        final totalSessions = sessions.length;

        // Calculate total duration from completed sessions
        int totalMinutes = 0;
        for (final session in sessions) {
          if (session['sessionStart'] != null &&
              session['sessionEnd'] != null) {
            final start = DateTime.parse(session['sessionStart']);
            final end = DateTime.parse(session['sessionEnd']);
            final duration = end.difference(start).inMinutes;
            totalMinutes += duration;
          }
        }

        final totalHours = (totalMinutes / 60).floor();
        final remainingMinutes = totalMinutes % 60;
        final avgMinutes =
            totalSessions > 0 ? (totalMinutes / totalSessions).round() : 0;
        final avgHours = (avgMinutes / 60).floor();
        final avgRemainingMinutes = avgMinutes % 60;

        final loginData = {
          'userId': _userId,
          'totalHours': totalHours,
          'totalMinutes': remainingMinutes,
          'sessionCount': totalSessions,
          'formattedDuration': '${totalHours}h ${remainingMinutes}m',
          'averageSessionDuration': avgHours > 0
              ? '${avgHours}h ${avgRemainingMinutes}m'
              : '${avgMinutes}m'
        };
        final journeyData = {
          'userId': _userId,
          'totalPlans': 0,
          'completedVisits': 0,
          'pendingVisits': 0,
          'missedVisits': 0,
          'clientVisits': [],
          'completionRate': '0%'
        };

        print('Raw Login Hours Data: ${json.encode(loginData)}');
        print('Raw Journey Visits Data: ${json.encode(journeyData)}');

        // Validate and process the data
        if (_isValidData(loginData) && _isValidJourneyData(journeyData)) {
          print('Data validation passed');

          // Cache the data
          _cache[cacheKey] = {
            'loginData': loginData,
            'journeyData': journeyData,
          };

          // Update UI in a single setState call
          setState(() {
            _loginData = [loginData];
            _journeyData = [journeyData];
            _isLoading = false;
          });

          // Print processed data
          final stats = _getFilteredStats();
          print('Processed Stats:');
          print('Formatted Duration: ${stats['formattedDuration']}');
          print('Total Hours: ${stats['totalHours']}');
          print('Total Minutes: ${stats['totalMinutes']}');
          print('Session Count: ${stats['sessionCount']}');
          print('Average Session Duration: ${stats['averageSessionDuration']}');
          print('Total Plans: ${stats['totalPlans']}');
          print('Completed Visits: ${stats['completedVisits']}');
          print('Pending Visits: ${stats['pendingVisits']}');
          print('Missed Visits: ${stats['missedVisits']}');
          print('Completion Rate: ${stats['completionRate']}');
          print('Client Visits: ${json.encode(stats['clientVisits'])}');
        } else {
          print('Data validation failed');
          print('Login Data Valid: ${_isValidData(loginData)}');
          print('Journey Data Valid: ${_isValidJourneyData(journeyData)}');
          throw Exception('Invalid data format received from server');
        }
      } else {
        final errorMessage = 'Failed to load journey data from services';
        print('Error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Exception caught: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _isValidData(Map<String, dynamic> data) {
    final requiredFields = [
      'userId',
      'totalHours',
      'totalMinutes',
      'sessionCount',
      'formattedDuration',
      'averageSessionDuration'
    ];

    for (final field in requiredFields) {
      if (data[field] == null) {
        print('Missing required field: $field');
        return false;
      }
    }

    // Validate numeric fields
    if (data['totalHours'] is! int) {
      print('Invalid totalHours type: ${data['totalHours'].runtimeType}');
      return false;
    }
    if (data['totalMinutes'] is! int) {
      print('Invalid totalMinutes type: ${data['totalMinutes'].runtimeType}');
      return false;
    }
    if (data['sessionCount'] is! int) {
      print('Invalid sessionCount type: ${data['sessionCount'].runtimeType}');
      return false;
    }

    // Validate duration format
    if (data['formattedDuration'] is! String ||
        !RegExp(r'^\d+h \d+m$').hasMatch(data['formattedDuration'])) {
      print('Invalid formattedDuration: ${data['formattedDuration']}');
      return false;
    }

    // Validate average session duration format (accepts both "Xm" and "Xh Ym" formats)
    if (data['averageSessionDuration'] is! String ||
        !RegExp(r'^(\d+h\s)?\d+m$').hasMatch(data['averageSessionDuration'])) {
      print(
          'Invalid averageSessionDuration: ${data['averageSessionDuration']}');
      return false;
    }

    return true;
  }

  bool _isValidJourneyData(Map<String, dynamic> data) {
    final requiredFields = [
      'userId',
      'totalPlans',
      'completedVisits',
      'pendingVisits',
      'missedVisits',
      'clientVisits',
      'completionRate'
    ];

    for (final field in requiredFields) {
      if (data[field] == null) {
        print('Missing required journey field: $field');
        return false;
      }
    }

    return true;
  }

  Map<String, String> _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'today':
        return {
          'start': DateFormat('yyyy-MM-dd').format(now),
          'end': DateFormat('yyyy-MM-dd').format(now),
        };
      case 'week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return {
          'start': DateFormat('yyyy-MM-dd').format(startOfWeek),
          'end': DateFormat('yyyy-MM-dd').format(now),
        };
      case 'month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return {
          'start': DateFormat('yyyy-MM-dd').format(startOfMonth),
          'end': DateFormat('yyyy-MM-dd').format(now),
        };
      default:
        return {
          'start': DateFormat('yyyy-MM-dd').format(now),
          'end': DateFormat('yyyy-MM-dd').format(now),
        };
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _isCustomDate = true;
      });
      _loadStats();
    }
  }

  Map<String, dynamic> _getFilteredStats() {
    if (_loginData == null || _journeyData == null) {
      return {
        'formattedDuration': '0h 0m',
        'completedVisits': 0,
        'completionRate': '0%',
        'averageSessionDuration': '0m',
        'totalHours': 0,
        'totalMinutes': 0,
        'sessionCount': 0,
        'totalPlans': 0,
        'pendingVisits': 0,
        'missedVisits': 0,
        'clientVisits': [],
      };
    }

    final loginStats = _loginData![0];
    final journeyStats = _journeyData![0];

    // Convert and validate numeric values
    final totalHours =
        loginStats['totalHours'] is int ? loginStats['totalHours'] : 0;
    final totalMinutes =
        loginStats['totalMinutes'] is int ? loginStats['totalMinutes'] : 0;
    final sessionCount =
        loginStats['sessionCount'] is int ? loginStats['sessionCount'] : 0;

    // Calculate correct total hours and minutes
    final totalMinutesFromHours = totalHours * 60;
    final totalMinutesCombined = totalMinutesFromHours + totalMinutes;
    final correctedHours = (totalMinutesCombined / 60).floor();
    final correctedMinutes = totalMinutesCombined % 60;

    // Format duration string correctly
    final formattedDuration = '$correctedHours ${correctedMinutes}m';

    // Calculate average session duration correctly
    final avgMinutes =
        sessionCount > 0 ? (totalMinutesCombined / sessionCount).round() : 0;
    final avgHours = (avgMinutes / 60).floor();
    final avgRemainingMinutes = avgMinutes % 60;
    final averageSessionDuration = avgHours > 0
        ? '${avgHours}h ${avgRemainingMinutes}m'
        : '${avgMinutes}m';

    return {
      'formattedDuration': formattedDuration,
      'completedVisits': journeyStats['completedVisits'],
      'completionRate': journeyStats['completionRate'],
      'averageSessionDuration': averageSessionDuration,
      'totalHours': correctedHours,
      'totalMinutes': correctedMinutes,
      'sessionCount': sessionCount,
      'totalPlans': journeyStats['totalPlans'],
      'pendingVisits': journeyStats['pendingVisits'],
      'missedVisits': journeyStats['missedVisits'],
      'clientVisits': journeyStats['clientVisits'],
      'totalMinutesCombined': totalMinutesCombined,
      'avgMinutes': avgMinutes,
    };
  }

  Future<void> _clearCache() async {
    print('Clearing all cached data');
    _cache.clear();
    setState(() {
      _loginData = null;
      _journeyData = null;
    });
  }

  Widget _buildPeriodSelector() {
    return CreamGradientCard(
      borderWidth: 1.5,
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today,
                  color: Theme.of(context).primaryColor, size: 14),
              const SizedBox(width: 4),
              const Text(
                'Select Period',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodChip('Today', 'today'),
                const SizedBox(width: 6),
                _buildPeriodChip('This Week', 'week'),
                const SizedBox(width: 6),
                _buildPeriodChip('This Month', 'month'),
                const SizedBox(width: 6),
                FilterChip(
                  selected: _isCustomDate,
                  label: Text(
                    _isCustomDate && _startDate != null && _endDate != null
                        ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}'
                        : 'Custom Range',
                    style: TextStyle(
                      color: _isCustomDate ? Colors.white : Colors.black87,
                      fontSize: 11,
                    ),
                  ),
                  selectedColor: Theme.of(context).primaryColor,
                  backgroundColor: Colors.grey.shade200,
                  onSelected: (bool selected) {
                    if (selected) {
                      _selectDateRange(context);
                    } else {
                      setState(() {
                        _isCustomDate = false;
                        _startDate = null;
                        _endDate = null;
                      });
                      _loadStats();
                    }
                  },
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value && !_isCustomDate;
    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 11,
        ),
      ),
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: Colors.grey.shade200,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedPeriod = value;
            _isCustomDate = false;
            _startDate = null;
            _endDate = null;
          });
          _loadStats();
        }
      },
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatsCards() {
    final stats = _getFilteredStats();

    return Column(
      children: [
        _buildStatCard(
          'Session Duration',
          stats['formattedDuration'],
          '${stats['sessionCount']} sessions',
          Icons.access_time,
          Colors.blue,
        ),
        _buildStatCard(
          'Average Session',
          stats['averageSessionDuration'],
          'per session',
          Icons.timer,
          Colors.green,
        ),
        _buildStatCard(
          'Shift Hours',
          '9:00 - 18:00',
          'Nairobi timezone',
          Icons.schedule,
          Colors.indigo,
        ),
        _buildStatCard(
          'Journey Plans',
          '${stats['totalPlans']}',
          '${stats['completedVisits']} completed',
          Icons.map,
          Colors.purple,
        ),
        _buildStatCard(
          'Completion Rate',
          stats['completionRate'],
          '${stats['pendingVisits']} pending, ${stats['missedVisits']} missed',
          Icons.check_circle,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          value,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'My Statistics',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _clearCache();
              await _loadStats();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
