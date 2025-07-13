import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';
import '../utils/logger.dart';

/// Servicio para recopilar y gestionar métricas de la aplicación
class MetricsService extends ChangeNotifier {

  static const String _totalSessionsKey = 'total_sessions';
  static const String _totalConteoKey = 'total_conteos';
  static const String _totalErrorsKey = 'total_errors';
  static const String _lastUsedKey = 'last_used_date';
  
  SharedPreferences? _prefs;
  DateTime? _sessionStartTime;
  Timer? _sessionTimer;
  
  // Métricas de sesión actual
  int _currentSessionConteos = 0;
  int _currentSessionErrors = 0;
  int _currentSessionScreenViews = 0;
  Duration _currentSessionDuration = Duration.zero;
  
  // Métricas totales
  int _totalSessions = 0;
  int _totalConteos = 0;
  int _totalErrors = 0;
  DateTime? _lastUsedDate;
  
  // Getters para métricas actuales
  int get currentSessionConteos => _currentSessionConteos;
  int get currentSessionErrors => _currentSessionErrors;
  int get currentSessionScreenViews => _currentSessionScreenViews;
  Duration get currentSessionDuration => _currentSessionDuration;
  
  // Getters para métricas totales
  int get totalSessions => _totalSessions;
  int get totalConteos => _totalConteos;
  int get totalErrors => _totalErrors;
  DateTime? get lastUsedDate => _lastUsedDate;
  bool get isFirstSession => _totalSessions == 0;
  
  /// Inicializar el servicio de métricas
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadMetrics();
      await _startSession();
      Logger.info('Metrics service initialized successfully');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize metrics service', e, stackTrace);
    }
  }
  
  /// Cargar métricas guardadas
  Future<void> _loadMetrics() async {
    try {
      _totalSessions = _prefs?.getInt(_totalSessionsKey) ?? 0;
      _totalConteos = _prefs?.getInt(_totalConteoKey) ?? 0;
      _totalErrors = _prefs?.getInt(_totalErrorsKey) ?? 0;
      
      final lastUsedString = _prefs?.getString(_lastUsedKey);
      if (lastUsedString != null) {
        _lastUsedDate = DateTime.tryParse(lastUsedString);
      }
      
      Logger.debug('Metrics loaded: Sessions=$_totalSessions, Conteos=$_totalConteos, Errors=$_totalErrors');
    } catch (e, stackTrace) {
      Logger.error('Error loading metrics', e, stackTrace);
    }
  }
  
  /// Iniciar nueva sesión
  Future<void> _startSession() async {
    try {
      _sessionStartTime = DateTime.now();
      _totalSessions++;
      _lastUsedDate = _sessionStartTime;
      
      // Guardar métricas actualizadas
      await _saveMetrics();
      
      // Iniciar timer para actualizar duración de sesión
      _sessionTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _updateSessionDuration();
      });
      
      // Registrar en Analytics
      await AnalyticsService.logScreenView('session_start');
      
      Logger.info('Session started: #$_totalSessions');
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.error('Error starting session', e, stackTrace);
    }
  }
  
  /// Actualizar duración de sesión actual
  void _updateSessionDuration() {
    if (_sessionStartTime != null) {
      _currentSessionDuration = DateTime.now().difference(_sessionStartTime!);
      notifyListeners();
    }
  }
  
  /// Finalizar sesión actual
  Future<void> endSession() async {
    try {
      _sessionTimer?.cancel();
      _updateSessionDuration();
      
      // Registrar métricas de sesión en Analytics
      await AnalyticsService.logScreenView('session_end');
      
      Logger.info('Session ended. Duration: ${_currentSessionDuration.inMinutes} minutes');
      
      // Resetear métricas de sesión
      _currentSessionConteos = 0;
      _currentSessionErrors = 0;
      _currentSessionScreenViews = 0;
      _currentSessionDuration = Duration.zero;
      _sessionStartTime = null;
      
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.error('Error ending session', e, stackTrace);
    }
  }
  
  /// Registrar conteo completado
  Future<void> recordConteo({
    required String vhId,
    required int productosContados,
    required bool tieneNovedades,
    required Duration tiempoConteo,
  }) async {
    try {
      _currentSessionConteos++;
      _totalConteos++;
      
      await _saveMetrics();
      
      // Registrar en Analytics
      await AnalyticsService.logConteoCompleted(
        vhId: vhId,
        productosContados: productosContados,
        tieneNovedades: tieneNovedades,
        tiempoConteo: tiempoConteo,
      );
      
      Logger.debug('Conteo recorded: VH=$vhId, Products=$productosContados');
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.error('Error recording conteo', e, stackTrace);
    }
  }
  
  /// Registrar error
  Future<void> recordError({
    required String errorType,
    required String screen,
    String? description,
  }) async {
    try {
      _currentSessionErrors++;
      _totalErrors++;
      
      await _saveMetrics();
      
      // Registrar en Analytics
      await AnalyticsService.logUserError(
        errorType: errorType,
        screen: screen,
        description: description,
      );
      
      Logger.debug('Error recorded: $errorType on $screen');
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.error('Error recording error metric', e, stackTrace);
    }
  }
  
  /// Registrar vista de pantalla
  Future<void> recordScreenView(String screenName) async {
    try {
      _currentSessionScreenViews++;
      
      // Registrar en Analytics
      await AnalyticsService.logScreenView(screenName);
      
      Logger.debug('Screen view recorded: $screenName');
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.error('Error recording screen view', e, stackTrace);
    }
  }
  
  /// Guardar métricas en almacenamiento local
  Future<void> _saveMetrics() async {
    try {
      await _prefs?.setInt(_totalSessionsKey, _totalSessions);
      await _prefs?.setInt(_totalConteoKey, _totalConteos);
      await _prefs?.setInt(_totalErrorsKey, _totalErrors);
      
      if (_lastUsedDate != null) {
        await _prefs?.setString(_lastUsedKey, _lastUsedDate!.toIso8601String());
      }
    } catch (e, stackTrace) {
      Logger.error('Error saving metrics', e, stackTrace);
    }
  }
  
  /// Obtener resumen de métricas
  Map<String, dynamic> getMetricsSummary() {
    return {
      'session': {
        'current_session_duration_minutes': _currentSessionDuration.inMinutes,
        'current_session_conteos': _currentSessionConteos,
        'current_session_errors': _currentSessionErrors,
        'current_session_screen_views': _currentSessionScreenViews,
      },
      'totals': {
        'total_sessions': _totalSessions,
        'total_conteos': _totalConteos,
        'total_errors': _totalErrors,
        'last_used': _lastUsedDate?.toIso8601String(),
      },
      'calculated': {
        'average_conteos_per_session': _totalSessions > 0 ? _totalConteos / _totalSessions : 0,
        'error_rate': _totalConteos > 0 ? _totalErrors / _totalConteos : 0,
        'is_first_session': isFirstSession,
      },
    };
  }
  
  /// Obtener métricas para dashboard
  Map<String, dynamic> getDashboardMetrics() {
    final now = DateTime.now();
    final sessionMinutes = _currentSessionDuration.inMinutes;
    
    return {
      'session_info': {
        'duration': '${sessionMinutes}m',
        'conteos': _currentSessionConteos,
        'errors': _currentSessionErrors,
        'screens': _currentSessionScreenViews,
      },
      'productivity': {
        'conteos_per_hour': sessionMinutes > 0 ? (_currentSessionConteos * 60 / sessionMinutes).toStringAsFixed(1) : '0',
        'error_rate': _currentSessionConteos > 0 ? '${((_currentSessionErrors / _currentSessionConteos) * 100).toStringAsFixed(1)}%' : '0%',
      },
      'totals': {
        'total_sessions': _totalSessions,
        'total_conteos': _totalConteos,
        'days_since_first_use': _lastUsedDate != null ? now.difference(_lastUsedDate!).inDays : 0,
      },
    };
  }
  
  /// Resetear todas las métricas (para testing o reset de usuario)
  Future<void> resetMetrics() async {
    try {
      _currentSessionConteos = 0;
      _currentSessionErrors = 0;
      _currentSessionScreenViews = 0;
      _currentSessionDuration = Duration.zero;
      _totalSessions = 0;
      _totalConteos = 0;
      _totalErrors = 0;
      _lastUsedDate = null;
      
      // Limpiar almacenamiento
      await _prefs?.remove(_totalSessionsKey);
      await _prefs?.remove(_totalConteoKey);
      await _prefs?.remove(_totalErrorsKey);
      await _prefs?.remove(_lastUsedKey);
      
      Logger.info('All metrics reset');
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.error('Error resetting metrics', e, stackTrace);
    }
  }
  
  /// Exportar métricas para análisis
  Map<String, dynamic> exportMetrics() {
    return {
      'export_date': DateTime.now().toIso8601String(),
      'app_version': '1.0.0',
      'metrics': getMetricsSummary(),
    };
  }
  
  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
