import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message, {String tag = 'APP'}) {
    dev.log(message, name: tag, level: 800);
  }

  static void warning(String message, {String tag = 'APP', Object? error}) {
    dev.log(message, name: tag, level: 900, error: error);
    if (kDebugMode) {
      debugPrint('⚠ [$tag] $message${error != null ? '\n  → $error' : ''}');
    }
  }

  static void error(
    String message, {
    String tag = 'APP',
    Object? error,
    StackTrace? stack,
  }) {
    dev.log(message, name: tag, level: 1000, error: error, stackTrace: stack);
    if (kDebugMode) {
      debugPrint('✖ [$tag] $message${error != null ? '\n  → $error' : ''}');
      if (stack != null) debugPrint(stack.toString());
    }
  }
}
