import 'dart:async';
import 'package:akari_app/stores/auth_store.dart';
import 'package:akari_app/services/firebase_messaging_service.dart';
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

    // Check for initial notification AFTER auth check
    final hasInitialNotification = FirebaseMessagingService.initialMessage != null;
    
    if (hasInitialNotification) {
      // First navigate to appropriate screen based on auth
      if (authStore.isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
      
      // Then handle the notification (this will navigate on top)
      await Future.delayed(const Duration(milliseconds: 500)); // Small delay for navigation
      await FirebaseMessagingService.handleInitialNotificationFromSplash();
    } else {
      // Normal navigation without notification
      if (authStore.isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
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