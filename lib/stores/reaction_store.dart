import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

class ReactionStore extends ChangeNotifier {
  // Loading states
  bool _addReactionLoading = false;
  bool _removeReactionLoading = false;
  
  // Error states
  String? _reactionError;
  
  // Getters
  bool get addReactionLoading => _addReactionLoading;
  bool get removeReactionLoading => _removeReactionLoading;
  String? get reactionError => _reactionError;
  
  // Add or update a reaction
  Future<Map<String, dynamic>> addReaction({
    required String type,
    required String postType,
    required int postId,
  }) async {
    try {
      Logger.log('🎯 ReactionStore: addReaction called with type=$type, postType=$postType, postId=$postId');
      
      _addReactionLoading = true;
      _reactionError = null;
      notifyListeners();
      
      final data = {
        'type': type,
        'post_type': postType,
        'post_id': postId,
      };
      
      Logger.log('📤 ReactionStore: Making API call with data: $data');
      
      final response = await ApiService.instance.post('/react', data: data);
      
      Logger.log('📥 ReactionStore: API response received');
      Logger.log('Reaction API Response: ${response.data}');
      
      // Check if response has the expected structure
      if (response.statusCode == 200 && response.data != null) {
        Logger.log('✅ ReactionStore: API call successful');
        // The API returns: { message, reaction, reaction_summary }
        return {
          'success': true,
          'message': response.data['message'] ?? 'تمت إضافة التفاعل بنجاح',
          'data': response.data, // Pass the entire response as data
        };
      } else {
        Logger.warn('❌ ReactionStore: API call failed with status ${response.statusCode}');
        _reactionError = response.data?['message'] ?? 'فشل في إضافة التفاعل';
        return {
          'success': false,
          'message': _reactionError,
        };
      }
    } on DioException catch (e) {
      Logger.error('❌ ReactionStore: DioException occurred', e);
      _reactionError = _handleDioError(e);
      return {
        'success': false,
        'message': _reactionError,
      };
    } catch (e, s) {
      Logger.error('❌ ReactionStore: General exception occurred', e, s);
      _reactionError = 'حدث خطأ غير متوقع';
      return {
        'success': false,
        'message': _reactionError,
      };
    } finally {
      _addReactionLoading = false;
      notifyListeners();
    }
  }
  
  // Remove a reaction
  Future<Map<String, dynamic>> removeReaction({
    required String postType,
    required int postId,
  }) async {
    try {
      Logger.log('🗑️ ReactionStore: removeReaction called with postType=$postType, postId=$postId');
      
      _removeReactionLoading = true;
      _reactionError = null;
      notifyListeners();
      
      final queryParams = {
        'post_type': postType,
        'post_id': postId,
      };
      
      Logger.log('📤 ReactionStore: Making DELETE API call with params: $queryParams');
      
      final response = await ApiService.instance.delete(
        '/react',
        queryParameters: queryParams,
      );
      
      Logger.log('📥 ReactionStore: DELETE API response received');
      Logger.log('Remove Reaction API Response: ${response.data}');
      
      // Check if response has the expected structure
      if (response.statusCode == 200 && response.data != null) {
        Logger.log('✅ ReactionStore: DELETE API call successful');
        // The API returns: { message, reaction_summary }
        return {
          'success': true,
          'message': response.data['message'] ?? 'تمت إزالة التفاعل بنجاح',
          'data': response.data, // Pass the entire response as data
        };
      } else {
        Logger.warn('❌ ReactionStore: DELETE API call failed with status ${response.statusCode}');
        _reactionError = response.data?['message'] ?? 'فشل في إزالة التفاعل';
        return {
          'success': false,
          'message': _reactionError,
        };
      }
    } on DioException catch (e) {
      Logger.error('❌ ReactionStore: DioException occurred in removeReaction', e);
      _reactionError = _handleDioError(e);
      return {
        'success': false,
        'message': _reactionError,
      };
    } catch (e, s) {
      Logger.error('❌ ReactionStore: General exception occurred in removeReaction', e, s);
      _reactionError = 'حدث خطأ غير متوقع';
      return {
        'success': false,
        'message': _reactionError,
      };
    } finally {
      _removeReactionLoading = false;
      notifyListeners();
    }
  }
  
  // Toggle favorite
  Future<Map<String, dynamic>> toggleFavorite({
    required String postType,
    required int postId,
  }) async {
    try {
      Logger.log('⭐ ReactionStore: toggleFavorite called with postType=$postType, postId=$postId');
      
      final data = {
        'type': postType,
        'id': postId,
      };
      
      Logger.log('📤 ReactionStore: Making API call to /favorites/toggle with data: $data');
      
      final response = await ApiService.instance.post('/favorites/toggle', data: data);
      
      Logger.log('📥 ReactionStore: Favorite toggle API response received');
      Logger.log('Toggle Favorite API Response: ${response.data}');
      
      // Check if response has the expected structure
      if (response.statusCode == 200 && response.data != null) {
        Logger.log('✅ ReactionStore: Favorite toggle API call successful');
        // Handle both success formats
        if (response.data['success'] == true) {
          return {
            'success': true,
            'message': response.data['message'] ?? 'تم تحديث المفضلة',
            'data': response.data['data'],
          };
        } else {
          // If no success field, assume success if status is 200
          return {
            'success': true,
            'message': response.data['message'] ?? 'تم تحديث المفضلة',
            'data': response.data,
          };
        }
      } else {
        Logger.warn('❌ ReactionStore: Favorite toggle API call failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': response.data?['message'] ?? 'فشل في تحديث المفضلة',
        };
      }
    } on DioException catch (e) {
      Logger.error('❌ ReactionStore: DioException occurred in toggleFavorite', e);
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e, s) {
      Logger.error('❌ ReactionStore: General exception occurred in toggleFavorite', e, s);
      return {
        'success': false,
        'message': 'حدث خطأ غير متوقع',
      };
    }
  }
  
  // Handle Dio errors
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'انتهت مهلة الاتصال';
      case DioExceptionType.sendTimeout:
        return 'انتهت مهلة إرسال البيانات';
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة استقبال البيانات';
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 400) {
          return e.response?.data['message'] ?? 'بيانات غير صحيحة';
        } else if (e.response?.statusCode == 401) {
          return 'غير مصرح لك بالوصول';
        } else if (e.response?.statusCode == 403) {
          return 'ممنوع الوصول';
        } else if (e.response?.statusCode == 404) {
          return 'الصفحة غير موجودة';
        } else if (e.response?.statusCode == 500) {
          return 'خطأ في الخادم';
        } else {
          return e.response?.data['message'] ?? 'حدث خطأ في الخادم';
        }
      case DioExceptionType.cancel:
        return 'تم إلغاء العملية';
      case DioExceptionType.connectionError:
        return 'خطأ في الاتصال بالانترنت';
      case DioExceptionType.unknown:
        return 'حدث خطأ غير متوقع';
      default:
        return 'حدث خطأ غير متوقع';
    }
  }
  
  // Clear errors
  void clearErrors() {
    _reactionError = null;
    notifyListeners();
  }
} 