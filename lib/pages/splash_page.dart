import 'dart:async';
import 'package:akari_app/stores/auth_store.dart';

import 'package:akari_app/services/firebase_messaging_service.dart';
import 'package:akari_app/services/version_service.dart';
import 'package:akari_app/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    final authStore = Provider.of<AuthStore>(context, listen: false);
    
    // Start non-blocking API calls in the background
    _startBackgroundApiCalls(authStore);
    
    // Navigate immediately based on current auth state (non-blocking)
    _navigateBasedOnCurrentAuthState(authStore);
  }

  Future<void> _startBackgroundApiCalls(AuthStore authStore) async {
    try {
      // Start version check in background (non-blocking)
      _performVersionCheckInBackground();
      
      // Start auth status check in background (non-blocking)
      _performAuthCheckInBackground(authStore);
      
    } catch (e) {
      Logger.log('❌ Splash: Background API calls failed: $e');
    }
  }

  Future<void> _performVersionCheckInBackground() async {
    try {
      Logger.log('🔄 Splash: Starting background version check...');
      
      // Store version check flag in a global variable or service
      // This will be checked by the destination page
      VersionService.instance.setPendingVersionCheck(true);
      
      Logger.log('✅ Splash: Background version check flag set');
    } catch (e) {
      Logger.log('❌ Splash: Background version check failed: $e');
    }
  }

  Future<void> _performAuthCheckInBackground(AuthStore authStore) async {
    try {
      Logger.log('🔄 Splash: Starting background auth check...');
      await authStore.checkAuthStatus();
      Logger.log('✅ Splash: Background auth check completed');
    } catch (e) {
      Logger.log('❌ Splash: Background auth check failed: $e');
    }
  }

  void _navigateBasedOnCurrentAuthState(AuthStore authStore) {
    if (_hasNavigated) return;
    _hasNavigated = true;

    Logger.log('🚀 Splash: Starting navigation...');
    Logger.log('🔐 Splash: Auth state - isAuthenticated: ${authStore.isAuthenticated}');

    // Check for initial notification
    final hasInitialNotification = FirebaseMessagingService.initialMessage != null;
    Logger.log('📱 Splash: Has initial notification: $hasInitialNotification');
    
    if (hasInitialNotification) {
      // Navigate based on current auth state (not waiting for API response)
      if (authStore.isAuthenticated) {
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
      if (authStore.isAuthenticated) {
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