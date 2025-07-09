import 'package:flutter/foundation.dart';

class Environment {
  static const String development = 'development';
  static const String production = 'production';
  
  // Base URLs
  static const String devBaseUrl = 'https://arrows-dev.versetech.net/api';
  static const String prodBaseUrl = 'https://akari.versetech.net/api';
  
  // Current environment (configure based on build mode)
  static String get currentEnvironment => 
    kDebugMode ? development : production;
  
  static String get baseUrl => 
    currentEnvironment == development ? devBaseUrl : prodBaseUrl;
  
  // Terms URL
  static String get termsUrl => 
    currentEnvironment == development 
      ? 'https://arrows-dev.versetech.net/terms.html'
      : 'https://akari.versetech.net/terms.html';
} 