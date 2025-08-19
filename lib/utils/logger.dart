import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _tag = 'GoodFit';

  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? ':$tag' : ''}] DEBUG: $message');
    }
  }

  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? ':$tag' : ''}] INFO: $message');
    }
  }

  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? ':$tag' : ''}] WARNING: $message');
    }
  }

  static void error(String message, [String? tag, Object? error]) {
    if (kDebugMode) {
      print('[$_tag${tag != null ? ':$tag' : ''}] ERROR: $message');
      if (error != null) {
        print('[$_tag${tag != null ? ':$tag' : ''}] ERROR DETAILS: $error');
      }
    }
  }

  static void network(String endpoint, int statusCode, [String? details]) {
    if (kDebugMode) {
      print('[$_tag:Network] $endpoint -> $statusCode${details != null ? ' | $details' : ''}');
    }
  }
}