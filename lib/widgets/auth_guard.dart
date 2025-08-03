import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../widgets/custom_spinner.dart';
import '../utils/logger.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;
  final bool requireAuth;

  const AuthGuard({
    super.key,
    required this.child,
    this.requireAuth = true,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final isAuth = await ChatService.isAuthenticated();
      
      if (isAuth) {
        // Test API connection if authenticated
        final isConnected = await ChatService.testConnection();
        if (!isConnected) {
          _errorMessage = 'لا يمكن الاتصال بالخادم. يرجى التحقق من الاتصال بالإنترنت.';
        }
      }

      setState(() {
        _isAuthenticated = isAuth;
        _isLoading = false;
      });

      Logger.log('AuthGuard: Authentication check completed - isAuth: $isAuth');
    } catch (e) {
      Logger.log('AuthGuard: Error checking authentication - $e');
      setState(() {
        _isLoading = false;
        _isAuthenticated = false;
        _errorMessage = 'حدث خطأ في التحقق من الهوية. يرجى المحاولة مرة أخرى.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && widget.requireAuth) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomSpinner(size: 40.0),
              const SizedBox(height: 16),
              Text(
                'التحقق من الهوية...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontFamily: 'Cairo',
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    fontFamily: 'Cairo',
                    height: 1.5,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _checkAuthentication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA88B67),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isAuthenticated) {
      return _buildLoginPrompt();
    }

    return widget.child;
  }

  Widget _buildLoginPrompt() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: const Color(0xFFA88B67),
              ),
              const SizedBox(height: 16),
              Text(
                'تسجيل الدخول مطلوب',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                  fontFamily: 'Cairo',
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              Text(
                'يجب تسجيل الدخول أولاً لاستخدام ميزة المحادثة',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  fontFamily: 'Cairo',
                  height: 1.5,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA88B67),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'العودة',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFA88B67),
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 