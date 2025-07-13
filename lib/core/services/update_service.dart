import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

/// Servicio para manejar actualizaciones de la aplicación usando Firebase Remote Config
class UpdateService {
  static FirebaseRemoteConfig? _remoteConfig;
  static bool _initialized = false;

  /// Inicializar Firebase Remote Config
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      print('🔄 [UPDATE_SERVICE] Inicializando Remote Config...');

      _remoteConfig = FirebaseRemoteConfig.instance;

      // Configurar settings con manejo de errores
      try {
        await _remoteConfig!.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(seconds: 10),
            minimumFetchInterval: Duration.zero, // Para desarrollo, permitir fetch inmediato
          ),
        );
        print('✅ [UPDATE_SERVICE] Settings configurados');
      } catch (settingsError) {
        print('⚠️ [UPDATE_SERVICE] Error configurando settings: $settingsError');
      }

      // Valores por defecto (fallback)
      try {
        await _remoteConfig!.setDefaults({
          'latest_app_version': '1.0.0',
          'minimum_required_version': '1.0.0',
          'update_message': 'Nueva versión disponible con mejoras de rendimiento',
          'force_update': false,
          'update_url_android': 'https://github.com/tu-usuario/recount-pro/releases/latest',
          'update_url_web': 'https://tu-sitio-web.com/descargas',
          'update_enabled': true,
          'changelog': '• Mejoras de rendimiento\n• Corrección de errores\n• Nueva funcionalidad',
        });
        print('✅ [UPDATE_SERVICE] Valores por defecto configurados');
      } catch (defaultsError) {
        print('⚠️ [UPDATE_SERVICE] Error configurando defaults: $defaultsError');
      }

      _initialized = true;
      print('✅ [UPDATE_SERVICE] Remote Config inicializado correctamente');
    } catch (e) {
      print('❌ [UPDATE_SERVICE] Error inicializando Remote Config: $e');
      // Marcar como inicializado para evitar reintentos infinitos
      _initialized = true;
    }
  }

  /// Verificar si hay actualizaciones disponibles
  static Future<UpdateInfo> checkForUpdates() async {
    try {
      print('🔍 [UPDATE_SERVICE] Verificando actualizaciones...');

      // 1. Obtener versión actual de la app
      final currentVersion = await getCurrentVersion();
      print('📱 [UPDATE_SERVICE] Versión actual: $currentVersion');

      // 2. Intentar usar Remote Config si está disponible, sino usar valores por defecto
      String latestVersion = '1.0.1'; // Simular nueva versión disponible
      String minimumVersion = '1.0.0';
      String updateMessage = 'Nueva versión disponible con mejoras de rendimiento y corrección de errores';
      bool forceUpdate = false;
      String changelog = '• Mejoras de rendimiento\n• Corrección de errores menores\n• Nueva funcionalidad de métricas\n• Optimización de la interfaz';
      bool updateEnabled = true;

      // Intentar obtener valores de Remote Config si está disponible
      if (_initialized && _remoteConfig != null) {
        try {
          await _remoteConfig!.fetchAndActivate();

          updateEnabled = _safeGetBool('update_enabled', true);
          latestVersion = _safeGetString('latest_app_version', '1.0.1');
          minimumVersion = _safeGetString('minimum_required_version', '1.0.0');
          updateMessage = _safeGetString('update_message', updateMessage);
          forceUpdate = _safeGetBool('force_update', false);
          changelog = _safeGetString('changelog', changelog);

          print('✅ [UPDATE_SERVICE] Usando configuración de Remote Config');
        } catch (remoteError) {
          print('⚠️ [UPDATE_SERVICE] Error con Remote Config, usando valores por defecto: $remoteError');
        }
      } else {
        print('⚠️ [UPDATE_SERVICE] Remote Config no disponible, usando valores por defecto');
      }

      if (!updateEnabled) {
        print('⚠️ [UPDATE_SERVICE] Verificación de actualizaciones deshabilitada');
        return UpdateInfo.noUpdate(currentVersion);
      }

      print('🌐 [UPDATE_SERVICE] Versión más reciente: $latestVersion');
      print('⚡ [UPDATE_SERVICE] Versión mínima requerida: $minimumVersion');

      // 3. Comparar versiones
      final hasUpdate = _isNewerVersion(latestVersion, currentVersion);
      final isForceUpdate = _isNewerVersion(minimumVersion, currentVersion) || forceUpdate;

      // 4. Obtener URL de actualización según plataforma
      final updateUrl = _getUpdateUrl();

      print('📊 [UPDATE_SERVICE] Resultado: hasUpdate=$hasUpdate, isForceUpdate=$isForceUpdate');

      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        minimumVersion: minimumVersion,
        hasUpdate: hasUpdate,
        isForceUpdate: isForceUpdate,
        updateMessage: updateMessage,
        updateUrl: updateUrl,
        changelog: changelog,
      );

    } catch (e) {
      print('❌ [UPDATE_SERVICE] Error verificando actualizaciones: $e');
      final currentVersion = await getCurrentVersion();
      return UpdateInfo.error(currentVersion, e.toString());
    }
  }

  /// Comparar si una versión es más nueva que otra
  static bool _isNewerVersion(String newVersion, String currentVersion) {
    try {
      final newParts = newVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();
      
      // Asegurar que ambas listas tengan 3 elementos (major.minor.patch)
      while (newParts.length < 3) {
        newParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      
      // Comparar major.minor.patch
      for (int i = 0; i < 3; i++) {
        if (newParts[i] > currentParts[i]) return true;
        if (newParts[i] < currentParts[i]) return false;
      }
      
      return false; // Son iguales
    } catch (e) {
      print('❌ [UPDATE_SERVICE] Error comparando versiones: $e');
      return false;
    }
  }

  /// Obtener URL de actualización según la plataforma
  static String _getUpdateUrl() {
    try {
      if (kIsWeb) {
        // Para web, usar URL específica de web
        return _safeGetString('update_url_web', 'https://tu-sitio-web.com/descargas');
      } else {
        // Para móviles (Android/iOS), usar URL de Android por defecto
        return _safeGetString('update_url_android', 'https://github.com/cemisys/recount-pro/releases/latest');
      }
    } catch (e) {
      print('❌ [UPDATE_SERVICE] Error obteniendo URL: $e');
      return 'https://github.com/tu-usuario/recount-pro/releases/latest';
    }
  }

  /// Abrir URL de actualización
  static Future<void> openUpdateUrl(String url) async {
    try {
      print('🔗 [UPDATE_SERVICE] Abriendo URL: $url');
      
      if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        print('✅ [UPDATE_SERVICE] URL abierta correctamente');
      } else {
        print('❌ [UPDATE_SERVICE] No se puede abrir URL: $url');
      }
    } catch (e) {
      print('❌ [UPDATE_SERVICE] Error abriendo URL: $e');
    }
  }

  /// Obtener información de la versión actual
  static Future<String> getCurrentVersion() async {
    try {
      if (kIsWeb) {
        // Para web, usar versión hardcodeada o desde variables de entorno
        return '1.0.0'; // Cambiar por la versión real de tu app
      } else {
        final packageInfo = await PackageInfo.fromPlatform();
        return packageInfo.version;
      }
    } catch (e) {
      print('❌ [UPDATE_SERVICE] Error obteniendo versión actual: $e');
      return '1.0.0';
    }
  }

  /// Verificar si Remote Config está inicializado
  static bool get isInitialized => _initialized;

  /// Obtener string de Remote Config de forma segura
  static String _safeGetString(String key, String defaultValue) {
    try {
      if (_remoteConfig != null) {
        return _remoteConfig!.getString(key);
      }
    } catch (e) {
      print('⚠️ [UPDATE_SERVICE] Error obteniendo $key: $e');
    }
    return defaultValue;
  }

  /// Obtener bool de Remote Config de forma segura
  static bool _safeGetBool(String key, bool defaultValue) {
    try {
      if (_remoteConfig != null) {
        return _remoteConfig!.getBool(key);
      }
    } catch (e) {
      print('⚠️ [UPDATE_SERVICE] Error obteniendo $key: $e');
    }
    return defaultValue;
  }
}

/// Clase para encapsular información de actualización
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String minimumVersion;
  final bool hasUpdate;
  final bool isForceUpdate;
  final String updateMessage;
  final String updateUrl;
  final String changelog;
  final String? error;
  
  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.minimumVersion,
    required this.hasUpdate,
    required this.isForceUpdate,
    required this.updateMessage,
    required this.updateUrl,
    required this.changelog,
    this.error,
  });
  
  /// Constructor para cuando no hay actualización
  factory UpdateInfo.noUpdate(String currentVersion) {
    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      minimumVersion: currentVersion,
      hasUpdate: false,
      isForceUpdate: false,
      updateMessage: 'Tu aplicación está actualizada',
      updateUrl: '',
      changelog: '',
    );
  }
  
  /// Constructor para errores
  factory UpdateInfo.error(String currentVersion, String error) {
    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      minimumVersion: currentVersion,
      hasUpdate: false,
      isForceUpdate: false,
      updateMessage: 'Error verificando actualizaciones',
      updateUrl: '',
      changelog: '',
      error: error,
    );
  }
  
  bool get hasError => error != null;
  
  @override
  String toString() {
    return 'UpdateInfo(current: $currentVersion, latest: $latestVersion, hasUpdate: $hasUpdate, isForce: $isForceUpdate)';
  }
}
