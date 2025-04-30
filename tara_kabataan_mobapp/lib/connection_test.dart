import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'api_service.dart';

class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  bool isLoading = false;
  List<Map<String, dynamic>> testResults = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> runConnectionTests() async {
    setState(() {
      isLoading = true;
      testResults = [];
    });

    // Get platform info
    final platform = kIsWeb 
        ? 'Web (Browser)' 
        : Platform.isAndroid 
            ? 'Android' 
            : Platform.isIOS 
                ? 'iOS' 
                : 'Other';
    
    addResult('Platform', platform);
    addResult('API Base URL', ApiService.baseUrl);

    // Use the ApiService test functionality
    try {
      final results = await ApiService.testConnectivity();

      // Process internet test
      if (results.containsKey('internet')) {
        final internetTest = results['internet'];
        addResult(
          'Internet Connectivity', 
          internetTest['success'] ? 'Success' : 'Failed',
          isSuccess: internetTest['success'],
          details: internetTest['success'] 
              ? 'Status code: ${internetTest['status']}' 
              : internetTest['error'],
        );
      }

      // Process base URL test
      if (results.containsKey('baseUrl')) {
        final baseUrlTest = results['baseUrl'];
        addResult(
          'Server Connection', 
          baseUrlTest['success'] ? 'Success' : 'Failed',
          isSuccess: baseUrlTest['success'],
          details: baseUrlTest['success'] 
              ? 'Status code: ${baseUrlTest['status']}' 
              : baseUrlTest['error'],
        );
      }

      // Process API endpoint test
      if (results.containsKey('apiEndpoint')) {
        final apiTest = results['apiEndpoint'];
        addResult(
          'API Endpoint', 
          apiTest['success'] ? 'Success' : 'Failed',
          isSuccess: apiTest['success'],
          details: apiTest['success'] 
              ? 'Status code: ${apiTest['status']}${apiTest.containsKey('validJson') ? ', Valid JSON: ${apiTest['validJson']}' : ''}' 
              : apiTest['error'],
        );

        // Add JSON preview if available
        if (apiTest['success'] == true && apiTest['validJson'] == true && apiTest.containsKey('responsePreview')) {
          addResult(
            'API Response Preview', 
            'Valid',
            isSuccess: true,
            details: apiTest['responsePreview'],
          );
        }
      }
    } catch (e) {
      addResult('Test Error', 'Failed', isSuccess: false, details: e.toString());
    }

    // For Android, run additional tests
    if (!kIsWeb && Platform.isAndroid) {
      await testAndroidSpecific();
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> testAndroidSpecific() async {
    try {
      // Test direct IP connectivity
      await testEndpoint(
        'Localhost via 127.0.0.1', 
        'http://127.0.0.1', 
        expectJson: false,
      );
      
      // Test Android emulator special IP
      await testEndpoint(
        'Host via 10.0.2.2', 
        'http://10.0.2.2', 
        expectJson: false,
      );
      
      // Test alternative ports
      await testEndpoint(
        'Host via port 8080', 
        'http://10.0.2.2:8080', 
        expectJson: false,
      );
      
      // Get Android device info
      final androidVersion = await _getAndroidVersion();
      addResult('Android Version', androidVersion);
      
      // Network configuration
      addResult(
        'Network Config', 
        'See details',
        details: 'The Android emulator uses 10.0.2.2 to access the host machine (your computer). Make sure your XAMPP is configured to accept connections from all interfaces, not just localhost.',
      );
    } catch (e) {
      addResult('Android Tests Error', 'Failed', isSuccess: false, details: e.toString());
    }
  }

  Future<String> _getAndroidVersion() async {
    try {
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> testEndpoint(String name, String url, {bool expectJson = true}) async {
    try {
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      
      // Check for successful response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (expectJson) {
          try {
            // The value is not used, but we're keeping the parsing to check if it's valid JSON
            jsonDecode(response.body);
            addResult(name, 'Success (${response.statusCode})', isSuccess: true, details: 'Valid JSON response received');
          } catch (e) {
            addResult(name, 'Partial Success (${response.statusCode})', 
                isSuccess: false, 
                details: 'Response received but not valid JSON: ${e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length)}');
          }
        } else {
          addResult(name, 'Success (${response.statusCode})', isSuccess: true);
        }
      } else {
        addResult(name, 'Failed (${response.statusCode})', 
            isSuccess: false, 
            details: 'Server responded with error code');
      }
    } catch (e) {
      addResult(name, 'Error', isSuccess: false, details: e.toString().substring(0, e.toString().length > 100 ? 100 : e.toString().length));
    }
  }

  void addResult(String name, String result, {bool isSuccess = true, String? details}) {
    setState(() {
      testResults.add({
        'name': name,
        'result': result,
        'success': isSuccess,
        'details': details,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Test'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Diagnostics',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Troubleshoot connectivity issues between your app and the backend server.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : runConnectionTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A3FF),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.network_check),
                  const SizedBox(width: 8),
                  Text(isLoading ? 'Testing...' : 'Run Connection Tests'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : testResults.isEmpty
                      ? const Center(
                          child: Text(
                            'Press the button to run tests',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: testResults.length,
                            itemBuilder: (context, index) {
                              final test = testResults[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (test['name'] != 'Platform' && 
                                              test['name'] != 'API Base URL' &&
                                              test['name'] != 'Android Version' &&
                                              test['name'] != 'Network Config') 
                                            Icon(
                                              test['success'] 
                                                  ? Icons.check_circle 
                                                  : Icons.error,
                                              color: test['success'] 
                                                  ? Colors.green 
                                                  : Colors.red,
                                            )
                                          else
                                            const Icon(Icons.info, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              test['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Result: ${test['result']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      if (test['details'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Details: ${test['details']}',
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Test Help'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('This diagnostic tool helps identify connection issues between your app and backend server.'),
              SizedBox(height: 16),
              Text('Android Emulator Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• The Android emulator uses 10.0.2.2 to access localhost on your computer'),
              Text('• Make sure XAMPP is running and accessible on your computer'),
              Text('• Check that your Android app has internet permissions'),
              Text('• Verify your AndroidManifest.xml allows cleartext traffic'),
              SizedBox(height: 16),
              Text('Web Browser Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Web browsers access localhost directly'),
              Text('• Check browser console for CORS errors'),
              Text('• Verify your PHP API has proper CORS headers'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}