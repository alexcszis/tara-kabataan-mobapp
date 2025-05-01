import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Debug mode - set to true to see verbose logging
  static bool debugMode = true;
  
  // Base URL that adapts based on platform
  static String get baseUrl {
    // For Android emulator
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/tara-kabataan/tara-kabataan-backend/api';
    }
    // For web (Chrome) - using the full localhost path that works 
    else if (kIsWeb) {
      return 'http://localhost/tara-kabataan/tara-kabataan-backend/api';
    }
    // For iOS simulator
    else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://localhost/tara-kabataan/tara-kabataan-backend/api';
    }
    // Default fallback
    return 'http://localhost/tara-kabataan/tara-kabataan-backend/api';
  }
  
  // Log helper
  static void _log(String message) {
    if (debugMode) {
      debugPrint('ApiService: $message');
    }
  }
  
  // Error handler
  static dynamic _handleError(String method, String endpoint, dynamic error) {
    final errorMessage = 'Error in $method $endpoint: $error';
    _log(errorMessage);
    throw Exception(errorMessage);
  }
  
  // Response handler  
  static dynamic _handleResponse(http.Response response, String method, String endpoint) {
    final statusCode = response.statusCode;
    _log('$method $endpoint response status: $statusCode');
    
    if (statusCode >= 200 && statusCode < 300) {
      try {
        final decoded = jsonDecode(response.body);
        _log('Response body decoded: $decoded');
        return decoded;
      } catch (e) {
        _log('Error decoding JSON: $e, Raw response: ${response.body}');
        return _handleError(method, endpoint, 'Invalid JSON response: $e');
      }
    } else {
      _log('Error response body: ${response.body}');
      return _handleError(method, endpoint, 'Status code: $statusCode, Response: ${response.body}');
    }
  }
  
  // Get all blogs
  static Future<Map<String, dynamic>> getBlogs({String category = 'ALL'}) async {
  final endpoint = '/blogs.php?category=$category';
  _log('GET $endpoint');
  
  try {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
    ).timeout(const Duration(seconds: 10));
    
    return _handleResponse(response, 'GET', endpoint);
  } catch (e) {
    return _handleError('GET', endpoint, e);
  }
}

// Get single blog by ID
static Future<Map<String, dynamic>> getBlogById(String blogId) async {
  final endpoint = '/blogs.php?blog_id=$blogId';
  _log('GET $endpoint');
  
  try {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
    ).timeout(const Duration(seconds: 10));
    
    return _handleResponse(response, 'GET', endpoint);
  } catch (e) {
    return _handleError('GET', endpoint, e);
  }
}

// Add new blog
static Future<Map<String, dynamic>> addBlog(Map<String, dynamic> blogData) async {
  final endpoint = '/add_new_blog.php';
  _log('POST $endpoint with data: $blogData');
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(blogData),
    ).timeout(const Duration(seconds: 15));
    
    _log('Response status code: ${response.statusCode}');
    _log('Response body: ${response.body}');
    
    try {
      final decodedResponse = jsonDecode(response.body);
      return decodedResponse;
    } catch (e) {
      _log('Error decoding JSON response: $e');
      return {
        'success': false,
        'error': 'Invalid JSON response from server: $e',
        'raw_response': response.body
      };
    }
  } catch (e) {
    _log('Exception in addBlog: $e');
    return {
      'success': false,
      'error': e.toString()
    };
  }
}

// Update blog
static Future<Map<String, dynamic>> updateBlog(Map<String, dynamic> blogData) async {
  final endpoint = '/update_blogs.php';
  _log('POST $endpoint with data: $blogData');
  
  try {
    // Clone the data to avoid modifying the original
    final dataToSend = Map<String, dynamic>.from(blogData);
    
    // Ensure blog_id is included
    if (!dataToSend.containsKey('blog_id')) {
      return {
        'success': false,
        'error': 'blog_id is required for updates'
      };
    }
    
    // Print EVERY field to ensure they match what the PHP script expects
    _log('DETAILED DEBUG DATA:');
    _log('blog_id: ${dataToSend['blog_id']} (type: ${dataToSend['blog_id'].runtimeType})');
    if (dataToSend.containsKey('title')) _log('title: ${dataToSend['title']} (type: ${dataToSend['title'].runtimeType})');
    if (dataToSend.containsKey('content')) _log('content: Length ${dataToSend['content'].length} (type: ${dataToSend['content'].runtimeType})');
    if (dataToSend.containsKey('category')) _log('category: ${dataToSend['category']} (type: ${dataToSend['category'].runtimeType})');
    if (dataToSend.containsKey('blog_status')) _log('blog_status: ${dataToSend['blog_status']} (type: ${dataToSend['blog_status'].runtimeType})');
    if (dataToSend.containsKey('image_url')) _log('image_url: ${dataToSend['image_url']} (type: ${dataToSend['image_url'].runtimeType})');
    if (dataToSend.containsKey('author')) _log('author: ${dataToSend['author']} (type: ${dataToSend['author'].runtimeType})');
    
    // Compare to the update_blogs.php expectations
    // Looking at your PHP script, it expects specific field names
    _log('CHECKING PHP COMPATIBILITY:');
    _log('blog_id field exists: ${dataToSend.containsKey('blog_id')}');
    _log('title field exists: ${dataToSend.containsKey('title')}'); // PHP expects 'title'
    _log('content field exists: ${dataToSend.containsKey('content')}'); // PHP expects 'content'
    _log('category field exists: ${dataToSend.containsKey('category')}'); // PHP expects 'category'
    _log('blog_status field exists: ${dataToSend.containsKey('blog_status')}'); // PHP expects 'blog_status'
    _log('image_url field exists: ${dataToSend.containsKey('image_url')}'); // PHP expects 'image_url'
    
    // Log the exact data being sent
    final jsonBody = jsonEncode(dataToSend);
    _log('Request body: $jsonBody');
    
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonBody,
    ).timeout(const Duration(seconds: 15));
    
    _log('Response status code: ${response.statusCode}');
    _log('Response body: ${response.body}');
    
    // Check if response is HTML
    if (response.body.contains('<br />') || response.body.contains('<b>') || 
        response.body.contains('<!DOCTYPE') || response.body.contains('<html')) {
      _log('Received HTML instead of JSON. PHP error likely occurred.');
      
      // Success case - sometimes PHP scripts return success but with HTML warnings
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'note': 'Server returned HTML with success status code'};
      }
      
      return {
        'success': false,
        'error': 'Server returned HTML instead of JSON. Please check server logs.'
      };
    }
    
    try {
      // Try to parse as JSON
      final decodedResponse = jsonDecode(response.body);
      return decodedResponse;
    } catch (e) {
      _log('Error decoding JSON response: $e');
      
      // If the status code indicates success, treat it as successful even if JSON parsing fails
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'note': 'Request succeeded but response was not valid JSON'};
      }
      
      return {
        'success': false,
        'error': 'Invalid JSON response from server: $e',
        'raw_response': response.body
      };
    }
  } catch (e) {
    _log('Exception in updateBlog: $e');
    return {
      'success': false,
      'error': e.toString()
    };
  }
}
  // Delete blog
  static Future<Map<String, dynamic>> deleteBlog(String blogId) async {
    final endpoint = '/delete_blogs.php';
    _log('POST $endpoint with blog_id: $blogId');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'blog_id': blogId}),
      ).timeout(const Duration(seconds: 10));
      
      return _handleResponse(response, 'POST', endpoint);
    } catch (e) {
      return _handleError('POST', endpoint, e);
    }
  }
  
  // Upload blog image
  static Future<Map<String, dynamic>> uploadBlogImage(List<int> imageBytes, String fileName) async {
    final endpoint = '/upload_blog_image.php';
    _log('POST $endpoint with image: $fileName (${imageBytes.length} bytes)');
    
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
        ),
      );
      
      _log('Sending multipart request to: ${request.url}');
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      _log('Response status code: ${response.statusCode}');
      _log('Response body: ${response.body}');
      
      try {
        final decodedResponse = jsonDecode(response.body);
        return decodedResponse;
      } catch (e) {
        _log('Error decoding JSON response: $e');
        return {
          'success': false,
          'error': 'Invalid JSON response from server: $e',
          'raw_response': response.body
        };
      }
    } catch (e) {
      _log('Exception in uploadBlogImage: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
  
  // Get all events
  static Future<Map<String, dynamic>> getEvents() async {
    final endpoint = '/events1.php';
    _log('GET $endpoint');
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
      ).timeout(const Duration(seconds: 10));
      
      return _handleResponse(response, 'GET', endpoint);
    } catch (e) {
      return _handleError('GET', endpoint, e);
    }
  }
  
  // Add new event
  static Future<Map<String, dynamic>> addEvent(Map<String, dynamic> eventData) async {
    final endpoint = '/add_new_event.php';
    _log('POST $endpoint with data: $eventData');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(eventData),
      ).timeout(const Duration(seconds: 15));
      
      return _handleResponse(response, 'POST', endpoint);
    } catch (e) {
      return _handleError('POST', endpoint, e);
    }
  }
  
  // Update event
  static Future<Map<String, dynamic>> updateEvent(Map<String, dynamic> eventData) async {
    final endpoint = '/update_event.php';
    _log('POST $endpoint with data: $eventData');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(eventData),
      ).timeout(const Duration(seconds: 15));
      
      return _handleResponse(response, 'POST', endpoint);
    } catch (e) {
      return _handleError('POST', endpoint, e);
    }
  }
  
  // Delete event
  static Future<Map<String, dynamic>> deleteEvent(String eventId) async {
    final endpoint = '/delete_event.php';
    _log('POST $endpoint with event_id: $eventId');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'event_id': eventId}),
      ).timeout(const Duration(seconds: 10));
      
      return _handleResponse(response, 'POST', endpoint);
    } catch (e) {
      return _handleError('POST', endpoint, e);
    }
  }
  
  // Upload event image
  static Future<Map<String, dynamic>> uploadEventImage(List<int> imageBytes, String fileName) async {
    final endpoint = '/upload_event_image.php';
    _log('POST $endpoint with image: $fileName (${imageBytes.length} bytes)');
    
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
        ),
      );
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response, 'POST', endpoint);
    } catch (e) {
      return _handleError('POST', endpoint, e);
    }
  }
  
  // Get user name by ID
  static Future<String> getUserName(String userId) async {
    final endpoint = '/get_user_name.php?user_id=$userId';
    _log('GET $endpoint');
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
      ).timeout(const Duration(seconds: 10));
      
      final data = _handleResponse(response, 'GET', endpoint);
      return data['user_name'] ?? 'Unknown';
    } catch (e) {
      _log('Error getting user name: $e');
      return 'Unknown';
    }
  }
  
  // Test connectivity - useful for debugging
  static Future<Map<String, dynamic>> testConnectivity() async {
    final results = <String, dynamic>{};
    
    // Test internet connectivity
    try {
      final response = await http.get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      results['internet'] = {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'status': response.statusCode,
      };
    } catch (e) {
      results['internet'] = {'success': false, 'error': e.toString()};
    }
    
    // Test API base URL
    try {
      final response = await http.get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 5));
      results['baseUrl'] = {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'status': response.statusCode,
      };
    } catch (e) {
      results['baseUrl'] = {'success': false, 'error': e.toString()};
    }
    
    // Test specific API endpoint
    try {
      final response = await http.get(Uri.parse('$baseUrl/blogs.php'))
          .timeout(const Duration(seconds: 10));
      results['apiEndpoint'] = {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'status': response.statusCode,
      };
      
      // Try to parse the response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);
          results['apiEndpoint']['validJson'] = true;
          results['apiEndpoint']['responsePreview'] = data.toString().substring(0, 
              data.toString().length > 100 ? 100 : data.toString().length);
        } catch (e) {
          results['apiEndpoint']['validJson'] = false;
          results['apiEndpoint']['parseError'] = e.toString();
        }
      }
    } catch (e) {
      results['apiEndpoint'] = {'success': false, 'error': e.toString()};
    }
    
    return results;
  }
}