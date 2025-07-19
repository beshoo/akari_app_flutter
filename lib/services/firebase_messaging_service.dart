import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/property_details_page.dart';
import '../utils/logger.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService instance = FirebaseMessagingService._internal();

  factory FirebaseMessagingService() {
    return instance;
  }

  FirebaseMessagingService._internal();

  // Make FirebaseMessaging lazy-loaded to avoid initialization issues
  FirebaseMessaging? _firebaseMessaging;
  FirebaseMessaging get _firebaseMessagingInstance {
    _firebaseMessaging ??= FirebaseMessaging.instance;
    return _firebaseMessaging!;
  }

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  String? _token;
  static RemoteMessage? _initialMessage; // Static for splash screen access
  
  // Option to handle notifications immediately in foreground (without showing notification)
  bool handleForegroundImmediately = false;

  String? get fcmToken => _token;
  static RemoteMessage? get initialMessage => _initialMessage;
  static void clearInitialMessage() => _initialMessage = null;
  
  // Check if Firebase is properly initialized
  bool get isInitialized => _firebaseMessaging != null;

  Future<void> initialize() async {
    try {
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

      // Initialize local notifications
      await _initializeLocalNotifications();

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
    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'akari_notifications', // Channel ID (matches manifest)
      'Akari Notifications', // Channel name
      description: 'Notifications from Akari App',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    Logger.log('📱 Got message in foreground: ${message.messageId}');
    Logger.log('📱 Message data: ${message.data}');

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
        title: message.notification!.title ?? 'Akari App',
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
    const androidDetails = AndroidNotificationDetails(
      'akari_notifications',
      'Akari Notifications',
      channelDescription: 'Notifications from Akari App',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xff633e3d),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    Logger.log('📱 Notification tapped with payload: ${response.payload}');
    
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final data = _decodePayload(response.payload!);
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