import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class DatabaseTestPage extends StatefulWidget {
  const DatabaseTestPage({Key? key}) : super(key: key);

  @override
  State<DatabaseTestPage> createState() => _DatabaseTestPageState();
}

class _DatabaseTestPageState extends State<DatabaseTestPage> {
  bool _isLoading = false;
  String _testResult = '';
  Map<String, dynamic>? _connectionTest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Connection Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Database Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Host: 102.218.215.35'),
                    const Text('Port: 3306'),
                    const Text('Database: citlogis_ws'),
                    const Text('User: citlogis_bryan'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Testing Connection...'),
                      ],
                    )
                  : const Text('Test Database Connection'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testHealthCheck,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Test Health Check'),
            ),
            const SizedBox(height: 16),
            if (_connectionTest != null) ...[
              Card(
                color: _connectionTest!['success'] == true
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connection Test Result',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _connectionTest!['success'] == true
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_connectionTest!['message']),
                      if (_connectionTest!['response_time_ms'] != null)
                        Text(
                          'Response Time: ${_connectionTest!['response_time_ms']}ms',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_testResult.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_testResult),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = '';
      _connectionTest = null;
    });

    try {
      final result = await DatabaseService.instance.testConnection();
      setState(() {
        _connectionTest = result;
        _testResult = result['success'] == true
            ? '✅ Connection test successful!'
            : '❌ Connection test failed: ${result['message']}';
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Error during connection test: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testHealthCheck() async {
    setState(() {
      _isLoading = true;
      _testResult = '';
    });

    try {
      final isHealthy = await DatabaseService.instance.isHealthy();
      setState(() {
        _testResult = isHealthy
            ? '✅ Health check passed! Database is responding correctly.'
            : '❌ Health check failed! Database is not responding.';
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Error during health check: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
