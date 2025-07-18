import 'package:firebase_messaging/firebase_messaging.dart';

import '../utils/logger.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService instance = FirebaseMessagingService._internal();

  factory FirebaseMessagingService() {
    return instance;
  }

  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _token;

  String? get fcmToken => _token;

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    _token = await _firebaseMessaging.getToken();
    Logger.log('Firebase Messaging Token: $_token');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Logger.log('Got a message whilst in the foreground!');
      Logger.log('Message data: ${message.data}');

      if (message.notification != null) {
        Logger.log('Message also contained a notification: ${message.notification}');
      }
    });
  }
} 