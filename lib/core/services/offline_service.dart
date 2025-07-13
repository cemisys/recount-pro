import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'cache_service.dart';
import '../utils/logger.dart';
import '../exceptions/app_exceptions.dart';

/// Servicio para manejar funcionalidad offline
class OfflineService extends ChangeNotifier {
  static const String _pendingOperationsKey = 'pending_operations';
  static const String _offlineDataKey = 'offline_data';
  
  bool _isOnline = true;
  final List<PendingOperation> _pendingOperations = [];
  
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  List<PendingOperation> get pendingOperations => List.unmodifiable(_pendingOperations);
  int get pendingOperationsCount => _pendingOperations.length;

  /// Inicializar el servicio offline
  Future<void> initialize() async {
    try {
      // Verificar conectividad inicial
      await _checkConnectivity();
      
      // Escuchar cambios de conectividad
      Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
      
      // Cargar operaciones pendientes
      await _loadPendingOperations();
      
      Logger.info('Offline service initialized. Online: $_isOnline, Pending operations: ${_pendingOperations.length}');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize offline service', e, stackTrace);
    }
  }

  /// Verificar conectividad actual
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      _updateOnlineStatus(connectivityResults);
    } catch (e, stackTrace) {
      Logger.error('Error checking connectivity', e, stackTrace);
      _isOnline = false; // Asumir offline en caso de error
    }
  }

  /// Manejar cambios de conectividad
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _updateOnlineStatus(results);
  }

  /// Actualizar estado de conectividad
  void _updateOnlineStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.isNotEmpty && !results.every((result) => result == ConnectivityResult.none);

    if (wasOnline != _isOnline) {
      Logger.info('Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');
      notifyListeners();

      // Si volvemos a estar online, procesar operaciones pendientes
      if (_isOnline && _pendingOperations.isNotEmpty) {
        _processPendingOperations();
      }
    }
  }

  /// Agregar operación pendiente para cuando vuelva la conectividad
  Future<void> addPendingOperation(PendingOperation operation) async {
    try {
      _pendingOperations.add(operation);
      await _savePendingOperations();
      
      Logger.info('Pending operation added: ${operation.type}');
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.error('Error adding pending operation', e, stackTrace);
    }
  }

  /// Procesar operaciones pendientes cuando hay conectividad
  Future<void> _processPendingOperations() async {
    if (_pendingOperations.isEmpty || !_isOnline) return;

    Logger.info('Processing ${_pendingOperations.length} pending operations');
    
    final operationsToProcess = List<PendingOperation>.from(_pendingOperations);
    final processedOperations = <PendingOperation>[];

    for (final operation in operationsToProcess) {
      try {
        final success = await _processOperation(operation);
        if (success) {
          processedOperations.add(operation);
          Logger.info('Processed pending operation: ${operation.type}');
        } else {
          Logger.warning('Failed to process pending operation: ${operation.type}');
        }
      } catch (e, stackTrace) {
        Logger.error('Error processing pending operation: ${operation.type}', e, stackTrace);
      }
    }

    // Remover operaciones procesadas exitosamente
    for (final processed in processedOperations) {
      _pendingOperations.remove(processed);
    }

    if (processedOperations.isNotEmpty) {
      await _savePendingOperations();
      notifyListeners();
      Logger.info('Processed ${processedOperations.length} pending operations successfully');
    }
  }

  /// Procesar una operación específica
  Future<bool> _processOperation(PendingOperation operation) async {
    // Aquí se implementaría la lógica específica para cada tipo de operación
    // Por ahora, simulamos el procesamiento
    switch (operation.type) {
      case OperationType.saveConteo:
        return await _processSaveConteo(operation);
      case OperationType.updateEstadisticas:
        return await _processUpdateEstadisticas(operation);
      default:
        Logger.warning('Unknown operation type: ${operation.type}');
        return false;
    }
  }

  /// Procesar guardado de conteo pendiente
  Future<bool> _processSaveConteo(PendingOperation operation) async {
    try {
      // Aquí se llamaría al servicio real para guardar el conteo
      // Por ahora, simulamos éxito
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e, stackTrace) {
      Logger.error('Error processing save conteo operation', e, stackTrace);
      return false;
    }
  }

  /// Procesar actualización de estadísticas pendiente
  Future<bool> _processUpdateEstadisticas(PendingOperation operation) async {
    try {
      // Aquí se llamaría al servicio real para actualizar estadísticas
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    } catch (e, stackTrace) {
      Logger.error('Error processing update estadisticas operation', e, stackTrace);
      return false;
    }
  }

  /// Guardar operaciones pendientes en caché
  Future<void> _savePendingOperations() async {
    try {
      final operationsJson = _pendingOperations
          .map((op) => op.toMap())
          .toList();
      
      await CacheService.set(_pendingOperationsKey, operationsJson);
    } catch (e, stackTrace) {
      Logger.error('Error saving pending operations', e, stackTrace);
    }
  }

  /// Cargar operaciones pendientes desde caché
  Future<void> _loadPendingOperations() async {
    try {
      final operationsData = await CacheService.get<List<dynamic>>(_pendingOperationsKey);
      
      if (operationsData != null) {
        _pendingOperations.clear();
        for (final opData in operationsData) {
          try {
            final operation = PendingOperation.fromMap(opData as Map<String, dynamic>);
            _pendingOperations.add(operation);
          } catch (e) {
            Logger.warning('Failed to parse pending operation: $e');
          }
        }
        
        Logger.info('Loaded ${_pendingOperations.length} pending operations from cache');
      }
    } catch (e, stackTrace) {
      Logger.error('Error loading pending operations', e, stackTrace);
    }
  }

  /// Limpiar operaciones pendientes
  Future<void> clearPendingOperations() async {
    try {
      _pendingOperations.clear();
      await CacheService.remove(_pendingOperationsKey);
      notifyListeners();
      Logger.info('Pending operations cleared');
    } catch (e, stackTrace) {
      Logger.error('Error clearing pending operations', e, stackTrace);
    }
  }

  /// Forzar procesamiento de operaciones pendientes
  Future<void> forceSyncPendingOperations() async {
    if (_isOnline) {
      await _processPendingOperations();
    } else {
      throw NetworkException.noConnection();
    }
  }

  /// Obtener datos offline para una clave específica
  Future<T?> getOfflineData<T>(String key) async {
    try {
      final offlineData = await CacheService.get<Map<String, dynamic>>(_offlineDataKey) ?? {};
      return offlineData[key] as T?;
    } catch (e, stackTrace) {
      Logger.error('Error getting offline data for key: $key', e, stackTrace);
      return null;
    }
  }

  /// Guardar datos offline
  Future<void> saveOfflineData(String key, dynamic data) async {
    try {
      final offlineData = await CacheService.get<Map<String, dynamic>>(_offlineDataKey) ?? {};
      offlineData[key] = data;
      await CacheService.set(_offlineDataKey, offlineData);
      Logger.debug('Offline data saved for key: $key');
    } catch (e, stackTrace) {
      Logger.error('Error saving offline data for key: $key', e, stackTrace);
    }
  }
}

/// Tipos de operaciones que se pueden realizar offline
enum OperationType {
  saveConteo,
  updateEstadisticas,
  syncData,
}

/// Operación pendiente para procesar cuando haya conectividad
class PendingOperation {
  final String id;
  final OperationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;

  const PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  factory PendingOperation.fromMap(Map<String, dynamic> map) {
    return PendingOperation(
      id: map['id'] ?? '',
      type: OperationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => OperationType.syncData,
      ),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      retryCount: map['retryCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  PendingOperation copyWith({
    String? id,
    OperationType? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return PendingOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
