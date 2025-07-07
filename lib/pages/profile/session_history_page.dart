import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:woosh/models/user_session/session_model.dart';
import 'package:woosh/services/core/session_service.dart';
import 'package:woosh/utils/app_theme.dart' hide CreamGradientCard;
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/gradient_widgets.dart';
import 'package:woosh/widgets/cream_gradient_card.dart';
import 'package:intl/intl.dart';

class SessionHistoryPage extends StatefulWidget {
  const SessionHistoryPage({super.key});

  @override
  State<SessionHistoryPage> createState() => _SessionHistoryPageState();
}

class _SessionHistoryPageState extends State<SessionHistoryPage> {
  List<Session> _sessions = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCustomDate = false;
  String _selectedPeriod = 'week';
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  final _cache = <String, List<Session>>{};

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

  void _loadUserId() {
    final userData = GetStorage().read('salesRep');
    if (userData != null && userData['id'] != null) {
      setState(() => _userId = userData['id'].toString());
      _loadSessions();
    } else {
      setState(() => _error = 'User ID not found');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreSessions();
    }
  }

  Future<void> _precacheData() async {
    if (_userId == null) return;

    final periods = ['today', 'week', 'month'];
    for (final period in periods) {
      if (period != _selectedPeriod) {
        final dateRange = _getDateRangeForPeriod(period);
        final cacheKey = '${_userId}_${dateRange['start']}_${dateRange['end']}';
        if (!_cache.containsKey(cacheKey)) {
          await _fetchAndCacheData(
              dateRange['start']!, dateRange['end']!, cacheKey);
        }
      }
    }
  }

  Future<void> _fetchAndCacheData(
      String startDate, String endDate, String cacheKey) async {
    try {
      final response = await SessionService.getSessionHistory(
        _userId!,
        startDate: startDate,
        endDate: endDate,
      );

      if (response['sessions'] != null) {
        _cache[cacheKey] = (response['sessions'] as List)
            .map((session) => Session.fromJson(session))
            .toList();
      }
    } catch (e) {
      print('Error precaching data: $e');
    }
  }

  List<Session> _filterSessionsByDate(
      List<Session> sessions, DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) return sessions;

    return sessions.where((session) {
      final sessionDate = session.loginAt;
      return sessionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          sessionDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> _loadSessions() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Fetching sessions for user ID: $_userId');
      final response = await SessionService.getSessionHistory(_userId!);

      // Print the raw response
      print('Raw API Response:');
      print(response);
      print('Total sessions in response: ${response['totalSessions']}');
      print('Sessions array length: ${response['sessions']?.length ?? 0}');

      if (response['sessions'] != null) {
        final allSessions = (response['sessions'] as List)
            .map((session) => Session.fromJson(session))
            .toList();

        print('Parsed sessions: ${allSessions.length}');

        // Filter sessions based on selected date range
        final filteredSessions = _filterSessionsByDate(
          allSessions,
          _isCustomDate ? _startDate : _getStartDateForPeriod(_selectedPeriod),
          _isCustomDate ? _endDate : DateTime.now(),
        );

        print('Filtered sessions: ${filteredSessions.length}');

        setState(() {
          _sessions = filteredSessions;
          _isLoading = false;
        });
      } else {
        print('No sessions data in response');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading sessions: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreSessions() async {
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
      _loadSessions();
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

  DateTime? _getStartDateForPeriod(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'today':
        return now;
      case 'week':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'month':
        return DateTime(now.year, now.month, 1);
      default:
        return null;
    }
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
          _loadSessions();
        }
      },
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildSessionCard(Session session) {
    // Format the session start time
    final startDateTime = session.sessionStart ?? session.loginAt;
    final formattedStartTime =
        '${DateFormat('yyyy/MM/dd').format(startDateTime)} ${DateFormat('hh:mm a').format(startDateTime)}';

    // Format the session end time and calculate duration
    String? formattedEndTime;
    String formattedDuration = 'N/A';

    if (session.sessionEnd != null) {
      final endDateTime = session.sessionEnd!;
      formattedEndTime = DateFormat('hh:mm a').format(endDateTime);

      // Calculate duration from start and end times
      final duration = endDateTime.difference(startDateTime);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      formattedDuration = '${hours}h ${minutes}m';
    }

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
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _getTimingStatusColor(session).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                session.isEarly ?? false 
                    ? Icons.trending_up 
                    : session.isLate 
                        ? Icons.warning 
                        : Icons.check_circle,
                color: _getTimingStatusColor(session),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        formattedStartTime,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusColor(session).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          session.isActive
                              ? 'Active'
                              : session.isComplete
                                  ? 'Complete'
                                  : 'Inactive',
                          style: TextStyle(
                            color: _getStatusColor(session),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              _getTimingStatusColor(session).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          session.timingStatus,
                          style: TextStyle(
                            color: _getTimingStatusColor(session),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              formattedDuration,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (formattedEndTime != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule,
                                  size: 12, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                formattedEndTime,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(Session session) {
    if (session.isActive) {
      return Colors.orange; // Active (ongoing)
    } else if (session.isComplete) {
      return Colors.green; // Complete (finished)
    } else {
      return Colors.grey; // Inactive
    }
  }

  Color _getTimingStatusColor(Session session) {
    if (session.isEarly ?? false) {
      return Colors.blue; // Early
    } else if (session.isLate) {
      return Colors.red; // Late
    } else {
      return Colors.green; // On Time
    }
  }

  Widget _buildDateFilter() {
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
                      _loadSessions();
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No sessions found for the selected period',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(6.0),
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            height: 70,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Session History',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      GoldGradientButton(
                        onPressed: _loadSessions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSessions,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateFilter(),
                        const SizedBox(height: 12),
                        if (_sessions.isEmpty)
                          _buildEmptyState()
                        else
                          ..._sessions.map(_buildSessionCard),
                        if (_isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
