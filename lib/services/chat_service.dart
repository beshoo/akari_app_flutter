import 'dart:convert';
import 'package:dio/dio.dart';
import '../utils/logger.dart';
import '../services/secure_storage.dart';
import '../config/environment.dart';

class ChatService {
  static final Dio _dio = Dio();
  static const int timeoutDuration = 120000; // 120 seconds

  static Future<String?> sendMessage(String message) async {
    final startTime = DateTime.now();
    try {
      Logger.log('ChatService: Sending message - $message');
      Logger.log('ChatService: API call started at: $startTime');
      
      // Get auth token
      final authToken = await SecureStorage.getToken();
      if (authToken == null) {
        Logger.log('ChatService: No auth token found');
        return 'يرجى تسجيل الدخول أولاً.';
      }
      
      final response = await _dio.post(
        '${Environment.baseUrl}/chat',
        data: {
          'message': message,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          receiveTimeout: const Duration(milliseconds: timeoutDuration),
          sendTimeout: const Duration(milliseconds: timeoutDuration),
        ),
      );

      if (response.statusCode == 200) {
        // Extract response text from the API response format
        String responseText = _extractResponseText(response.data);
        
        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);
        Logger.log('ChatService: Received response after ${duration.inSeconds} seconds');
        Logger.log('ChatService: Received response - $responseText');
        return responseText;
      } else {
        Logger.log('ChatService: API error - ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      Logger.log('ChatService: Dio error after ${duration.inSeconds} seconds - ${e.message}');
      Logger.log('ChatService: Dio error type - ${e.type}');
      if (e.type == DioExceptionType.receiveTimeout || 
          e.type == DioExceptionType.sendTimeout || 
          e.type == DioExceptionType.connectionTimeout) {
        Logger.log('ChatService: Timeout error occurred after ${timeoutDuration}ms');
      }
      return _getErrorMessage(e);
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      Logger.log('ChatService: Unexpected error after ${duration.inSeconds} seconds - $e');
      return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
    }
  }

  static Future<bool> deleteThreads() async {
    try {
      Logger.log('ChatService: Deleting chat threads');
      
      // Get auth token
      final authToken = await SecureStorage.getToken();
      if (authToken == null) {
        Logger.log('ChatService: No auth token found for delete threads');
        return false;
      }
      
      final response = await _dio.delete(
        '${Environment.baseUrl}/chat/threads',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          receiveTimeout: const Duration(milliseconds: timeoutDuration),
          sendTimeout: const Duration(milliseconds: timeoutDuration),
        ),
      );

      if (response.statusCode == 200) {
        Logger.log('ChatService: Threads deleted successfully');
        return true;
      } else {
        Logger.log('ChatService: Delete threads error - ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      Logger.log('ChatService: Delete threads Dio error - ${e.message}');
      return false;
    } catch (e) {
      Logger.log('ChatService: Delete threads unexpected error - $e');
      return false;
    }
  }

  static String _extractResponseText(dynamic responseData) {
    if (responseData is String) {
      return responseData;
    }
    
    if (responseData is Map<String, dynamic>) {
      // API returns {"response": "string"} - prioritize this format
      if (responseData.containsKey('response')) {
        return responseData['response'].toString();
      }
      
      // Fallback to other common response field names
      if (responseData.containsKey('message')) {
        return responseData['message'].toString();
      }
      if (responseData.containsKey('text')) {
        return responseData['text'].toString();
      }
      if (responseData.containsKey('data')) {
        return _extractResponseText(responseData['data']);
      }
      if (responseData.containsKey('result')) {
        return _extractResponseText(responseData['result']);
      }
      
      // If no known field, return the JSON as string
      return jsonEncode(responseData);
    }
    
    return responseData.toString();
  }

  static String _getErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاتصال. يرجى التحقق من الاتصال بالإنترنت والمحاولة مرة أخرى.';
      case DioExceptionType.connectionError:
        return 'فشل في الاتصال بالخادم. يرجى التحقق من الاتصال بالإنترنت.';
      case DioExceptionType.badResponse:
        return 'خطأ في الخادم. يرجى المحاولة مرة أخرى لاحقاً.';
      case DioExceptionType.cancel:
        return 'تم إلغاء الطلب.';
      default:
        return 'حدث خطأ في الشبكة. يرجى المحاولة مرة أخرى.';
    }
  }



  // Test API connectivity and authentication
  static Future<bool> testConnection() async {
    try {
      Logger.log('ChatService: Testing API connection');
      
      final authToken = await SecureStorage.getToken();
      if (authToken == null) {
        Logger.log('ChatService: No auth token found for connection test');
        return false;
      }
      
      final response = await _dio.post(
        '${Environment.baseUrl}/chat',
        data: {
          'message': 'test connection',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          receiveTimeout: const Duration(milliseconds: 60000), // 60 seconds timeout for test
          sendTimeout: const Duration(milliseconds: 60000),
        ),
      );

      final isConnected = response.statusCode == 200;
      Logger.log('ChatService: Connection test ${isConnected ? 'successful' : 'failed'} - Status: ${response.statusCode}');
      return isConnected;
    } on DioException catch (e) {
      Logger.log('ChatService: Connection test failed - ${e.message}');
      return false;
    } catch (e) {
      Logger.log('ChatService: Connection test unexpected error - $e');
      return false;
    }
  }

  // Get current authentication status
  static Future<bool> isAuthenticated() async {
    final token = await SecureStorage.getToken();
    return token != null && token.isNotEmpty;
  }
} 