import 'dart:async';

import 'package:akari_app/services/firebase_messaging_service.dart';
import 'package:akari_app/services/secure_storage.dart';
import 'package:akari_app/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:akari_app/pages/home/home_page.dart';
import 'package:akari_app/pages/onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _startNonBlockingInitialization();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset('assets/images/logo_spalsh.mp4');
    
    try {
      await _videoController.initialize();
      _videoController.setLooping(false);
      _videoController.setVolume(0.5); // Reduce sound by 50%
      
      // Add listener for video completion
      _videoController.addListener(() {
        if (_videoController.value.position >= _videoController.value.duration) {
          if (!_isVideoCompleted) {
            setState(() {
              _isVideoCompleted = true;
            });
            Logger.log('✅ Splash: Video completed');
          }
        }
      });
      
      _videoController.play();
      
      // Log video dimensions for debugging
      Logger.log('📹 Video dimensions: ${_videoController.value.size.width} x ${_videoController.value.size.height}');
      Logger.log('📹 Video aspect ratio: ${_videoController.value.aspectRatio}');
      
      // Get screen dimensions
      final screenSize = MediaQuery.of(context).size;
      Logger.log('📱 Screen dimensions: ${screenSize.width} x ${screenSize.height}');
      Logger.log('📱 Screen aspect ratio: ${screenSize.width / screenSize.height}');
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      Logger.log('❌ Splash: Video initialization failed: $e');
      // If video fails, just show black screen
      if (mounted) {
        setState(() {
          _isVideoInitialized = true; // Still set to true to avoid showing fallback
        });
      }
    }
  }

  bool _hasNavigated = false;

  Future<void> _startNonBlockingInitialization() async {
    // Wait for video to complete
    while (!_isVideoCompleted && mounted) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    
    // Add a small buffer after video completion
    await Future.delayed(const Duration(milliseconds: 10));

    if (!mounted) return;

    // DEBUG: Check token storage directly
    await _debugTokenStorage();
    
    // Check if token exists locally (no HTTP call)
    final token = await SecureStorage.getToken();
    final hasToken = token != null;
    
    // No HTTP calls in splash - user data will be loaded in home page
    if (hasToken) {
      Logger.log('📱 Splash: Token found, will load user data in home page');
    }
    
    Logger.log('🔑 Splash: Token exists: $hasToken');
    if (hasToken) {
      Logger.log('🔑 Splash: Token length: ${token.length}');
    }
    
    // Navigate based on token presence
    _navigateBasedOnTokenPresence(hasToken);
  }

  // DEBUG: Add token storage debugging
  Future<void> _debugTokenStorage() async {
    try {
      Logger.log('🔍 DEBUG: Checking token storage...');
      
      // Check if token exists
      final token = await SecureStorage.getToken();
      Logger.log('🔑 DEBUG: Token exists: ${token != null}');
      Logger.log('🔑 DEBUG: Token length: ${token?.length ?? 0}');
      if (token != null) {
        Logger.log('🔑 DEBUG: Token preview: ${token.substring(0, 50)}...');
      }
      
      // Check user data
      final userData = await SecureStorage.getUserData('user_data');
      Logger.log('👤 DEBUG: User data exists: ${userData != null}');
      if (userData != null) {
        Logger.log('👤 DEBUG: User data length: ${userData.length}');
      }
      
    } catch (e) {
      Logger.log('❌ DEBUG: Error checking token storage: $e');
    }
  }







  void _navigateBasedOnTokenPresence(bool hasToken) {
    if (_hasNavigated) return;
    _hasNavigated = true;

    Logger.log('🚀 Splash: Starting navigation...');
    Logger.log('🔐 Splash: Token presence - hasToken: $hasToken');

    // Check for initial notification
    final hasInitialNotification = FirebaseMessagingService.initialMessage != null;
    Logger.log('📱 Splash: Has initial notification: $hasInitialNotification');
    
    if (hasInitialNotification) {
      // Navigate based on current auth state (not waiting for API response)
      if (hasToken) {
        Logger.log('🏠 Splash: Navigating to Home (with notification)');
        _navigateToHome();
      } else {
        Logger.log('📚 Splash: Navigating to Onboarding (with notification)');
        _navigateToOnboarding();
      }
      
      // Handle notification after navigation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          FirebaseMessagingService.handleInitialNotificationFromSplash();
        }
      });
    } else {
      // Normal navigation without notification
      if (hasToken) {
        Logger.log('🏠 Splash: Navigating to Home (no notification)');
        _navigateToHome();
      } else {
        Logger.log('📚 Splash: Navigating to Onboarding (no notification)');
        _navigateToOnboarding();
      }
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    Logger.log('🏠 Splash: Executing navigation to Home');
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _navigateToOnboarding() {
    if (!mounted) return;
    Logger.log('📚 Splash: Executing navigation to Onboarding');
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const OnboardingPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA),
      body: _isVideoInitialized
          ? AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(), // Show nothing until video is ready
    );
  }
} 