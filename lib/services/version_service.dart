import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../utils/logger.dart';
import 'api_service.dart';
import 'firebase_messaging_service.dart';

class VersionResponse {
  final String version;
  final int forceBefore;

  VersionResponse({required this.version, required this.forceBefore});

  factory VersionResponse.fromJson(Map<String, dynamic> json) {
    return VersionResponse(
      version: json['version']?.toString() ?? '0',
      forceBefore: int.tryParse(json['force_before']?.toString() ?? '0') ?? 0,
    );
  }
}

class VersionService {
  static final VersionService instance = VersionService._internal();
  
  factory VersionService() {
    return instance;
  }
  
  VersionService._internal();
  
  // Cache for package info to avoid multiple calls
  static PackageInfo? _cachedPackageInfo;
  
  // Google Play Store URL
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=akari.versetech.net';

  /// Check if the current platform is Android
  static bool get isAndroid => Platform.isAndroid;

  /// Check if the current platform is iOS
  static bool get isIOS => Platform.isIOS;

  /// Get the current platform name
  static String get platformName {
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    return 'Unknown';
  }

  /// Get platform-specific store URL
  static String get storeUrl {
    if (isAndroid) {
      return playStoreUrl;
    } else if (isIOS) {
      // Add your App Store URL here when available
      return 'https://apps.apple.com/app/your-app-id';
    }
    return playStoreUrl; // Default to Play Store
  }

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

  /// Get current app version as integer
  Future<int> getCurrentAppVersion() async {
    try {
      final PackageInfo? packageInfo = await getPackageInfo();
      if (packageInfo != null) {
        // Convert version to int by removing dots (e.g., "1.0.0" -> 100)
        final versionParts = packageInfo.version.split('.');
        int versionNumber = 0;
        
        for (int i = 0; i < versionParts.length && i < 3; i++) {
          versionNumber += int.parse(versionParts[i]) * (100 ~/ (i + 1));
        }
        
        // If we have build number, use it as the version number
        if (packageInfo.buildNumber.isNotEmpty) {
          final buildNumber = int.tryParse(packageInfo.buildNumber);
          if (buildNumber != null) {
            return buildNumber;
          }
        }
        
        return versionNumber;
      }
      return 1; // Fallback version
    } catch (e) {
      Logger.log('❌ VersionService: Error getting app version: $e');
      return 1;
    }
  }

  /// Get server version information
  Future<VersionResponse?> getServerVersion() async {
    try {
      Logger.log('🔄 VersionService: Getting server version...');
      
      final response = await ApiService.instance.get('/version/get');
      
      if (response.data['success'] == true || response.data.containsKey('version')) {
        final versionResponse = VersionResponse.fromJson(response.data);
        Logger.log('✅ VersionService: Server version: ${versionResponse.version}, Force before: ${versionResponse.forceBefore}');
        return versionResponse;
      } else {
        Logger.log('⚠️ VersionService: Server version check failed - ${response.data['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      Logger.log('❌ VersionService: Error getting server version: $e');
      return null;
    }
  }

  /// Check if app needs update and show appropriate dialog
  Future<void> checkAndHandleVersionUpdate(BuildContext context) async {
    try {
      Logger.log('🔄 VersionService: Starting version check...');
      
      final serverVersionResponse = await getServerVersion();
      if (serverVersionResponse == null) {
        Logger.log('⚠️ VersionService: Could not get server version, skipping update check');
        return;
      }
      
      final currentAppVersion = await getCurrentAppVersion();
      final serverVersion = int.tryParse(serverVersionResponse.version) ?? 0;
      final forceBefore = serverVersionResponse.forceBefore;
      
      Logger.log('📱 VersionService: Current app version: $currentAppVersion');
      Logger.log('🌐 VersionService: Server version: $serverVersion');
      Logger.log('⚠️ VersionService: Force before: $forceBefore');
      
      // Check if app version is greater than server version
      if (currentAppVersion > serverVersion) {
        Logger.log('📈 VersionService: App version is newer, updating server...');
        await _updateServerVersion(currentAppVersion.toString());
        return;
      }
      
      // Check if server version is greater than app version (update needed)
      if (serverVersion > currentAppVersion) {
        Logger.log('🔄 VersionService: Update available, showing update dialog...');
        
        // Check if force update is required
        final isForceUpdate = forceBefore > 0 && currentAppVersion <= forceBefore;
        
        if (context.mounted) {
          await _showUpdateBottomSheet(
            context, 
            isForceUpdate: isForceUpdate,
            serverVersion: serverVersion,
            currentVersion: currentAppVersion,
          );
        }
      } else {
        // App version equals server version - no action needed
        Logger.log('✅ VersionService: App version equals server version, no action needed');
      }
      
    } catch (e) {
      Logger.log('❌ VersionService: Error in version check: $e');
    }
  }

  /// Show update bottom sheet
  Future<void> _showUpdateBottomSheet(
    BuildContext context, {
    required bool isForceUpdate,
    required int serverVersion,
    required int currentVersion,
  }) async {
    return showModalBottomSheet(
      context: context,
      isDismissible: !isForceUpdate,
      enableDrag: !isForceUpdate,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WillPopScope(
        onWillPop: () async => !isForceUpdate,
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar (only if not forced update)
                  if (!isForceUpdate) ...[
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF633E3D).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.system_update,
                      size: 40,
                      color: Color(0xFF633E3D),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    isForceUpdate ? 'تحديث مطلوب' : 'تحديث متاح',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Message
                  Text(
                    isForceUpdate 
                      ? 'يجب تحديث التطبيق للمتابعة. لا يمكن استخدام التطبيق بدون التحديث.'
                      : 'يتوفر تحديث جديد لتطبيق عقاري. يُنصح بالتحديث للحصول على أحدث الميزات والتحسينات.',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      color: Color(0xFF8C7A6A),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Buttons
                  Column(
                    children: [
                      // Update Now Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xff633e3d),
                                Color(0xff774b46),
                                Color(0xff8d5e52),
                                Color(0xffa47764),
                                Color(0xffbda28c),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                await _openPlayStore();
                                if (!isForceUpdate && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Center(
                                child: Text(
                                  'تحديث الآن',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Update Later Button (only if not forced)
                      if (!isForceUpdate) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F5F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.of(context).pop(),
                                child: const Center(
                                  child: Text(
                                    'التحديث لاحقاً',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Color(0xFF8C7A6A),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  // Safe area padding
                  SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Open platform-specific app store
  Future<void> _openPlayStore() async {
    try {
      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Logger.log('✅ VersionService: Opened ${platformName} store');
      } else {
        Logger.log('❌ VersionService: Could not launch ${platformName} store URL');
      }
    } catch (e) {
      Logger.log('❌ VersionService: Error opening ${platformName} store: $e');
    }
  }

  /// Update server version when app is newer
  Future<void> _updateServerVersion(String version) async {
    try {
      Logger.log('🔄 VersionService: Updating server version to $version...');
      
      final response = await ApiService.instance.post(
        '/version/set',
        data: {'version': version},
      );
      
      if (response.data['success'] == true) {
        Logger.log('✅ VersionService: Server version updated successfully');
      } else {
        Logger.log('⚠️ VersionService: Server version update failed - ${response.data['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      Logger.log('❌ VersionService: Error updating server version: $e');
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
      
      // Get Firebase token safely, handle case where Firebase might not be initialized
      String? firebaseToken;
      try {
        if (FirebaseMessagingService.instance.isInitialized) {
          firebaseToken = FirebaseMessagingService.instance.fcmToken;
        } else {
          Logger.log('⚠️ VersionService: Firebase Messaging not initialized, skipping FCM token');
          firebaseToken = null;
        }
      } catch (e) {
        Logger.log('⚠️ VersionService: Could not get FCM token: $e');
        firebaseToken = null;
      }
      
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