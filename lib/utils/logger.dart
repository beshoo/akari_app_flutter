import 'package:flutter/foundation.dart';

// A simple logger that only prints in debug mode.
// In release mode, all logs are ignored.
class Logger {
  // Log a message to the console.
  static void log(dynamic message) {
    if (!kReleaseMode) {
      debugPrint('[LOG]: $message');
    }
  }

  // Log an informational message.
  static void info(dynamic message) {
    if (!kReleaseMode) {
      debugPrint('ℹ️ [INFO]: $message');
    }
  }

  // Log a warning message.
  static void warn(dynamic message) {
    if (!kReleaseMode) {
      debugPrint('⚠️ [WARN]: $message');
    }
  }

  // Log an error message.
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (!kReleaseMode) {
      debugPrint('⛔ [ERROR]: $message');
      if (error != null) {
        debugPrint('  ➡️ Exception: $error');
      }
      if (stackTrace != null) {
        debugPrint('  ➡️ Stack Trace: $stackTrace');
      }
    }
  }
} 