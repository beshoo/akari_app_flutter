import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/environment.dart';
import 'secure_storage.dart';

class ApiService {
  static late Dio dio;
  static bool _initialized = false;
  
  static void initialize() {
    if (_initialized) return;
    
    dio = Dio();
    
    // Configure base options
    dio.options = BaseOptions(
      baseUrl: Environment.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(milliseconds: 30000),
      receiveTimeout: const Duration(milliseconds: 30000),
      sendTimeout: const Duration(milliseconds: 30000),
    );
    
    // Add interceptors
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add authorization token if available
        final token = await SecureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        // Add random parameter (100000-999999)
        final rand = Random().nextInt(900000) + 100000;
        options.queryParameters['rand'] = rand.toString();
        
        // Log request in debug mode
        if (kDebugMode) {
          print('🚀 REQUEST: ${options.method} ${options.uri}');
          print('📤 Headers: ${options.headers}');
          if (options.data != null) {
            print('📦 Payload: ${options.data}');
          }
        }
        
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Log response in debug mode
        if (kDebugMode) {
          print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
          print('📨 Data: ${response.data}');
        }
        
        handler.next(response);
      },
      onError: (error, handler) async {
        // Log error in debug mode
        if (kDebugMode) {
          print('❌ ERROR: ${error.response?.statusCode} ${error.requestOptions.uri}');
          print('💥 Error: ${error.message}');
          print('📝 Response: ${error.response?.data}');
        }
        
        // Handle 401 Unauthorized
        if (error.response?.statusCode == 401) {
          await SecureStorage.deleteToken();
          // Here you might want to navigate to login page
          // This would require a navigation service or global navigation key
        }
        
        // Handle 500 Internal Server Error
        if (error.response?.statusCode == 500) {
          await _sendErrorReport(error);
        }
        
        handler.next(error);
      },
    ));
    
    _initialized = true;
  }
  
  // Send error report for 500 errors
  static Future<void> _sendErrorReport(DioException error) async {
    try {
      if (kDebugMode) {
        print('📊 Sending error report for 500 error');
      }
      
      final errorData = {
        'timestamp': DateTime.now().toIso8601String(),
        'url': error.requestOptions.uri.toString(),
        'method': error.requestOptions.method,
        'status_code': error.response?.statusCode,
        'error_message': error.message,
        'response_data': error.response?.data,
        'request_data': error.requestOptions.data,
        'platform': defaultTargetPlatform.toString(),
      };
      
      // You can implement your error reporting service here
      // For example, send to Firebase Crashlytics, Sentry, etc.
      if (kDebugMode) {
        print('📈 Error report data: $errorData');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to send error report: $e');
      }
    }
  }
  
  // Helper method to check if ApiService is initialized
  static bool get isInitialized => _initialized;
  
  // Helper method to get Dio instance
  static Dio get instance {
    if (!_initialized) {
      throw Exception('ApiService not initialized. Call ApiService.initialize() first.');
    }
    return dio;
  }
} 