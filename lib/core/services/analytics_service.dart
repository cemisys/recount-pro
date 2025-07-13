import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// Servicio centralizado para analytics, crashlytics y performance monitoring
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  static final FirebasePerformance _performance = FirebasePerformance.instance;
  
  static bool _initialized = false;
  
  /// Inicializar el servicio de analytics
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Configurar Crashlytics
      await _configureCrashlytics();
      
      // Configurar Analytics
      await _configureAnalytics();
      
      // Configurar Performance Monitoring
      await _configurePerformance();
      
      _initialized = true;
      Logger.info('Analytics service initialized successfully');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize analytics service', e, stackTrace);
    }
  }
  
  /// Configurar Firebase Crashlytics
  static Future<void> _configureCrashlytics() async {
    try {
      // Habilitar recolección automática de crashes solo en release
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      
      // Configurar información del usuario por defecto
      await _crashlytics.setCustomKey('app_version', '1.0.0');
      await _crashlytics.setCustomKey('platform', 'flutter');
      
      Logger.info('Crashlytics configured successfully');
    } catch (e, stackTrace) {
      Logger.error('Error configuring Crashlytics', e, stackTrace);
    }
  }
  
  /// Configurar Firebase Analytics
  static Future<void> _configureAnalytics() async {
    try {
      // Habilitar analytics solo en release
      await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
      
      Logger.info('Analytics configured successfully');
    } catch (e, stackTrace) {
      Logger.error('Error configuring Analytics', e, stackTrace);
    }
  }
  
  /// Configurar Firebase Performance
  static Future<void> _configurePerformance() async {
    try {
      // Habilitar performance monitoring solo en release
      await _performance.setPerformanceCollectionEnabled(!kDebugMode);
      
      Logger.info('Performance monitoring configured successfully');
    } catch (e, stackTrace) {
      Logger.error('Error configuring Performance monitoring', e, stackTrace);
    }
  }
  
  // ANALYTICS EVENTS
  
  /// Registrar evento de login
  static Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      Logger.debug('Analytics: Login event logged with method: $method');
    } catch (e, stackTrace) {
      Logger.error('Error logging login event', e, stackTrace);
    }
  }
  
  /// Registrar evento de logout
  static Future<void> logLogout() async {
    try {
      await _analytics.logEvent(name: 'logout');
      Logger.debug('Analytics: Logout event logged');
    } catch (e, stackTrace) {
      Logger.error('Error logging logout event', e, stackTrace);
    }
  }
  
  /// Registrar evento de conteo completado
  static Future<void> logConteoCompleted({
    required String vhId,
    required int productosContados,
    required bool tieneNovedades,
    required Duration tiempoConteo,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'conteo_completed',
        parameters: {
          'vh_id': vhId,
          'productos_contados': productosContados,
          'tiene_novedades': tieneNovedades,
          'tiempo_conteo_segundos': tiempoConteo.inSeconds,
        },
      );
      Logger.debug('Analytics: Conteo completed event logged for VH: $vhId');
    } catch (e, stackTrace) {
      Logger.error('Error logging conteo completed event', e, stackTrace);
    }
  }
  
  /// Registrar evento de novedad reportada
  static Future<void> logNovedadReported({
    required String tipo,
    required String sku,
    required int diferencia,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'novedad_reported',
        parameters: {
          'tipo': tipo,
          'sku': sku,
          'diferencia': diferencia,
        },
      );
      Logger.debug('Analytics: Novedad reported event logged: $tipo for SKU: $sku');
    } catch (e, stackTrace) {
      Logger.error('Error logging novedad reported event', e, stackTrace);
    }
  }
  
  /// Registrar evento de búsqueda de VH
  static Future<void> logVhSearch({
    required String placa,
    required bool found,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'vh_search',
        parameters: {
          'placa': placa,
          'found': found,
        },
      );
      Logger.debug('Analytics: VH search event logged for placa: $placa, found: $found');
    } catch (e, stackTrace) {
      Logger.error('Error logging VH search event', e, stackTrace);
    }
  }
  
  /// Registrar evento de cambio de tema
  static Future<void> logThemeChanged(String themeName) async {
    try {
      await _analytics.logEvent(
        name: 'theme_changed',
        parameters: {'theme': themeName},
      );
      Logger.debug('Analytics: Theme changed event logged: $themeName');
    } catch (e, stackTrace) {
      Logger.error('Error logging theme changed event', e, stackTrace);
    }
  }
  
  /// Registrar evento de error de usuario
  static Future<void> logUserError({
    required String errorType,
    required String screen,
    String? description,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'user_error',
        parameters: {
          'error_type': errorType,
          'screen': screen,
          if (description != null) 'description': description,
        },
      );
      Logger.debug('Analytics: User error event logged: $errorType on $screen');
    } catch (e, stackTrace) {
      Logger.error('Error logging user error event', e, stackTrace);
    }
  }
  
  /// Registrar navegación entre pantallas
  static Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
      Logger.debug('Analytics: Screen view logged: $screenName');
    } catch (e, stackTrace) {
      Logger.error('Error logging screen view', e, stackTrace);
    }
  }
  
  // USER PROPERTIES
  
  /// Establecer propiedades del usuario
  static Future<void> setUserProperties({
    required String userId,
    required String userRole,
    String? userName,
  }) async {
    try {
      await _analytics.setUserId(id: userId);
      await _analytics.setUserProperty(name: 'user_role', value: userRole);
      if (userName != null) {
        await _analytics.setUserProperty(name: 'user_name', value: userName);
      }
      
      // También configurar en Crashlytics
      await _crashlytics.setUserIdentifier(userId);
      await _crashlytics.setCustomKey('user_role', userRole);
      if (userName != null) {
        await _crashlytics.setCustomKey('user_name', userName);
      }
      
      Logger.debug('Analytics: User properties set for user: $userId');
    } catch (e, stackTrace) {
      Logger.error('Error setting user properties', e, stackTrace);
    }
  }
  
  /// Limpiar propiedades del usuario (al hacer logout)
  static Future<void> clearUserProperties() async {
    try {
      await _analytics.setUserId(id: null);
      await _crashlytics.setUserIdentifier('');
      Logger.debug('Analytics: User properties cleared');
    } catch (e, stackTrace) {
      Logger.error('Error clearing user properties', e, stackTrace);
    }
  }
  
  // CRASHLYTICS
  
  /// Reportar error no fatal
  static Future<void> recordError({
    required dynamic exception,
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? customKeys,
    bool fatal = false,
  }) async {
    try {
      // Agregar claves personalizadas si se proporcionan
      if (customKeys != null) {
        for (final entry in customKeys.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value);
        }
      }
      
      await _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
      
      Logger.debug('Crashlytics: Error recorded - ${exception.toString()}');
    } catch (e, stackTrace) {
      Logger.error('Error recording crash', e, stackTrace);
    }
  }
  
  /// Registrar mensaje personalizado en Crashlytics
  static Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
      Logger.debug('Crashlytics: Message logged - $message');
    } catch (e, stackTrace) {
      Logger.error('Error logging message to Crashlytics', e, stackTrace);
    }
  }
  
  // PERFORMANCE MONITORING
  
  /// Crear trace personalizado para medir performance
  static Trace createTrace(String name) {
    return _performance.newTrace(name);
  }
  
  /// Medir tiempo de operación
  static Future<T> measureOperation<T>({
    required String operationName,
    required Future<T> Function() operation,
    Map<String, String>? attributes,
  }) async {
    final trace = createTrace(operationName);
    
    try {
      // Agregar atributos si se proporcionan
      if (attributes != null) {
        for (final entry in attributes.entries) {
          trace.putAttribute(entry.key, entry.value);
        }
      }
      
      await trace.start();
      final result = await operation();
      await trace.stop();
      
      Logger.debug('Performance: Operation "$operationName" measured');
      return result;
    } catch (e, stackTrace) {
      await trace.stop();
      Logger.error('Error measuring operation: $operationName', e, stackTrace);
      rethrow;
    }
  }
  
  // UTILIDADES
  
  /// Verificar si el servicio está inicializado
  static bool get isInitialized => _initialized;
  
  /// Obtener instancia de Analytics (para uso avanzado)
  static FirebaseAnalytics get analytics => _analytics;
  
  /// Obtener instancia de Crashlytics (para uso avanzado)
  static FirebaseCrashlytics get crashlytics => _crashlytics;
  
  /// Obtener instancia de Performance (para uso avanzado)
  static FirebasePerformance get performance => _performance;
}
