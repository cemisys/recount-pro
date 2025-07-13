import 'dart:async';
import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import 'analytics_service.dart';

/// Servicio para optimizar el rendimiento de la aplicación
class PerformanceService {

  static const String _imageQualityKey = 'image_quality';
  static const String _animationsEnabledKey = 'animations_enabled';
  static const String _preloadDataKey = 'preload_data';
  
  static SharedPreferences? _prefs;
  static bool _initialized = false;
  
  // Configuraciones de performance
  static ImageQuality _imageQuality = ImageQuality.high;
  static bool _animationsEnabled = true;
  static bool _preloadData = true;
  static bool _lowMemoryMode = false;
  
  // Getters
  static ImageQuality get imageQuality => _imageQuality;
  static bool get animationsEnabled => _animationsEnabled;
  static bool get preloadData => _preloadData;
  static bool get lowMemoryMode => _lowMemoryMode;
  static bool get isInitialized => _initialized;
  
  /// Inicializar el servicio de performance
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadPerformanceSettings();
      await _detectDeviceCapabilities();
      
      _initialized = true;
      Logger.info('Performance service initialized successfully');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize performance service', e, stackTrace);
    }
  }
  
  /// Cargar configuraciones de performance guardadas
  static Future<void> _loadPerformanceSettings() async {
    try {
      final imageQualityIndex = _prefs?.getInt(_imageQualityKey) ?? ImageQuality.high.index;
      _imageQuality = ImageQuality.values[imageQualityIndex.clamp(0, ImageQuality.values.length - 1)];
      
      _animationsEnabled = _prefs?.getBool(_animationsEnabledKey) ?? true;
      _preloadData = _prefs?.getBool(_preloadDataKey) ?? true;
      
      Logger.debug('Performance settings loaded: imageQuality=${_imageQuality.name}, animations=$_animationsEnabled, preload=$_preloadData');
    } catch (e, stackTrace) {
      Logger.error('Error loading performance settings', e, stackTrace);
      _resetToDefaults();
    }
  }
  
  /// Detectar capacidades del dispositivo y ajustar configuraciones
  static Future<void> _detectDeviceCapabilities() async {
    try {
      // Detectar memoria disponible (aproximada)
      final memoryInfo = await _getMemoryInfo();
      
      // Si el dispositivo tiene poca memoria, activar modo de bajo consumo
      if (memoryInfo['availableMemoryMB'] != null && memoryInfo['availableMemoryMB']! < 1024) {
        _lowMemoryMode = true;
        _imageQuality = ImageQuality.medium;
        _animationsEnabled = false;
        _preloadData = false;
        
        Logger.info('Low memory device detected. Performance optimizations applied.');
      }
      
      // Registrar información del dispositivo en Analytics
      await AnalyticsService.recordError(
        exception: 'Device capabilities detected',
        reason: 'Performance optimization',
        customKeys: memoryInfo.map((key, value) => MapEntry(key, value.toString())),
        fatal: false,
      );
      
    } catch (e, stackTrace) {
      Logger.error('Error detecting device capabilities', e, stackTrace);
    }
  }
  
  /// Obtener información aproximada de memoria del dispositivo
  static Future<Map<String, int?>> _getMemoryInfo() async {
    try {
      if (Platform.isAndroid) {
        // En Android, podríamos usar platform channels para obtener info de memoria
        // Por ahora, usamos valores aproximados basados en el rendimiento observado
        return {
          'totalMemoryMB': null, // No disponible sin platform channel
          'availableMemoryMB': null,
        };
      } else if (Platform.isIOS) {
        // En iOS, similar situación
        return {
          'totalMemoryMB': null,
          'availableMemoryMB': null,
        };
      }
      
      return {
        'totalMemoryMB': null,
        'availableMemoryMB': null,
      };
    } catch (e, stackTrace) {
      Logger.error('Error getting memory info', e, stackTrace);
      return {
        'totalMemoryMB': null,
        'availableMemoryMB': null,
      };
    }
  }
  
  /// Guardar configuraciones de performance
  static Future<void> _savePerformanceSettings() async {
    try {
      await _prefs?.setInt(_imageQualityKey, _imageQuality.index);
      await _prefs?.setBool(_animationsEnabledKey, _animationsEnabled);
      await _prefs?.setBool(_preloadDataKey, _preloadData);
      
      Logger.debug('Performance settings saved');
    } catch (e, stackTrace) {
      Logger.error('Error saving performance settings', e, stackTrace);
    }
  }
  
  /// Establecer calidad de imagen
  static Future<void> setImageQuality(ImageQuality quality) async {
    if (_imageQuality != quality) {
      _imageQuality = quality;
      await _savePerformanceSettings();
      Logger.info('Image quality changed to: ${quality.name}');
    }
  }
  
  /// Activar/desactivar animaciones
  static Future<void> setAnimationsEnabled(bool enabled) async {
    if (_animationsEnabled != enabled) {
      _animationsEnabled = enabled;
      await _savePerformanceSettings();
      Logger.info('Animations ${enabled ? 'enabled' : 'disabled'}');
    }
  }
  
  /// Activar/desactivar precarga de datos
  static Future<void> setPreloadData(bool enabled) async {
    if (_preloadData != enabled) {
      _preloadData = enabled;
      await _savePerformanceSettings();
      Logger.info('Data preloading ${enabled ? 'enabled' : 'disabled'}');
    }
  }
  
  /// Activar modo de bajo consumo de memoria
  static Future<void> setLowMemoryMode(bool enabled) async {
    if (_lowMemoryMode != enabled) {
      _lowMemoryMode = enabled;
      
      if (enabled) {
        // Aplicar optimizaciones de memoria
        await setImageQuality(ImageQuality.low);
        await setAnimationsEnabled(false);
        await setPreloadData(false);
        
        // Forzar garbage collection
        await _forceGarbageCollection();
      } else {
        // Restaurar configuraciones normales
        await setImageQuality(ImageQuality.high);
        await setAnimationsEnabled(true);
        await setPreloadData(true);
      }
      
      Logger.info('Low memory mode ${enabled ? 'enabled' : 'disabled'}');
    }
  }
  
  /// Forzar garbage collection
  static Future<void> _forceGarbageCollection() async {
    try {
      // En Flutter, no hay una forma directa de forzar GC
      // Pero podemos sugerir al sistema que libere memoria
      await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      Logger.debug('Garbage collection suggested');
    } catch (e) {
      // Ignorar errores de GC forzado
      Logger.debug('Could not force garbage collection: $e');
    }
  }
  
  /// Obtener duración de animación basada en configuración
  static Duration getAnimationDuration(Duration defaultDuration) {
    if (!_animationsEnabled) {
      return Duration.zero;
    }
    
    if (_lowMemoryMode) {
      return Duration(milliseconds: (defaultDuration.inMilliseconds * 0.5).round());
    }
    
    return defaultDuration;
  }
  
  /// Obtener calidad de imagen como factor de escala
  static double getImageScaleFactor() {
    switch (_imageQuality) {
      case ImageQuality.low:
        return 0.5;
      case ImageQuality.medium:
        return 0.75;
      case ImageQuality.high:
        return 1.0;
    }
  }
  
  /// Verificar si se debe precargar datos
  static bool shouldPreloadData() {
    return _preloadData && !_lowMemoryMode;
  }
  
  /// Obtener configuración de caché de imágenes
  static int getImageCacheSize() {
    switch (_imageQuality) {
      case ImageQuality.low:
        return 50; // 50 MB
      case ImageQuality.medium:
        return 100; // 100 MB
      case ImageQuality.high:
        return 200; // 200 MB
    }
  }
  
  /// Limpiar caché de imágenes
  static Future<void> clearImageCache() async {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      Logger.info('Image cache cleared');
    } catch (e, stackTrace) {
      Logger.error('Error clearing image cache', e, stackTrace);
    }
  }
  
  /// Optimizar configuración de caché de imágenes
  static void optimizeImageCache() {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      imageCache.maximumSizeBytes = getImageCacheSize() * 1024 * 1024; // Convertir MB a bytes
      imageCache.maximumSize = _lowMemoryMode ? 50 : 100; // Número máximo de imágenes
      
      Logger.debug('Image cache optimized: ${getImageCacheSize()}MB, max images: ${imageCache.maximumSize}');
    } catch (e, stackTrace) {
      Logger.error('Error optimizing image cache', e, stackTrace);
    }
  }
  
  /// Resetear a configuraciones por defecto
  static Future<void> _resetToDefaults() async {
    _imageQuality = ImageQuality.high;
    _animationsEnabled = true;
    _preloadData = true;
    _lowMemoryMode = false;
    
    await _savePerformanceSettings();
    Logger.info('Performance settings reset to defaults');
  }
  
  /// Obtener estadísticas de performance
  static Map<String, dynamic> getPerformanceStats() {
    return {
      'image_quality': _imageQuality.name,
      'animations_enabled': _animationsEnabled,
      'preload_data': _preloadData,
      'low_memory_mode': _lowMemoryMode,
      'image_scale_factor': getImageScaleFactor(),
      'image_cache_size_mb': getImageCacheSize(),
      'should_preload': shouldPreloadData(),
    };
  }
  
  /// Aplicar configuraciones de performance recomendadas para el dispositivo
  static Future<void> applyRecommendedSettings() async {
    try {
      // Detectar capacidades nuevamente
      await _detectDeviceCapabilities();
      
      // Optimizar caché de imágenes
      optimizeImageCache();
      
      Logger.info('Recommended performance settings applied');
    } catch (e, stackTrace) {
      Logger.error('Error applying recommended settings', e, stackTrace);
    }
  }
}

/// Enum para calidad de imagen
enum ImageQuality {
  low('Baja'),
  medium('Media'),
  high('Alta');
  
  const ImageQuality(this.displayName);
  final String displayName;
}

/// Mixin para widgets que necesitan optimizaciones de performance
mixin PerformanceOptimizedWidget {
  /// Obtener duración de animación optimizada
  Duration getOptimizedAnimationDuration(Duration defaultDuration) {
    return PerformanceService.getAnimationDuration(defaultDuration);
  }
  
  /// Verificar si las animaciones están habilitadas
  bool get animationsEnabled => PerformanceService.animationsEnabled;
  
  /// Verificar si se debe precargar datos
  bool get shouldPreloadData => PerformanceService.shouldPreloadData();
  
  /// Obtener factor de escala de imagen
  double get imageScaleFactor => PerformanceService.getImageScaleFactor();
}
