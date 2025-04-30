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
        return decoded;
      } catch (e) {
        return _handleError(method, endpoint, 'Invalid JSON response: $e');
      }
    } else {
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
      
      return _handleResponse(response, 'POST', endpoint);
    } catch (e) {
      return _handleError('POST', endpoint, e);
    }
  }
  
  // Update blog
  static Future<Map<String, dynamic>> updateBlog(Map<String, dynamic> blogData) async {
    final endpoint = '/update_blogs.php';
    _log('POST $endpoint with data: $blogData');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(blogData),
      ).timeout(const Duration(seconds: 15));
      
      return _handleResponse(response, 'POST', endpoint);
    } catch (e) {
      return _handleError('POST', endpoint, e);
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
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response, 'POST', endpoint);
    } catch (e) {
      return _handleError('POST', endpoint, e);
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