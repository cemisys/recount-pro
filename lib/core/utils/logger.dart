import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class Logger {
  static const String _appName = 'ReCount Pro';
  
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }
  
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }
  
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }
  
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }
  
  static void critical(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.critical, message, error, stackTrace);
  }
  
  static void _log(LogLevel level, String message, Object? error, StackTrace? stackTrace) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final levelStr = level.name.toUpperCase().padRight(8);
      
      String logMessage = '[$timestamp] [$_appName] [$levelStr] $message';
      
      if (error != null) {
        logMessage += '\nError: $error';
      }
      
      if (stackTrace != null) {
        logMessage += '\nStackTrace: $stackTrace';
      }
      
      // En producción, aquí se podría enviar a un servicio de logging
      // como Firebase Crashlytics, Sentry, etc.
      debugPrint(logMessage);
    }
  }
  
  // Método para logging de operaciones de Firebase
  static void firebaseOperation(String operation, String collection, [Map<String, dynamic>? data]) {
    info('Firebase $operation on $collection${data != null ? ' with data: $data' : ''}');
  }
  
  // Método para logging de autenticación
  static void auth(String action, String? userId) {
    info('Auth $action${userId != null ? ' for user: $userId' : ''}');
  }
  
  // Método para logging de navegación
  static void navigation(String from, String to) {
    debug('Navigation: $from -> $to');
  }
}
