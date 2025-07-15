import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

class EnumsStore extends ChangeNotifier {
  // Job titles state
  bool _jobTitlesLoading = false;
  List<dynamic>? _jobTitlesResponse;
  String? _jobTitlesError;
  
  // Getters
  bool get jobTitlesLoading => _jobTitlesLoading;
  List<dynamic>? get jobTitlesResponse => _jobTitlesResponse;
  String? get jobTitlesError => _jobTitlesError;
  
  // Get job titles from API
  Future<List<dynamic>?> getJobTitles() async {
    try {
      _jobTitlesLoading = true;
      _jobTitlesError = null;
      notifyListeners();
      
      final response = await ApiService.instance.get('/job_titles');
      
      if (response.data is List) {
        _jobTitlesResponse = response.data;
        return response.data;
      } else if (response.data is Map && response.data['success'] == true) {
        _jobTitlesResponse = response.data['data'];
        return response.data['data'];
      } else {
        _jobTitlesError = response.data['message'] ?? 'فشل في تحميل المسميات الوظيفية';
        return null;
      }
    } on DioException catch (e) {
      _jobTitlesError = _handleDioError(e);
      Logger.error('Get job titles DioException', e);
      return null;
    } catch (e, s) {
      _jobTitlesError = 'حدث خطأ غير متوقع';
      Logger.error('Get job titles error', e, s);
      return null;
    } finally {
      _jobTitlesLoading = false;
      notifyListeners();
    }
  }
  
  // Get job title by ID
  Map<String, dynamic>? getJobTitleById(int id) {
    if (_jobTitlesResponse != null) {
      try {
        return _jobTitlesResponse!.firstWhere(
          (title) => title['id'] == id,
          orElse: () => null,
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  // Get job title name by ID
  String? getJobTitleNameById(int id) {
    final title = getJobTitleById(id);
    return title?['name'];
  }
  
  // Search job titles by name
  List<dynamic>? searchJobTitles(String query) {
    if (_jobTitlesResponse != null && query.isNotEmpty) {
      return _jobTitlesResponse!.where((title) {
        final name = title['name']?.toString().toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    }
    return _jobTitlesResponse;
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
          return 'البيانات غير موجودة';
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
  void clearJobTitlesError() {
    _jobTitlesError = null;
    notifyListeners();
  }
  
  // Clear all data
  void clearAll() {
    _jobTitlesResponse = null;
    _jobTitlesError = null;
    notifyListeners();
  }
  
  // Refresh job titles
  Future<void> refreshJobTitles() async {
    await getJobTitles();
  }
} 