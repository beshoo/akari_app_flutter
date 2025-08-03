import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  // Notification channels
  static const String _chatChannelId = 'chat_notifications';
  static const String _chatChannelName = 'Chat Notifications';
  static const String _chatChannelDescription = 'Notifications for chat responses';

  // Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permissions
      final status = await Permission.notification.request();
      Logger.log('LocalNotificationService: Notification permission status: $status');

      // Initialize settings for Android
      const androidSettings = AndroidInitializationSettings('@drawable/notification_icon');
      
      // Initialize settings for iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialize settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      await _createNotificationChannel();

      _isInitialized = true;
      Logger.log('LocalNotificationService: Initialized successfully');
    } catch (e) {
      Logger.log('LocalNotificationService: Error initializing - $e');
    }
  }

  // Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      _chatChannelId,
      _chatChannelName,
      description: _chatChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Show chat response notification
  static Future<void> showChatResponseNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        _chatChannelId,
        _chatChannelName,
        channelDescription: _chatChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@drawable/notification_icon',
        color: Color(0xFFA88B67), // App theme color
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: payload,
      );

      Logger.log('LocalNotificationService: Chat notification shown - $title');
    } catch (e) {
      Logger.log('LocalNotificationService: Error showing notification - $e');
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    Logger.log('LocalNotificationService: Notification tapped - ${response.payload}');
    
    // The payload will contain the route to navigate to
    if (response.payload == 'chat') {
      // Navigate to chat page using GetX
      try {
        Get.toNamed('/chat');
        Logger.log('LocalNotificationService: Navigating to chat page');
      } catch (e) {
        Logger.log('LocalNotificationService: Error navigating to chat - $e');
      }
    }
  }

  // Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
    Logger.log('LocalNotificationService: All notifications cancelled');
  }

  // Cancel specific notification
  static Future<void> cancel(int id) async {
    await _notifications.cancel(id);
    Logger.log('LocalNotificationService: Notification cancelled - $id');
  }
} 