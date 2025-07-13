import 'package:flutter/foundation.dart';
import '../exceptions/app_exceptions.dart';
import '../utils/logger.dart';
import '../utils/error_handler.dart';

/// Estados de carga de la aplicación
enum LoadingState {
  idle,
  loading,
  success,
  error,
}

/// Servicio centralizado para manejar el estado de la aplicación
class AppStateService extends ChangeNotifier {
  // Estados de carga
  LoadingState _loadingState = LoadingState.idle;
  AppException? _lastError;
  String? _loadingMessage;

  // Estados específicos de funcionalidades
  bool _isAuthenticating = false;
  bool _isSavingConteo = false;
  bool _isLoadingVh = false;
  bool _isLoadingSkus = false;
  bool _isLoadingEstadisticas = false;

  // Getters para estados generales
  LoadingState get loadingState => _loadingState;
  AppException? get lastError => _lastError;
  String? get loadingMessage => _loadingMessage;
  bool get hasError => _lastError != null;
  bool get isLoading => _loadingState == LoadingState.loading;

  // Getters para estados específicos
  bool get isAuthenticating => _isAuthenticating;
  bool get isSavingConteo => _isSavingConteo;
  bool get isLoadingVh => _isLoadingVh;
  bool get isLoadingSkus => _isLoadingSkus;
  bool get isLoadingEstadisticas => _isLoadingEstadisticas;

  // Getter para mensaje de error amigable
  String? get errorMessage => _lastError != null 
      ? ErrorHandler.getUserFriendlyMessage(_lastError!) 
      : null;

  /// Establecer estado de carga general
  void setLoadingState(LoadingState state, {String? message}) {
    _loadingState = state;
    _loadingMessage = message;
    
    if (state != LoadingState.error) {
      _lastError = null;
    }
    
    Logger.debug('App state changed to: ${state.name}${message != null ? ' - $message' : ''}');
    notifyListeners();
  }

  /// Establecer estado de error
  void setError(AppException error) {
    _loadingState = LoadingState.error;
    _lastError = error;
    _loadingMessage = null;
    
    Logger.error('App state error: ${error.message}', error.originalError);
    notifyListeners();
  }

  /// Limpiar error
  void clearError() {
    _lastError = null;
    if (_loadingState == LoadingState.error) {
      _loadingState = LoadingState.idle;
    }
    Logger.debug('App state error cleared');
    notifyListeners();
  }

  /// Establecer estado de autenticación
  void setAuthenticating(bool isAuthenticating, {String? message}) {
    _isAuthenticating = isAuthenticating;
    if (isAuthenticating) {
      setLoadingState(LoadingState.loading, message: message ?? 'Autenticando...');
    } else if (_loadingState == LoadingState.loading && _loadingMessage?.contains('Autenticando') == true) {
      setLoadingState(LoadingState.idle);
    }
  }

  /// Establecer estado de guardado de conteo
  void setSavingConteo(bool isSaving, {String? message}) {
    _isSavingConteo = isSaving;
    if (isSaving) {
      setLoadingState(LoadingState.loading, message: message ?? 'Guardando conteo...');
    } else if (_loadingState == LoadingState.loading && _loadingMessage?.contains('conteo') == true) {
      setLoadingState(LoadingState.success);
    }
  }

  /// Establecer estado de carga de VH
  void setLoadingVh(bool isLoading, {String? message}) {
    _isLoadingVh = isLoading;
    if (isLoading) {
      setLoadingState(LoadingState.loading, message: message ?? 'Buscando VH...');
    } else if (_loadingState == LoadingState.loading && _loadingMessage?.contains('VH') == true) {
      setLoadingState(LoadingState.idle);
    }
  }

  /// Establecer estado de carga de SKUs
  void setLoadingSkus(bool isLoading, {String? message}) {
    _isLoadingSkus = isLoading;
    if (isLoading) {
      setLoadingState(LoadingState.loading, message: message ?? 'Cargando SKUs...');
    } else if (_loadingState == LoadingState.loading && _loadingMessage?.contains('SKU') == true) {
      setLoadingState(LoadingState.idle);
    }
  }

  /// Establecer estado de carga de estadísticas
  void setLoadingEstadisticas(bool isLoading, {String? message}) {
    _isLoadingEstadisticas = isLoading;
    if (isLoading) {
      setLoadingState(LoadingState.loading, message: message ?? 'Cargando estadísticas...');
    } else if (_loadingState == LoadingState.loading && _loadingMessage?.contains('estadísticas') == true) {
      setLoadingState(LoadingState.idle);
    }
  }

  /// Ejecutar una operación asíncrona con manejo de estado automático
  Future<T?> executeWithState<T>({
    required Future<T> Function() operation,
    required String loadingMessage,
    String? successMessage,
    bool showSuccess = false,
  }) async {
    try {
      setLoadingState(LoadingState.loading, message: loadingMessage);
      
      final result = await operation();
      
      if (showSuccess) {
        setLoadingState(LoadingState.success, message: successMessage);
        // Volver a idle después de un breve momento
        Future.delayed(const Duration(seconds: 1), () {
          if (_loadingState == LoadingState.success) {
            setLoadingState(LoadingState.idle);
          }
        });
      } else {
        setLoadingState(LoadingState.idle);
      }
      
      return result;
    } catch (e, stackTrace) {
      final appException = ErrorHandler.handleGenericError(e, stackTrace);
      setError(appException);
      return null;
    }
  }

  /// Reiniciar todos los estados
  void reset() {
    _loadingState = LoadingState.idle;
    _lastError = null;
    _loadingMessage = null;
    _isAuthenticating = false;
    _isSavingConteo = false;
    _isLoadingVh = false;
    _isLoadingSkus = false;
    _isLoadingEstadisticas = false;
    
    Logger.debug('App state reset');
    notifyListeners();
  }

  /// Verificar si se puede realizar una operación (no hay otra en curso)
  bool canPerformOperation() {
    return _loadingState != LoadingState.loading;
  }

  /// Obtener descripción del estado actual
  String getStateDescription() {
    switch (_loadingState) {
      case LoadingState.idle:
        return 'Listo';
      case LoadingState.loading:
        return _loadingMessage ?? 'Cargando...';
      case LoadingState.success:
        return _loadingMessage ?? 'Operación exitosa';
      case LoadingState.error:
        return errorMessage ?? 'Error';
    }
  }
}
