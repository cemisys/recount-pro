import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Servicio de caché local para mejorar el rendimiento de la aplicación
class CacheService {
  static const String _keyPrefix = 'recount_pro_cache_';
  static const Duration _defaultTtl = Duration(hours: 1);
  
  // Claves de caché específicas
  static const String _skuListKey = '${_keyPrefix}sku_list';
  static const String _auxiliaresKey = '${_keyPrefix}auxiliares';
  static const String _vhProgramadosKey = '${_keyPrefix}vh_programados';
  static const String _estadisticasKey = '${_keyPrefix}estadisticas';
  
  static SharedPreferences? _prefs;
  
  /// Inicializar el servicio de caché
  static Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      Logger.info('Cache service initialized successfully');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize cache service', e, stackTrace);
    }
  }
  
  /// Verificar si el caché está inicializado
  static bool get isInitialized => _prefs != null;
  
  /// Guardar datos en caché con TTL
  static Future<bool> set<T>(
    String key, 
    T data, {
    Duration? ttl,
  }) async {
    if (!isInitialized) {
      Logger.warning('Cache service not initialized');
      return false;
    }
    
    try {
      final cacheKey = _keyPrefix + key;
      final expirationTime = DateTime.now().add(ttl ?? _defaultTtl);
      
      final cacheData = {
        'data': data,
        'expiration': expirationTime.millisecondsSinceEpoch,
        'type': T.toString(),
      };
      
      final jsonString = jsonEncode(cacheData);
      final success = await _prefs!.setString(cacheKey, jsonString);
      
      if (success) {
        Logger.debug('Data cached successfully: $key');
      } else {
        Logger.warning('Failed to cache data: $key');
      }
      
      return success;
    } catch (e, stackTrace) {
      Logger.error('Error caching data for key: $key', e, stackTrace);
      return false;
    }
  }
  
  /// Obtener datos del caché
  static Future<T?> get<T>(String key) async {
    if (!isInitialized) {
      Logger.warning('Cache service not initialized');
      return null;
    }
    
    try {
      final cacheKey = _keyPrefix + key;
      final jsonString = _prefs!.getString(cacheKey);
      
      if (jsonString == null) {
        Logger.debug('Cache miss for key: $key');
        return null;
      }
      
      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(
        cacheData['expiration'] as int,
      );
      
      // Verificar si el caché ha expirado
      if (DateTime.now().isAfter(expirationTime)) {
        Logger.debug('Cache expired for key: $key');
        await remove(key);
        return null;
      }
      
      Logger.debug('Cache hit for key: $key');
      return cacheData['data'] as T;
    } catch (e, stackTrace) {
      Logger.error('Error retrieving cached data for key: $key', e, stackTrace);
      await remove(key); // Limpiar caché corrupto
      return null;
    }
  }
  
  /// Verificar si existe un elemento en caché y no ha expirado
  static Future<bool> has(String key) async {
    if (!isInitialized) return false;
    
    try {
      final cacheKey = _keyPrefix + key;
      final jsonString = _prefs!.getString(cacheKey);
      
      if (jsonString == null) return false;
      
      final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(
        cacheData['expiration'] as int,
      );
      
      if (DateTime.now().isAfter(expirationTime)) {
        await remove(key);
        return false;
      }
      
      return true;
    } catch (e, stackTrace) {
      Logger.error('Error checking cache for key: $key', e, stackTrace);
      await remove(key);
      return false;
    }
  }
  
  /// Eliminar un elemento del caché
  static Future<bool> remove(String key) async {
    if (!isInitialized) return false;
    
    try {
      final cacheKey = _keyPrefix + key;
      final success = await _prefs!.remove(cacheKey);
      
      if (success) {
        Logger.debug('Cache entry removed: $key');
      }
      
      return success;
    } catch (e, stackTrace) {
      Logger.error('Error removing cache entry: $key', e, stackTrace);
      return false;
    }
  }
  
  /// Limpiar todo el caché de la aplicación
  static Future<void> clear() async {
    if (!isInitialized) return;
    
    try {
      final keys = _prefs!.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_keyPrefix));
      
      for (final key in cacheKeys) {
        await _prefs!.remove(key);
      }
      
      Logger.info('Cache cleared successfully');
    } catch (e, stackTrace) {
      Logger.error('Error clearing cache', e, stackTrace);
    }
  }
  
  /// Limpiar caché expirado
  static Future<void> clearExpired() async {
    if (!isInitialized) return;
    
    try {
      final keys = _prefs!.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_keyPrefix));
      int removedCount = 0;
      
      for (final cacheKey in cacheKeys) {
        try {
          final jsonString = _prefs!.getString(cacheKey);
          if (jsonString == null) continue;
          
          final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
          final expirationTime = DateTime.fromMillisecondsSinceEpoch(
            cacheData['expiration'] as int,
          );
          
          if (DateTime.now().isAfter(expirationTime)) {
            await _prefs!.remove(cacheKey);
            removedCount++;
          }
        } catch (e) {
          // Si hay error al parsear, eliminar la entrada corrupta
          await _prefs!.remove(cacheKey);
          removedCount++;
        }
      }
      
      Logger.info('Expired cache entries removed: $removedCount');
    } catch (e, stackTrace) {
      Logger.error('Error clearing expired cache', e, stackTrace);
    }
  }
  
  /// Obtener estadísticas del caché
  static Future<Map<String, dynamic>> getStats() async {
    if (!isInitialized) {
      return {
        'initialized': false,
        'totalEntries': 0,
        'expiredEntries': 0,
        'validEntries': 0,
      };
    }
    
    try {
      final keys = _prefs!.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_keyPrefix));
      
      int totalEntries = cacheKeys.length;
      int expiredEntries = 0;
      int validEntries = 0;
      
      for (final cacheKey in cacheKeys) {
        try {
          final jsonString = _prefs!.getString(cacheKey);
          if (jsonString == null) continue;
          
          final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
          final expirationTime = DateTime.fromMillisecondsSinceEpoch(
            cacheData['expiration'] as int,
          );
          
          if (DateTime.now().isAfter(expirationTime)) {
            expiredEntries++;
          } else {
            validEntries++;
          }
        } catch (e) {
          expiredEntries++;
        }
      }
      
      return {
        'initialized': true,
        'totalEntries': totalEntries,
        'expiredEntries': expiredEntries,
        'validEntries': validEntries,
      };
    } catch (e, stackTrace) {
      Logger.error('Error getting cache stats', e, stackTrace);
      return {
        'initialized': true,
        'totalEntries': 0,
        'expiredEntries': 0,
        'validEntries': 0,
        'error': e.toString(),
      };
    }
  }
  
  // Métodos específicos para datos de la aplicación
  
  /// Caché para lista de SKUs
  static Future<bool> cacheSkuList(List<Map<String, dynamic>> skus) async {
    return await set(_skuListKey, skus, ttl: const Duration(hours: 6));
  }
  
  static Future<List<Map<String, dynamic>>?> getCachedSkuList() async {
    final data = await get<List<dynamic>>(_skuListKey);
    return data?.cast<Map<String, dynamic>>();
  }
  
  /// Caché para auxiliares
  static Future<bool> cacheAuxiliares(List<Map<String, dynamic>> auxiliares) async {
    return await set(_auxiliaresKey, auxiliares, ttl: const Duration(hours: 12));
  }
  
  static Future<List<Map<String, dynamic>>?> getCachedAuxiliares() async {
    final data = await get<List<dynamic>>(_auxiliaresKey);
    return data?.cast<Map<String, dynamic>>();
  }
  
  /// Caché para VH programados del día
  static Future<bool> cacheVhProgramados(List<Map<String, dynamic>> vhProgramados) async {
    return await set(_vhProgramadosKey, vhProgramados, ttl: const Duration(hours: 2));
  }
  
  static Future<List<Map<String, dynamic>>?> getCachedVhProgramados() async {
    final data = await get<List<dynamic>>(_vhProgramadosKey);
    return data?.cast<Map<String, dynamic>>();
  }
  
  /// Caché para estadísticas del usuario
  static Future<bool> cacheEstadisticas(Map<String, dynamic> estadisticas) async {
    return await set(_estadisticasKey, estadisticas, ttl: const Duration(minutes: 30));
  }
  
  static Future<Map<String, dynamic>?> getCachedEstadisticas() async {
    final data = await get<Map<String, dynamic>>(_estadisticasKey);
    return data;
  }
}
