import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Servicio para gestionar el tema de la aplicación
class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  static const String _systemThemeKey = 'follow_system_theme';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _followSystemTheme = true;
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;
  bool get followSystemTheme => _followSystemTheme;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Inicializar el servicio de temas
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadThemePreferences();
      Logger.info('Theme service initialized. Current mode: ${_themeMode.name}');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize theme service', e, stackTrace);
    }
  }

  /// Cargar preferencias de tema guardadas
  Future<void> _loadThemePreferences() async {
    try {
      final savedThemeIndex = _prefs?.getInt(_themeKey);
      final savedFollowSystem = _prefs?.getBool(_systemThemeKey) ?? true;

      _followSystemTheme = savedFollowSystem;

      if (savedThemeIndex != null && savedThemeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[savedThemeIndex];
      } else {
        _themeMode = ThemeMode.system;
      }

      Logger.debug('Theme preferences loaded: mode=${_themeMode.name}, followSystem=$_followSystemTheme');
    } catch (e, stackTrace) {
      Logger.error('Error loading theme preferences', e, stackTrace);
      _themeMode = ThemeMode.system;
      _followSystemTheme = true;
    }
  }

  /// Guardar preferencias de tema
  Future<void> _saveThemePreferences() async {
    try {
      await _prefs?.setInt(_themeKey, _themeMode.index);
      await _prefs?.setBool(_systemThemeKey, _followSystemTheme);
      Logger.debug('Theme preferences saved: mode=${_themeMode.name}, followSystem=$_followSystemTheme');
    } catch (e, stackTrace) {
      Logger.error('Error saving theme preferences', e, stackTrace);
    }
  }

  /// Cambiar a tema claro
  Future<void> setLightTheme() async {
    if (_themeMode != ThemeMode.light) {
      _themeMode = ThemeMode.light;
      _followSystemTheme = false;
      await _saveThemePreferences();
      await _updateSystemUI();
      notifyListeners();
      Logger.info('Theme changed to light mode');
    }
  }

  /// Cambiar a tema oscuro
  Future<void> setDarkTheme() async {
    if (_themeMode != ThemeMode.dark) {
      _themeMode = ThemeMode.dark;
      _followSystemTheme = false;
      await _saveThemePreferences();
      await _updateSystemUI();
      notifyListeners();
      Logger.info('Theme changed to dark mode');
    }
  }

  /// Seguir el tema del sistema
  Future<void> setSystemTheme() async {
    if (_themeMode != ThemeMode.system || !_followSystemTheme) {
      _themeMode = ThemeMode.system;
      _followSystemTheme = true;
      await _saveThemePreferences();
      await _updateSystemUI();
      notifyListeners();
      Logger.info('Theme changed to system mode');
    }
  }

  /// Alternar entre tema claro y oscuro
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setDarkTheme();
    } else {
      await setLightTheme();
    }
  }

  /// Actualizar la UI del sistema según el tema actual
  Future<void> _updateSystemUI() async {
    try {
      SystemUiOverlayStyle overlayStyle;
      
      switch (_themeMode) {
        case ThemeMode.light:
          overlayStyle = SystemUiOverlayStyle.dark;
          break;
        case ThemeMode.dark:
          overlayStyle = SystemUiOverlayStyle.light;
          break;
        case ThemeMode.system:
          // En modo sistema, usar el estilo apropiado según la hora o configuración del sistema
          final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
          overlayStyle = brightness == Brightness.dark 
              ? SystemUiOverlayStyle.light 
              : SystemUiOverlayStyle.dark;
          break;
      }

      SystemChrome.setSystemUIOverlayStyle(overlayStyle);
    } catch (e, stackTrace) {
      Logger.error('Error updating system UI', e, stackTrace);
    }
  }

  /// Obtener el brillo actual basado en el tema y el sistema
  Brightness getCurrentBrightness(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }

  /// Verificar si el tema actual es oscuro
  bool isDarkTheme(BuildContext context) {
    return getCurrentBrightness(context) == Brightness.dark;
  }

  /// Obtener el nombre del tema actual para mostrar en UI
  String getThemeName() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  /// Obtener el icono del tema actual
  IconData getThemeIcon() {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  /// Obtener lista de temas disponibles para selector
  List<ThemeOption> getAvailableThemes() {
    return [
      const ThemeOption(
        mode: ThemeMode.system,
        name: 'Sistema',
        description: 'Seguir configuración del sistema',
        icon: Icons.brightness_auto,
      ),
      const ThemeOption(
        mode: ThemeMode.light,
        name: 'Claro',
        description: 'Tema claro siempre',
        icon: Icons.light_mode,
      ),
      const ThemeOption(
        mode: ThemeMode.dark,
        name: 'Oscuro',
        description: 'Tema oscuro siempre',
        icon: Icons.dark_mode,
      ),
    ];
  }

  /// Aplicar tema específico
  Future<void> setTheme(ThemeMode mode) async {
    switch (mode) {
      case ThemeMode.light:
        await setLightTheme();
        break;
      case ThemeMode.dark:
        await setDarkTheme();
        break;
      case ThemeMode.system:
        await setSystemTheme();
        break;
    }
  }

  /// Resetear a configuración por defecto
  Future<void> resetToDefault() async {
    await setSystemTheme();
  }

  /// Obtener estadísticas de uso del tema
  Map<String, dynamic> getThemeStats() {
    return {
      'currentTheme': _themeMode.name,
      'followSystemTheme': _followSystemTheme,
      'isDarkMode': isDarkMode,
      'isLightMode': isLightMode,
      'isSystemMode': isSystemMode,
    };
  }
}

/// Clase para representar una opción de tema
class ThemeOption {
  final ThemeMode mode;
  final String name;
  final String description;
  final IconData icon;

  const ThemeOption({
    required this.mode,
    required this.name,
    required this.description,
    required this.icon,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeOption && other.mode == mode;
  }

  @override
  int get hashCode => mode.hashCode;
}
