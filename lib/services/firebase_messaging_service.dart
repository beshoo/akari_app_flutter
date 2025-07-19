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

    if (message.notification != null) {
      Logger.log('📱 Notification: ${message.notification!.title} - ${message.notification!.body}');
      
      // Display the notification
      await _showNotification(
        title: message.notification!.title ?? 'Akari App',
        body: message.notification!.body ?? 'You have a new message',
        payload: _encodePayload(message.data),
      );
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
    Logger.log('📱 Notification tapped: ${response.payload}');
    // Handle notification tap - navigate to specific screen if needed
    if (response.payload != null) {
      final data = _decodePayload(response.payload!);
      _handleNotificationAction(data);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    Logger.log('📱 Notification opened app: ${message.messageId}');
    Logger.log('📱 Message data: ${message.data}');
    
    // Handle navigation based on message data
    _handleNotificationAction(message.data);
  }

  String _encodePayload(Map<String, dynamic> data) {
    // Convert map to a simple string format for local notifications
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  Map<String, dynamic> _decodePayload(String payload) {
    // Convert string back to map
    final Map<String, dynamic> data = {};
    final pairs = payload.split('&');
    for (final pair in pairs) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        data[parts[0]] = parts[1];
      }
    }
    return data;
  }

  void _handleNotificationAction(Map<String, dynamic> data) {
    Logger.log('📱 Handling notification action with data: $data');
    
    final notificationType = data['notification_type'];
    final content = data['content'];

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
          }
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
          }
        }
        break;
        
      case 'url':
        if (content != null) {
          Logger.log('📱 Opening URL: $content');
          _openUrl(content);
        }
        break;
        
      default:
        Logger.log('📱 Navigating to notifications page');
        Get.toNamed('/notifications');
        break;
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