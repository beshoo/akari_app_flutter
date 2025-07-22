import 'package:flutter/foundation.dart';

class NotificationStore extends ChangeNotifier {
  int _notificationCount = 0;

  int get notificationCount => _notificationCount;

  void setNotificationCount(int count) {
    _notificationCount = count;
    notifyListeners();
  }

  void increment() {
    _notificationCount++;
    notifyListeners();
  }

  void clear() {
    _notificationCount = 0;
    notifyListeners();
  }
} 