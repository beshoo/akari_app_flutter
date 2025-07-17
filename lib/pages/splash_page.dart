import 'dart:async';
import 'package:akari_app/services/secure_storage.dart';
import 'package:akari_app/stores/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for a few seconds on the splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authStore = Provider.of<AuthStore>(context, listen: false);
    
    // Check authentication status and refresh user data from server
    await authStore.checkAuthStatus();

    if (!mounted) return;

    if (authStore.isAuthenticated) {
      // If user is authenticated, go to home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Otherwise, go to onboarding
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Transform.scale(
          scale: 0.8, // Reduce size by 20%
          child: Image.asset(
            'assets/images/splash_1.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
} 