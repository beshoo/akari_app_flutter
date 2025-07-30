import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

class Environment {
  static const String development = 'development';
  static const String production = 'production';
  
  // Base URLs
  static const String devBaseUrl = 'https://arrows-dev.versetech.net/api';
  static const String prodBaseUrl = 'https://akari.versetech.net/api';
  
  // Current environment (configure based on build mode)
  static String get currentEnvironment => 
    kReleaseMode ?  production : development;
  
  static String get baseUrl => 
    kReleaseMode ? prodBaseUrl : devBaseUrl;
  
  // Terms URL
  static String get termsUrl => 'https://akari.versetech.net/terms.html';

  // Initialize and log environment
  static void initialize() {
    Logger.info('🌍 Environment: ${currentEnvironment.toUpperCase()}');
    Logger.info('🔗 Base URL: $baseUrl');
  }
} 