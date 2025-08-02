import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/property_details_page.dart';
import '../utils/logger.dart';
import '../services/secure_storage.dart';

// Global notification callback handler
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  Logger.log('📱 Background notification tap: ${notificationResponse.payload}');
  FirebaseMessagingService.instance.handleNotificationTap(notificationResponse);
}

class FirebaseMessagingService {
  static final FirebaseMessagingService instance = FirebaseMessagingService._internal();

  factory FirebaseMessagingService() {
    return instance;
  }

  FirebaseMessagingService._internal();

  // Flutter Local Notifications instance
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  // Callback for foreground notification
  void Function()? onForegroundNotification;

  // Make FirebaseMessaging lazy-loaded to avoid initialization issues
  FirebaseMessaging? _firebaseMessaging;
  FirebaseMessaging get _firebaseMessagingInstance {
    _firebaseMessaging ??= FirebaseMessaging.instance;
    return _firebaseMessaging!;
  }

  String? _token;
  static RemoteMessage? _initialMessage; // Static for splash screen access
  
  // Option to handle notifications immediately in foreground (without showing notification)
  bool handleForegroundImmediately = false;

  // Add a persistent flag for notification state
  static const String _notificationEnabledKey = 'notifications_enabled';

  // Get notification enabled state - check actual system permission
  static Future<bool> isNotificationEnabled() async {
    try {
      // Check if notifications are allowed at the system level
      final isAllowed = await Permission.notification.isGranted;
      Logger.log('🔔 System notification permission: $isAllowed');
      
      // Also check our stored preference
      final storedValue = await SecureStorage.getUserData(_notificationEnabledKey);
      final storedEnabled = storedValue == 'true';
      Logger.log('🔔 Stored notification preference: $storedEnabled');
      
      // Return true only if both system permission and stored preference are true
      return isAllowed && storedEnabled;
    } catch (e) {
      Logger.error('Error checking notification permission', e);
      // Fallback to stored value only
    final value = await SecureStorage.getUserData(_notificationEnabledKey);
    return value == 'true';
    }
  }

  // Check if user has disabled notifications at system level
  static Future<bool> isSystemNotificationEnabled() async {
    try {
      return await Permission.notification.isGranted;
    } catch (e) {
      Logger.error('Error checking system notification permission', e);
      return false;
    }
  }

  // Enable notifications: request permission and subscribe
  Future<void> enableNotifications() async {
    Logger.log('🔔 Enabling notifications');
    
    // Request permission using permission_handler
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      Logger.log('🔔 Permission denied by user');
      throw Exception('Notification permission denied');
    }
    
    // Also request Firebase permission
    await _firebaseMessagingInstance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    await _firebaseMessagingInstance.subscribeToTopic('all');
    await SecureStorage.setUserData(_notificationEnabledKey, 'true');
    Logger.log('🔔 Notifications enabled');
  }

  // Disable notifications: unsubscribe from topic
  Future<void> disableNotifications() async {
    Logger.log('🔕 Disabling notifications');
    await _firebaseMessagingInstance.unsubscribeFromTopic('all');
    await SecureStorage.setUserData(_notificationEnabledKey, 'false');
    Logger.log('🔕 Notifications disabled');
  }

  String? get fcmToken => _token;
  static RemoteMessage? get initialMessage => _initialMessage;
  static void clearInitialMessage() => _initialMessage = null;
  
  // Check if Firebase is properly initialized
  bool get isInitialized => _firebaseMessaging != null;

  Future<void> initialize() async {
    try {
      // Initialize flutter local notifications
      await _initializeLocalNotifications();

      // Request permissions
      await _firebaseMessagingInstance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Get FCM token
      _token = await _firebaseMessagingInstance.getToken();
      Logger.log('🔑 Firebase Messaging Token: $_token');

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Listen for notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      // Store initial message for splash screen to handle
      _initialMessage = await _firebaseMessagingInstance.getInitialMessage();
      if (_initialMessage != null) {
        Logger.log('📱 Initial message stored for splash: ${_initialMessage!.messageId}');
      }
    } catch (e, stack) {
      Logger.log('❌ Firebase Messaging initialization failed: $e');
      Logger.log('❌ Stack trace: $stack');
      // Continue without Firebase messaging if it fails
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/notification_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'akari_notifications',
      'Akari Notifications',
      description: 'Notifications from Akari App',
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationTap(NotificationResponse notificationResponse) {
    Logger.log('📱 Notification tapped: ${notificationResponse.payload}');
    handleNotificationTap(notificationResponse);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    Logger.log('📱 Got message in foreground: ${message.messageId}');
    Logger.log('📱 Message data: ${message.data}');

    // Call the callback if set
    if (onForegroundNotification != null) {
      onForegroundNotification!();
    }

    // Increment notification count in store
    // notificationStore.increment(); // This line was removed as per the edit hint

    // If configured to handle immediately, do so without showing notification
    if (handleForegroundImmediately && message.data.isNotEmpty) {
      Logger.log('📱 Handling foreground message immediately');
      _handleNotificationAction(message.data);
      return;
    }

    if (message.notification != null) {
      Logger.log('📱 Notification: ${message.notification!.title} - ${message.notification!.body}');
      
      // Display the notification with proper payload encoding
      await _showNotification(
        title: message.notification!.title ?? 'عقاري',
        body: message.notification!.body ?? 'You have a new message',
        payload: _encodePayload(message.data),
      );
    } else if (message.data.isNotEmpty) {
      // Handle data-only messages immediately in foreground
      Logger.log('📱 Data-only message in foreground, handling immediately');
      _handleNotificationAction(message.data);
    } else {
      Logger.log('📱 Foreground message with no data or notification content');
    }
  }

  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'akari_notifications',
          'Akari Notifications',
          channelDescription: 'Notifications from Akari App',
          color: const Color(0xff633e3d),
          ledColor: Colors.white,
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
             payload: payload ?? '{}',
    );
  }

  void handleNotificationTap(NotificationResponse notificationResponse) {
    Logger.log('📱 Notification tapped: ${notificationResponse.payload}');
    
    final payload = notificationResponse.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final data = _decodePayload(payload);
        Logger.log('📱 Decoded notification data: $data');
        
        if (data.isNotEmpty) {
          _handleNotificationAction(data);
        } else {
          Logger.log('📱 Empty data, navigating to notifications page');
          Get.toNamed('/notifications');
        }
      } catch (e) {
        Logger.log('❌ Error handling notification tap: $e');
        Get.toNamed('/notifications');
      }
    } else {
      Logger.log('📱 No payload, navigating to notifications page');
      Get.toNamed('/notifications');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    Logger.log('📱 Notification opened app: ${message.messageId}');
    Logger.log('📱 Message data: ${message.data}');
    
    // Handle navigation based on message data
    _handleNotificationAction(message.data);
  }

  String _encodePayload(Map<String, dynamic> data) {
    try {
      // Convert map to JSON string for more reliable encoding
      return jsonEncode(data);
    } catch (e) {
      Logger.log('❌ Error encoding payload: $e');
      return '{}';
    }
  }

  Map<String, dynamic> _decodePayload(String payload) {
    try {
      // Convert JSON string back to map
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (e) {
      Logger.log('❌ Error decoding payload: $e');
      return {};
    }
  }

  void _handleNotificationAction(Map<String, dynamic> data) {
    Logger.log('📱 Handling notification action with data: $data');
    
    try {
      final notificationType = data['notification_type'];
      final content = data['content'];

      Logger.log('📱 Notification type: $notificationType, Content: $content');

      switch (notificationType) {
        case 'share':
          if (content != null) {
            Logger.log('📱 Navigating to share details: $content');
            final shareId = int.tryParse(content.toString());
            if (shareId != null) {
              Get.to(() => PropertyDetailsPage(
                id: shareId,
                itemType: "share",
              ));
            } else {
              Logger.log('❌ Invalid share ID: $content');
              Get.toNamed('/notifications');
            }
          } else {
            Logger.log('❌ Share notification missing content');
            Get.toNamed('/notifications');
          }
          break;
          
        case 'apartment':
          if (content != null) {
            Logger.log('📱 Navigating to apartment details: $content');
            final apartmentId = int.tryParse(content.toString());
            if (apartmentId != null) {
              Get.to(() => PropertyDetailsPage(
                id: apartmentId,
                itemType: "apartment",
              ));
            } else {
              Logger.log('❌ Invalid apartment ID: $content');
              Get.toNamed('/notifications');
            }
          } else {
            Logger.log('❌ Apartment notification missing content');
            Get.toNamed('/notifications');
          }
          break;
          
        case 'url':
          if (content != null) {
            Logger.log('📱 Opening URL: $content');
            _openUrl(content.toString());
          } else {
            Logger.log('❌ URL notification missing content');
            Get.toNamed('/notifications');
          }
          break;
          
        default:
          Logger.log('📱 Unknown notification type or no type specified, navigating to notifications page');
          Get.toNamed('/notifications');
          break;
      }
    } catch (e) {
      Logger.log('❌ Error handling notification action: $e');
      Get.toNamed('/notifications');
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      Logger.log('📱 Attempting to open URL: $url');
      
      final uri = Uri.parse(url);
      Logger.log('📱 Parsed URI: $uri');
      
      final canLaunch = await canLaunchUrl(uri);
      Logger.log('📱 Can launch URL: $canLaunch');
      
      if (canLaunch) {
        final result = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        Logger.log('📱 Launch result: $result');
      } else {
        Logger.log('❌ Cannot launch URL: $url');
        // Try alternative approach
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Logger.log('❌ Error launching URL: $e');
      // Fallback: try with different mode
      try {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        Logger.log('📱 Fallback launch successful');
      } catch (fallbackError) {
        Logger.log('❌ Fallback launch also failed: $fallbackError');
      }
    }
  }

  // Static method for splash screen to handle notifications
  static Future<void> handleInitialNotificationFromSplash() async {
    if (_initialMessage != null) {
      Logger.log('📱 Splash handling initial notification: ${_initialMessage!.messageId}');
      instance._handleNotificationTap(_initialMessage!);
      _initialMessage = null; // Clear after handling
    }
  }
} 