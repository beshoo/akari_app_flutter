import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../services/api_service.dart';
import '../services/firebase_messaging_service.dart';
import '../services/secure_storage.dart';
import '../services/version_service.dart';
import '../utils/logger.dart';

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
      Logger.error('Signup DioException', e);
      return {
        'success': false,
        'message': _signupError,
      };
    } catch (e, s) {
      _signupError = 'حدث خطأ غير متوقع';
      Logger.error('Signup error', e, s);
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
      Logger.error('Login DioException', e);
      return {
        'success': false,
        'message': _loginError,
      };
    } catch (e, s) {
      _loginError = 'حدث خطأ غير متوقع';
      Logger.error('Login error', e, s);
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
      Logger.error('Request OTP DioException', e);
      return {
        'success': false,
        'message': _otpError,
      };
    } catch (e, s) {
      _otpError = 'حدث خطأ غير متوقع';
      Logger.error('OTP error', e, s);
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

      // Get FCM token safely, handle case where Firebase might not be initialized
      String? fcmToken;
      try {
        if (FirebaseMessagingService.instance.isInitialized) {
          fcmToken = FirebaseMessagingService.instance.fcmToken;
        } else {
          Logger.log('⚠️ AuthStore: Firebase Messaging not initialized, skipping FCM token');
          fcmToken = null;
        }
      } catch (e) {
        Logger.log('⚠️ AuthStore: Could not get FCM token: $e');
        fcmToken = null;
      }
      
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
        
        // Save user data and app settings - ensure all required fields are included
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
        
        // Persist user data locally for offline access and faster startup
        await _saveUserDataLocally();
        
        Logger.log('✅ AuthStore: Login successful, saved user data:');
        Logger.log('🔐 AuthStore: User ID: ${_user?['user_id']}');
        Logger.log('🔐 AuthStore: Authenticated: ${_user?['authenticated']}');
        Logger.log('🔐 AuthStore: Support Phone: ${_user?['support_phone']}');
        Logger.log('🔐 AuthStore: Privilege: ${_user?['privilege']}');
        
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
      Logger.error('Verify OTP DioException', e);
      return {
        'success': false,
        'message': _otpError,
      };
    } catch (e, s) {
      _otpError = 'حدث خطأ غير متوقع';
      Logger.error('Verify OTP error', e, s);
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
      
      // Clear local user data
      await _clearUserDataLocally();
      
      _user = null;
      _isAuthenticated = false;
      _signupSchema = null;
      _loginSchema = null;
      _otpSchema = null;
      _signupError = null;
      _loginError = null;
      _otpError = null;
      
      Logger.log('👋 AuthStore: User logged out successfully');
      notifyListeners();
    } on DioException catch (e) {
      // Handle or log error, but don't show to user
      Logger.error('Logout DioException', e);
    } catch (e, s) {
      // Handle or log error, but don't show to user
      Logger.error('Logout error', e, s);
    }
  }
  
  // Check authentication status and refresh user data
  Future<void> checkAuthStatus() async {
    Logger.log('🔄 AuthStore: Checking authentication status...');
    try {
      final token = await SecureStorage.getToken();
      Logger.log('🔑 AuthStore: Token exists: ${token != null}');
      Logger.log('🔑 AuthStore: Token length: ${token?.length ?? 0}');
      
      if (token != null) {
        // First, try to load user data from local storage for faster startup
        await _loadUserDataLocally();
        
        // Always call /user/auth_data endpoint to get fresh data on app startup
        Logger.log('🌐 AuthStore: Calling /user/auth_data endpoint to refresh user data...');
        final response = await ApiService.instance.get('/user/auth_data');
        Logger.log('📦 AuthStore: /user/auth_data response success: ${response.data['success']}');
        Logger.log('📦 AuthStore: Full response data: ${response.data}');
        
        if (response.data['success'] == true) {
          // Update user data with fresh data from server
          // The response contains the user data directly, not nested under 'data'
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
          
          // Update local storage with fresh data
          await _saveUserDataLocally();
          
          Logger.log('✅ AuthStore: User data refreshed successfully');
          Logger.log('🔐 AuthStore: User ID: ${_user?['user_id']}');
          Logger.log('🔐 AuthStore: User Name: ${_user?['name']}');
          Logger.log('🔐 AuthStore: Authenticated: ${_user?['authenticated']}');
          Logger.log('🔐 AuthStore: Support Phone: ${_user?['support_phone']}');
          Logger.log('🔐 AuthStore: User Privilege: ${_user?['privilege']}');
          
          // Send version update to server (non-blocking)
          VersionService.instance.sendVersionUpdate().catchError((e) {
            Logger.log('⚠️ AuthStore: Version update failed but continuing: $e');
          });
        } else {
          Logger.log('❌ AuthStore: /user/auth_data endpoint returned failure, deleting token');
          await SecureStorage.deleteToken();
          await _clearUserDataLocally();
          _isAuthenticated = false;
          _user = null;
        }
      } else {
        Logger.log('❌ AuthStore: No token found');
        await _clearUserDataLocally();
        _isAuthenticated = false;
        _user = null;
      }
    } on DioException catch (e) {
      // If we have local user data and network fails, use local data
      if (_user == null) {
        await _loadUserDataLocally();
      }
      
      if (_user != null) {
        Logger.log('📱 AuthStore: Network error, using cached user data');
        Logger.log('🔐 AuthStore: Cached User ID: ${_user?['user_id']}');
        Logger.log('🔐 AuthStore: Cached Authenticated: ${_user?['authenticated']}');
        Logger.log('🔐 AuthStore: Cached Support Phone: ${_user?['support_phone']}');
        Logger.log('🔐 AuthStore: Cached Privilege: ${_user?['privilege']}');
        _isAuthenticated = true;
      } else {
        Logger.log('❌ AuthStore: Network error and no cached data');
        _isAuthenticated = false;
        _user = null;
      }
      Logger.error('❌ AuthStore: Check auth status DioException', e);
    } catch (e, s) {
      _isAuthenticated = false;
      _user = null;
      Logger.error('❌ AuthStore: Check auth status error', e, s);
    } finally {
      Logger.log('🏁 AuthStore: Final auth state - Authenticated: $_isAuthenticated');
      notifyListeners();
    }
  }

  // Save user data to local storage
  Future<void> _saveUserDataLocally() async {
    if (_user != null) {
      try {
        final userDataJson = jsonEncode(_user);
        await SecureStorage.setUserData('user_data', userDataJson);
        Logger.log('💾 AuthStore: User data saved locally');
      } catch (e) {
        Logger.error('❌ AuthStore: Failed to save user data locally', e);
      }
    }
  }

  // Load user data from local storage
  Future<void> _loadUserDataLocally() async {
    try {
      final userDataJson = await SecureStorage.getUserData('user_data');
      if (userDataJson != null) {
        _user = Map<String, dynamic>.from(jsonDecode(userDataJson));
        Logger.log('📱 AuthStore: User data loaded from local storage');
        Logger.log('🔐 AuthStore: Cached User ID: ${_user?['user_id']}');
      } else {
        Logger.log('📱 AuthStore: No cached user data found');
      }
    } catch (e) {
      Logger.error('❌ AuthStore: Failed to load user data from local storage', e);
      _user = null;
    }
  }

  // Clear user data from local storage
  Future<void> _clearUserDataLocally() async {
    try {
      await SecureStorage.deleteUserData('user_data');
      Logger.log('🗑️ AuthStore: User data cleared from local storage');
    } catch (e) {
      Logger.error('❌ AuthStore: Failed to clear user data from local storage', e);
    }
  }

  // Manual method to restore auth state (for debugging)
  Future<Map<String, dynamic>> restoreAuthState() async {
    Logger.log('🔧 AuthStore: Manual auth state restoration requested');
    await checkAuthStatus();
    
    return {
      'success': _isAuthenticated,
      'message': _isAuthenticated ? 'Auth state restored successfully' : 'Failed to restore auth state',
      'data': {
        'user_id': userId,
        'name': userName,
        'privilege': userPrivilege,
        'authenticated': isAuthenticated,
        'has_token': await SecureStorage.getToken() != null,
      }
    };
  }

  // Test method to verify /user/auth_data API call
  Future<Map<String, dynamic>> testAuthDataApi() async {
    Logger.log('🧪 AuthStore: Testing /user/auth_data API call...');
    
    try {
      final token = await SecureStorage.getToken();
      Logger.log('🔑 Test: Token exists: ${token != null}');
      Logger.log('🔑 Test: Token preview: ${token?.substring(0, 50)}...');
      
      final response = await ApiService.instance.get('/user/auth_data');
      Logger.log('✅ Test: Response received');
      Logger.log('📦 Test: Status Code: ${response.statusCode}');
      Logger.log('📦 Test: Response Headers: ${response.headers}');
      Logger.log('📦 Test: Full Response: ${response.data}');
      
      return {
        'success': true,
        'message': 'API test completed successfully',
        'data': response.data,
      };
    } catch (e, s) {
      Logger.error('❌ Test: API call failed', e, s);
      return {
        'success': false,
        'message': 'API test failed: $e',
      };
    }
  }

  // Method to manually refresh user data from server
  Future<Map<String, dynamic>> refreshUserData() async {
    Logger.log('🔄 AuthStore: Manual user data refresh requested');
    
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      Logger.log('🌐 AuthStore: Calling /user/auth_data to refresh user data...');
      final response = await ApiService.instance.get('/user/auth_data');
      Logger.log('📦 AuthStore: Manual refresh response: ${response.data}');
      
      if (response.data['success'] == true) {
        // Update user data with fresh data from server
        // The response contains the user data directly, not nested under 'data'
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
        
        // Update local storage with fresh data
        await _saveUserDataLocally();
        
        Logger.log('✅ AuthStore: User data refreshed manually');
        Logger.log('🔐 AuthStore: User ID: ${_user?['user_id']}');
        Logger.log('🔐 AuthStore: Authenticated: ${_user?['authenticated']}');
        Logger.log('🔐 AuthStore: Support Phone: ${_user?['support_phone']}');
        Logger.log('🔐 AuthStore: Privilege: ${_user?['privilege']}');
        
        notifyListeners();
        
        return {
          'success': true,
          'message': 'User data refreshed successfully',
          'data': _user,
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to refresh user data',
        };
      }
    } on DioException catch (e) {
      Logger.error('❌ AuthStore: Manual refresh DioException', e);
      return {
        'success': false,
        'message': _handleDioError(e),
      };
    } catch (e, s) {
      Logger.error('❌ AuthStore: Manual refresh error', e, s);
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
    _signupError = null;
    _loginError = null;
    _otpError = null;
    notifyListeners();
  }
} 