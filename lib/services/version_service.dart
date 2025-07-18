import 'package:package_info_plus/package_info_plus.dart';
import 'api_service.dart';
import 'firebase_messaging_service.dart';
import '../utils/logger.dart';

class VersionService {
  static final VersionService instance = VersionService._internal();
  
  factory VersionService() {
    return instance;
  }
  
  VersionService._internal();
  
  // Cache for package info to avoid multiple calls
  static PackageInfo? _cachedPackageInfo;
  
  /// Get package info with caching
  static Future<PackageInfo?> getPackageInfo() async {
    if (_cachedPackageInfo != null) {
      return _cachedPackageInfo;
    }
    
    try {
      _cachedPackageInfo = await PackageInfo.fromPlatform();
      return _cachedPackageInfo;
    } catch (e) {
      Logger.log('❌ VersionService: Failed to get PackageInfo: $e');
      return null;
    }
  }

  /// Sends version information to the server
  /// This should be called when the app starts and user is authenticated
  Future<void> sendVersionUpdate() async {
    try {
      Logger.log('🔄 VersionService: Starting version update...');
      
      // Small delay to ensure app is fully initialized
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Get app version information with fallback
      String version = 'unknown';
      Logger.log('📦 VersionService: Attempting to get PackageInfo...');
      
      final PackageInfo? packageInfo = await getPackageInfo();
      if (packageInfo != null) {
        // Send only the version number (without build number)
        version = packageInfo.version;
        Logger.log('📦 VersionService: Successfully got version from PackageInfo: $version');
        Logger.log('📦 VersionService: App name: ${packageInfo.appName}');
        Logger.log('📦 VersionService: Package name: ${packageInfo.packageName}');
        Logger.log('📦 VersionService: Version (sent to server): ${packageInfo.version}');
        Logger.log('📦 VersionService: Build number (internal): ${packageInfo.buildNumber}');
      } else {
        // Fallback to the actual version from pubspec.yaml (without build number)
        version = '1.0.0';
        Logger.log('⚠️ VersionService: Using fallback version: $version');
      }
      
      // Get Firebase token
      final String? firebaseToken = FirebaseMessagingService.instance.fcmToken;
      
      Logger.log('📱 VersionService: App version: $version');
      Logger.log('🔥 VersionService: Firebase token available: ${firebaseToken != null}');
      
      // Prepare request data
      final Map<String, dynamic> requestData = {
        'version': version,
        'firebase': firebaseToken ?? '',
      };
      
      // Send the request
      final response = await ApiService.instance.post(
        '/version/set',
        data: requestData,
      );
      
      if (response.data['success'] == true) {
        Logger.log('✅ VersionService: Version update sent successfully');
      } else {
        Logger.log('⚠️ VersionService: Version update failed - ${response.data['message'] ?? 'Unknown error'}');
      }
      
    } catch (e, stackTrace) {
      Logger.log('❌ VersionService: Error sending version update - $e');
      Logger.log('📍 VersionService: Stack trace: $stackTrace');
      // Don't throw error - version check shouldn't block app functionality
    }
  }
} 