import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar las preferencias de actualización
class UpdatePreferencesService {
  static const String _autoUpdateEnabledKey = 'auto_update_enabled';
  static const String _lastUpdateCheckKey = 'last_update_check';
  static const String _skipVersionKey = 'skip_version';

  /// Verificar si la verificación automática está habilitada
  static Future<bool> isAutoUpdateEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_autoUpdateEnabledKey) ?? true; // Por defecto habilitado
    } catch (e) {
      print('❌ [UPDATE_PREFS] Error obteniendo auto-update enabled: $e');
      return true; // Fallback a habilitado
    }
  }

  /// Habilitar o deshabilitar verificación automática
  static Future<void> setAutoUpdateEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoUpdateEnabledKey, enabled);
      print('✅ [UPDATE_PREFS] Auto-update ${enabled ? 'habilitado' : 'deshabilitado'}');
    } catch (e) {
      print('❌ [UPDATE_PREFS] Error guardando auto-update enabled: $e');
    }
  }

  /// Obtener la fecha de la última verificación
  static Future<DateTime?> getLastUpdateCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastUpdateCheckKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      print('❌ [UPDATE_PREFS] Error obteniendo última verificación: $e');
      return null;
    }
  }

  /// Guardar la fecha de la última verificación
  static Future<void> setLastUpdateCheck(DateTime dateTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastUpdateCheckKey, dateTime.millisecondsSinceEpoch);
      print('✅ [UPDATE_PREFS] Última verificación guardada: ${dateTime.toIso8601String()}');
    } catch (e) {
      print('❌ [UPDATE_PREFS] Error guardando última verificación: $e');
    }
  }

  /// Obtener versión que el usuario decidió omitir
  static Future<String?> getSkippedVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_skipVersionKey);
    } catch (e) {
      print('❌ [UPDATE_PREFS] Error obteniendo versión omitida: $e');
      return null;
    }
  }

  /// Marcar una versión como omitida
  static Future<void> setSkippedVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_skipVersionKey, version);
      print('✅ [UPDATE_PREFS] Versión $version marcada como omitida');
    } catch (e) {
      print('❌ [UPDATE_PREFS] Error guardando versión omitida: $e');
    }
  }

  /// Limpiar versión omitida
  static Future<void> clearSkippedVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_skipVersionKey);
      print('✅ [UPDATE_PREFS] Versión omitida limpiada');
    } catch (e) {
      print('❌ [UPDATE_PREFS] Error limpiando versión omitida: $e');
    }
  }

  /// Verificar si debe mostrar actualización (considerando versión omitida)
  static Future<bool> shouldShowUpdate(String version) async {
    try {
      final skippedVersion = await getSkippedVersion();
      if (skippedVersion != null && skippedVersion == version) {
        print('⚠️ [UPDATE_PREFS] Versión $version fue omitida por el usuario');
        return false;
      }
      return true;
    } catch (e) {
      print('❌ [UPDATE_PREFS] Error verificando si mostrar actualización: $e');
      return true; // Fallback a mostrar
    }
  }

  /// Verificar si es tiempo de verificar actualizaciones (evitar spam)
  static Future<bool> shouldCheckForUpdates({Duration cooldown = const Duration(hours: 6)}) async {
    try {
      final lastCheck = await getLastUpdateCheck();
      if (lastCheck == null) {
        return true; // Primera vez, verificar
      }
      
      final now = DateTime.now();
      final timeSinceLastCheck = now.difference(lastCheck);
      
      if (timeSinceLastCheck >= cooldown) {
        print('✅ [UPDATE_PREFS] Es tiempo de verificar actualizaciones (${timeSinceLastCheck.inHours}h desde última verificación)');
        return true;
      } else {
        print('⚠️ [UPDATE_PREFS] Muy pronto para verificar actualizaciones (${timeSinceLastCheck.inMinutes}min desde última verificación)');
        return false;
      }
    } catch (e) {
      print('❌ [UPDATE_PREFS] Error verificando cooldown: $e');
      return true; // Fallback a verificar
    }
  }

  /// Obtener resumen de configuración
  static Future<Map<String, dynamic>> getConfigSummary() async {
    try {
      return {
        'autoUpdateEnabled': await isAutoUpdateEnabled(),
        'lastUpdateCheck': await getLastUpdateCheck(),
        'skippedVersion': await getSkippedVersion(),
      };
    } catch (e) {
      print('❌ [UPDATE_PREFS] Error obteniendo resumen de configuración: $e');
      return {
        'autoUpdateEnabled': true,
        'lastUpdateCheck': null,
        'skippedVersion': null,
      };
    }
  }
}
