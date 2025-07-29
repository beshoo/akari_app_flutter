import 'dart:io';
import 'dart:math';
import 'package:akari_app/pages/network_error_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../config/environment.dart';
import 'secure_storage.dart';
import 'package:akari_app/utils/logger.dart';
import '../data/models/notification_model.dart';

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
      connectTimeout: const Duration(milliseconds: 120000),
      receiveTimeout: const Duration(milliseconds: 120000),
      sendTimeout: const Duration(milliseconds: 120000),
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
        
        // Enhanced detailed logging for requests
        Logger.log('');
        Logger.log('🚀 ═══════════════════════════════════════════════════════════════');
        Logger.log('🚀 REQUEST: ${options.method.toUpperCase()} ${options.baseUrl}${options.path}');
        Logger.log('🚀 ═══════════════════════════════════════════════════════════════');
        
        // Log headers (excluding sensitive authorization)
        if (options.headers.isNotEmpty) {
          Logger.log('📤 HEADERS:');
          options.headers.forEach((key, value) {
            if (key.toLowerCase() == 'authorization') {
              Logger.log('   $key: Bearer ***TOKEN***');
            } else {
              Logger.log('   $key: $value');
            }
          });
        }
        
        // Log query parameters for GET requests
        if (options.queryParameters.isNotEmpty) {
          Logger.log('🔍 QUERY PARAMETERS:');
          options.queryParameters.forEach((key, value) {
            Logger.log('   $key: $value');
          });
        }
        
        // Log request body for POST/PUT/PATCH requests
        if (options.data != null) {
          Logger.log('📦 REQUEST BODY:');
          if (options.data is Map) {
            final data = options.data as Map;
            data.forEach((key, value) {
              // Hide sensitive fields
              if (key.toString().toLowerCase().contains('password') || 
                  key.toString().toLowerCase().contains('token')) {
                Logger.log('   $key: ***HIDDEN***');
              } else {
                Logger.log('   $key: $value');
              }
            });
          } else {
            Logger.log('   ${options.data}');
          }
        }
        
        Logger.log('🚀 ═══════════════════════════════════════════════════════════════');
        Logger.log('');
        
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Enhanced detailed logging for responses
        Logger.log('');
        Logger.log('✅ ═══════════════════════════════════════════════════════════════');
        Logger.log('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.method.toUpperCase()} ${response.requestOptions.uri}');
        Logger.log('✅ ═══════════════════════════════════════════════════════════════');
        
        // Log response headers
        if (response.headers.map.isNotEmpty) {
          Logger.log('📨 RESPONSE HEADERS:');
          response.headers.map.forEach((key, value) {
            Logger.log('   $key: ${value.join(', ')}');
          });
        }
        
        // Log response data
        if (response.data != null) {
          Logger.log('📨 RESPONSE DATA:');
          if (response.data is Map) {
            final data = response.data as Map;
            data.forEach((key, value) {
              // Format different types of values
              if (value is List && value.length > 3) {
                Logger.log('   $key: [${value.length} items] ${value.take(3).toList()}...');
              } else if (value is Map && value.length > 5) {
                final keys = value.keys.take(5).toList();
                Logger.log('   $key: {${value.length} fields} showing: $keys...');
              } else {
                Logger.log('   $key: $value');
              }
            });
          } else if (response.data is List) {
            final list = response.data as List;
            Logger.log('   Array with ${list.length} items');
            if (list.isNotEmpty) {
              Logger.log('   First item: ${list.first}');
            }
          } else {
            Logger.log('   ${response.data}');
          }
        }
        
        Logger.log('✅ ═══════════════════════════════════════════════════════════════');
        Logger.log('');
        
        handler.next(response);
      },
      onError: (error, handler) async {
        // Enhanced error logging
        Logger.log('');
        Logger.log('❌ ═══════════════════════════════════════════════════════════════');
        Logger.log('❌ ERROR: ${error.response?.statusCode ?? 'NO_STATUS'} ${error.requestOptions.method.toUpperCase()} ${error.requestOptions.uri}');
        Logger.log('❌ ═══════════════════════════════════════════════════════════════');
        Logger.log('❌ Error Type: ${error.type}');
        Logger.log('❌ Error Message: ${error.message}');
        
        if (error.response?.data != null) {
          Logger.log('❌ ERROR RESPONSE DATA:');
          if (error.response!.data is Map) {
            final data = error.response!.data as Map;
            data.forEach((key, value) {
              Logger.log('   $key: $value');
            });
          } else {
            Logger.log('   ${error.response!.data}');
          }
        }
        
        Logger.log('❌ ═══════════════════════════════════════════════════════════════');
        Logger.log('');

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
                  Logger.error('--- RETRY FAILED ---', e);
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
            // Navigate to login and clear all previous routes
            try {
              Get.offAllNamed('/login');
            } catch (e) {
              // Fallback: if named route fails, try to navigate to onboarding
              Logger.error('Failed to navigate to login, trying onboarding', e);
              Get.offAllNamed('/onboarding');
            }
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
      Logger.log('');
      Logger.log('📊 ═══════════════════════════════════════════════════════════════');
      Logger.log('📊 SENDING ERROR REPORT FOR 500 ERROR');
      Logger.log('📊 ═══════════════════════════════════════════════════════════════');
      
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
      
      Logger.log('📊 ERROR REPORT DATA:');
      errorData.forEach((key, value) {
        if (key == 'request_data' && value is Map) {
          Logger.log('   $key:');
          (value).forEach((reqKey, reqValue) {
            if (reqKey.toString().toLowerCase().contains('password') || 
                reqKey.toString().toLowerCase().contains('token')) {
              Logger.log('     $reqKey: ***HIDDEN***');
            } else {
              Logger.log('     $reqKey: $reqValue');
            }
          });
        } else {
          Logger.log('   $key: $value');
        }
      });
      
      // You can implement your error reporting service here
      // For example, send to Firebase Crashlytics, Sentry, etc.
      Logger.log('📊 ═══════════════════════════════════════════════════════════════');
      Logger.log('');
    } catch (e) {
      Logger.error('❌ Failed to send error report', e);
    }
  }
  
  // Fetch notification count
  static Future<int> getNotificationCount() async {
    try {
      final response = await dio.get('/notification/count');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        Logger.log('Notification count raw value: $data (type:  [36m [1m [4m [7m${data.runtimeType} [0m)');
        if (data is int) {
          return data;
        } else if (data is String) {
          return int.tryParse(data) ?? 0;
        } else if (data is Map && data['count'] != null) {
          final countValue = data['count'];
          if (countValue is int) return countValue;
          if (countValue is String) return int.tryParse(countValue) ?? 0;
        }
      }
      return 0;
    } catch (e) {
      Logger.log('Failed to fetch notification count: $e');
      return 0;
    }
  }

  // Delete all notifications
  static Future<bool> deleteAllNotifications() async {
    try {
      final response = await dio.delete('/notification/empty');
      if (response.statusCode == 200) {
        Logger.log('All notifications deleted successfully');
        return true;
      }
      Logger.error('Failed to delete all notifications: ${response.statusCode}');
      return false;
    } catch (e) {
      Logger.error('Failed to delete all notifications', e);
      return false;
    }
  }
  
  // Fetch notifications with pagination
  static Future<Map<String, dynamic>> fetchNotifications({int page = 1}) async {
    try {
      final response = await dio.get('/notification/list', queryParameters: {'page': page});
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final List<NotificationItem> notifications = (data['data'] as List<dynamic>?)?.map((item) => NotificationItem.fromJson(item)).toList() ?? [];
        final String? nextPageUrl = data['next_page_url'];
        return {
          'notifications': notifications,
          'nextPageUrl': nextPageUrl,
        };
      }
      return {'notifications': <NotificationItem>[], 'nextPageUrl': null};
    } catch (e) {
      Logger.error('Failed to fetch notifications', e);
      return {'notifications': <NotificationItem>[], 'nextPageUrl': null};
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