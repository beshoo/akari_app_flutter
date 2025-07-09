import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/firebase_messaging_service.dart';
import '../services/secure_storage.dart';

class AuthStore extends ChangeNotifier {
  // Signup state
  bool _signupLoading = false;
  Map<String, dynamic>? _signupSchema;
  String? _signupError;
  
  // Login state
  bool _loginLoading = false;
  Map<String, dynamic>? _loginSchema;
  String? _loginError;
  
  // OTP state
  bool _otpLoading = false;
  Map<String, dynamic>? _otpSchema;
  String? _otpError;
  
  // User state
  Map<String, dynamic>? _user;
  bool _isAuthenticated = false;
  
  // Getters
  bool get signupLoading => _signupLoading;
  Map<String, dynamic>? get signupSchema => _signupSchema;
  String? get signupError => _signupError;
  
  bool get loginLoading => _loginLoading;
  Map<String, dynamic>? get loginSchema => _loginSchema;
  String? get loginError => _loginError;
  
  bool get otpLoading => _otpLoading;
  Map<String, dynamic>? get otpSchema => _otpSchema;
  String? get otpError => _otpError;
  
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  
  // User property getters
  String? get userId => _user?['user_id']?.toString();
  String? get userName => _user?['name'];
  String? get userPhone => _user?['phone'];
  String? get userPrivilege => _user?['privilege'];
  bool get canUpload => _user?['allow_upload'] ?? false;
  bool get isUserAuthenticated => _user?['authenticated'] ?? false;
  String? get supportPhone => _user?['support_phone'];
  bool get showAdsBanner => _user?['ads_banner'] ?? false;
  bool get isOpenForAll => _user?['open_akari_for_all'] ?? false;
  bool get httpErrorLog => _user?['http_error_log'] ?? false;
  bool get chatEnabled => _user?['chat'] ?? false;
  String? get tokenType => _user?['token_type'];
  int? get tokenExpiresIn => _user?['expires_in'];
  
  // Signup functionality
  Future<Map<String, dynamic>> signup(Map<String, dynamic> signupData) async {
    try {
      _signupLoading = true;
      _signupError = null;
      notifyListeners();
      
      final response = await ApiService.instance.post('/signup', data: signupData);
      
      _signupSchema = response.data;
      
      // If signup successful, return success response
      if (response.data['success'] == true) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'تم إنشاء الحساب بنجاح',
          'data': response.data['data'],
        };
      } else {
        _signupError = response.data['message'] ?? 'حدث خطأ في إنشاء الحساب';
        return {
          'success': false,
          'message': _signupError,
        };
      }
    } on DioException catch (e) {
      _signupError = _handleDioError(e);
      return {
        'success': false,
        'message': _signupError,
      };
    } catch (e) {
      _signupError = 'حدث خطأ غير متوقع';
      if (kDebugMode) {
        print('Signup error: $e');
      }
      return {
        'success': false,
        'message': _signupError,
      };
    } finally {
      _signupLoading = false;
      notifyListeners();
    }
  }
  
  // Login functionality
  Future<Map<String, dynamic>> login(Map<String, dynamic> loginData) async {
    try {
      _loginLoading = true;
      _loginError = null;
      notifyListeners();
      
      final response = await ApiService.instance.post('/login', data: loginData);
      
      _loginSchema = response.data;
      
      if (response.data['success'] == true) {
        // Save token if provided
        if (response.data['data']?['token'] != null) {
          await SecureStorage.setToken(response.data['data']['token']);
        }
        
        // Save user data
        _user = response.data['data']['user'];
        _isAuthenticated = true;
        
        return {
          'success': true,
          'message': response.data['message'] ?? 'تم تسجيل الدخول بنجاح',
          'data': response.data['data'],
        };
      } else {
        _loginError = response.data['message'] ?? 'خطأ في تسجيل الدخول';
        return {
          'success': false,
          'message': _loginError,
        };
      }
    } on DioException catch (e) {
      _loginError = _handleDioError(e);
      return {
        'success': false,
        'message': _loginError,
      };
    } catch (e) {
      _loginError = 'حدث خطأ غير متوقع';
      if (kDebugMode) {
        print('Login error: $e');
      }
      return {
        'success': false,
        'message': _loginError,
      };
    } finally {
      _loginLoading = false;
      notifyListeners();
    }
  }
  
  // Request OTP functionality
  Future<Map<String, dynamic>> requestOtp(Map<String, dynamic> otpData) async {
    try {
      _otpLoading = true;
      _otpError = null;
      notifyListeners();
      
      final response = await ApiService.instance.post('/requestOtp', data: otpData);
      
      _otpSchema = response.data;
      
      if (response.data['success'] == true) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'تم إرسال رمز التحقق بنجاح',
          'data': response.data['data'],
        };
      } else {
        _otpError = response.data['message'] ?? 'خطأ في إرسال رمز التحقق';
        return {
          'success': false,
          'message': _otpError,
        };
      }
    } on DioException catch (e) {
      _otpError = _handleDioError(e);
      return {
        'success': false,
        'message': _otpError,
      };
    } catch (e) {
      _otpError = 'حدث خطأ غير متوقع';
      if (kDebugMode) {
        print('OTP error: $e');
      }
      return {
        'success': false,
        'message': _otpError,
      };
    } finally {
      _otpLoading = false;
      notifyListeners();
    }
  }
  
  // Verify OTP functionality
  Future<Map<String, dynamic>> loginWithOtp(Map<String, dynamic> verifyData) async {
    try {
      _otpLoading = true;
      _otpError = null;
      notifyListeners();

      final fcmToken = FirebaseMessagingService.instance.fcmToken;
      final data = {
        ...verifyData,
        'firebase': fcmToken,
      };
      
      final response = await ApiService.instance.post('/loginWithOtp', data: data);
      
      _otpSchema = response.data;
      
      if (response.data['success'] == true) {
        // Save access token if provided
        if (response.data['access_token'] != null) {
          await SecureStorage.setToken(response.data['access_token']);
        }
        
        // Save user data and app settings
        _user = {
          'user_id': response.data['user_id'],
          'name': response.data['name'],
          'phone': response.data['phone'],
          'privilege': response.data['privilege'],
          'allow_upload': response.data['allow_upload'],
          'authenticated': response.data['authenticated'],
          'support_phone': response.data['support_phone'],
          'ads_banner': response.data['ads_banner'],
          'open_akari_for_all': response.data['open_akari_for_all'],
          'http_error_log': response.data['http_error_log'],
          'chat': response.data['chat'],
          'token_type': response.data['token_type'],
          'expires_in': response.data['expires_in'],
        };
        _isAuthenticated = true;
        
        return {
          'success': true,
          'message': response.data['message'] ?? 'تم التحقق بنجاح',
          'data': response.data,
        };
      } else {
        _otpError = response.data['message'] ?? 'خطأ في التحقق من الرمز';
        return {
          'success': false,
          'message': _otpError,
        };
      }
    } on DioException catch (e) {
      _otpError = _handleDioError(e);
      return {
        'success': false,
        'message': _otpError,
      };
    } catch (e) {
      _otpError = 'حدث خطأ غير متوقع';
      if (kDebugMode) {
        print('Verify OTP error: $e');
      }
      return {
        'success': false,
        'message': _otpError,
      };
    } finally {
      _otpLoading = false;
      notifyListeners();
    }
  }
  
  // Logout functionality
  Future<void> logout() async {
    try {
      await SecureStorage.deleteToken();
      _user = null;
      _isAuthenticated = false;
      _signupSchema = null;
      _loginSchema = null;
      _otpSchema = null;
      _signupError = null;
      _loginError = null;
      _otpError = null;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Logout error: $e');
      }
    }
  }
  
  // Check authentication status
  Future<void> checkAuthStatus() async {
    try {
      final token = await SecureStorage.getToken();
      if (token != null) {
        // Verify token with backend
        final response = await ApiService.instance.get('/me');
        if (response.data['success'] == true) {
          _user = response.data['data'];
          _isAuthenticated = true;
        } else {
          await SecureStorage.deleteToken();
          _isAuthenticated = false;
        }
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      await SecureStorage.deleteToken();
      _isAuthenticated = false;
      if (kDebugMode) {
        print('Check auth status error: $e');
      }
    }
    notifyListeners();
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
    _signupError = null;
    _loginError = null;
    _otpError = null;
    notifyListeners();
  }
} 