import 'dart:io';
import 'dart:math';
import 'package:akari_app/pages/network_error_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../config/environment.dart';
import 'secure_storage.dart';

class ApiService {
  static late Dio dio;
  static bool _initialized = false;
  static bool _isErrorPageShown = false;
  
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

        // --- Network Error Handling ---
        final isNetworkError = error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.unknown ||
            error.error is SocketException;

        if (isNetworkError) {
          if (_isErrorPageShown) {
            // If an error page is already shown, we prevent showing another one
            // and just pass the error to the next handler.
            return handler.next(error);
          }
          _isErrorPageShown = true;

          final response = await Get.to<Response?>(
            () => NetworkErrorPage(
              onRetry: () async {
                try {
                  // Re-attempt the failed request with a 10-second timeout
                  final newResponse = await dio.fetch(
                    error.requestOptions.copyWith(
                      sendTimeout: const Duration(seconds: 10),
                      receiveTimeout: const Duration(seconds: 10),
                      connectTimeout: const Duration(seconds: 10),
                    ),
                  );
                  // If successful, pop the error page and return the response
                  Get.back(result: newResponse);
                } catch (e) {
                  // If retry fails, print the error and stay on the error page
                  if (kDebugMode) {
                    print('--- RETRY FAILED ---');
                    print(e);
                  }
                }
              },
            ),
            preventDuplicates: true,
          );

          _isErrorPageShown = false;

          if (response != null) {
            // If retry was successful and a response was returned,
            // resolve the original request with the new response.
            return handler.resolve(response);
          } else {
            // If the error page was dismissed without a successful retry,
            // pass the original error to the next handler.
            return handler.next(error);
          }
        }
        // --- End of Network Error Handling ---

        // Handle Unauthenticated
        if (error.response?.data is Map<String, dynamic>) {
          final data = error.response!.data as Map<String, dynamic>;
          if (data['message'] == 'Unauthenticated') {
            await SecureStorage.deleteToken();
            Get.offAllNamed('/login');
            // We return the error to prevent other interceptors from processing it
            return handler.next(error);
          }
        }
        
        // Handle 401 Unauthorized (fallback)
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