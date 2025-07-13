import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Servicio para gestionar la localización de la aplicación
class LocalizationService extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  static const String _followSystemKey = 'follow_system_locale';
  
  Locale _currentLocale = const Locale('es'); // Español por defecto
  bool _followSystemLocale = true;
  SharedPreferences? _prefs;
  
  // Locales soportados
  static const List<Locale> supportedLocales = [
    Locale('es'), // Español
    Locale('en'), // Inglés
  ];
  
  // Getters
  Locale get currentLocale => _currentLocale;
  bool get followSystemLocale => _followSystemLocale;
  bool get isSpanish => _currentLocale.languageCode == 'es';
  bool get isEnglish => _currentLocale.languageCode == 'en';
  
  /// Inicializar el servicio de localización
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadLocalePreferences();
      Logger.info('Localization service initialized. Current locale: ${_currentLocale.languageCode}');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize localization service', e, stackTrace);
    }
  }
  
  /// Cargar preferencias de localización guardadas
  Future<void> _loadLocalePreferences() async {
    try {
      final savedLocaleCode = _prefs?.getString(_localeKey);
      final savedFollowSystem = _prefs?.getBool(_followSystemKey) ?? true;
      
      _followSystemLocale = savedFollowSystem;
      
      if (savedLocaleCode != null && _isLocaleSupported(savedLocaleCode)) {
        _currentLocale = Locale(savedLocaleCode);
      } else {
        // Si no hay locale guardado o no es soportado, usar español por defecto
        _currentLocale = const Locale('es');
      }
      
      Logger.debug('Locale preferences loaded: ${_currentLocale.languageCode}, followSystem: $_followSystemLocale');
    } catch (e, stackTrace) {
      Logger.error('Error loading locale preferences', e, stackTrace);
      _currentLocale = const Locale('es');
      _followSystemLocale = true;
    }
  }
  
  /// Guardar preferencias de localización
  Future<void> _saveLocalePreferences() async {
    try {
      await _prefs?.setString(_localeKey, _currentLocale.languageCode);
      await _prefs?.setBool(_followSystemKey, _followSystemLocale);
      Logger.debug('Locale preferences saved: ${_currentLocale.languageCode}, followSystem: $_followSystemLocale');
    } catch (e, stackTrace) {
      Logger.error('Error saving locale preferences', e, stackTrace);
    }
  }
  
  /// Verificar si un locale es soportado
  bool _isLocaleSupported(String languageCode) {
    return supportedLocales.any((locale) => locale.languageCode == languageCode);
  }
  
  /// Cambiar a español
  Future<void> setSpanish() async {
    if (_currentLocale.languageCode != 'es') {
      _currentLocale = const Locale('es');
      _followSystemLocale = false;
      await _saveLocalePreferences();
      notifyListeners();
      Logger.info('Locale changed to Spanish');
    }
  }
  
  /// Cambiar a inglés
  Future<void> setEnglish() async {
    if (_currentLocale.languageCode != 'en') {
      _currentLocale = const Locale('en');
      _followSystemLocale = false;
      await _saveLocalePreferences();
      notifyListeners();
      Logger.info('Locale changed to English');
    }
  }
  
  /// Seguir el idioma del sistema
  Future<void> setSystemLocale() async {
    _followSystemLocale = true;
    await _saveLocalePreferences();
    
    // Obtener el locale del sistema
    final systemLocale = _getSystemLocale();
    if (systemLocale != null && systemLocale.languageCode != _currentLocale.languageCode) {
      _currentLocale = systemLocale;
      notifyListeners();
      Logger.info('Locale changed to system: ${_currentLocale.languageCode}');
    }
  }
  
  /// Obtener el locale del sistema si es soportado
  Locale? _getSystemLocale() {
    try {
      final systemLocales = WidgetsBinding.instance.platformDispatcher.locales;
      
      for (final systemLocale in systemLocales) {
        if (_isLocaleSupported(systemLocale.languageCode)) {
          return Locale(systemLocale.languageCode);
        }
      }
      
      // Si ningún locale del sistema es soportado, retornar español por defecto
      return const Locale('es');
    } catch (e, stackTrace) {
      Logger.error('Error getting system locale', e, stackTrace);
      return const Locale('es');
    }
  }
  
  /// Cambiar locale específico
  Future<void> setLocale(Locale locale) async {
    if (_isLocaleSupported(locale.languageCode)) {
      if (_currentLocale.languageCode != locale.languageCode) {
        _currentLocale = locale;
        _followSystemLocale = false;
        await _saveLocalePreferences();
        notifyListeners();
        Logger.info('Locale changed to: ${locale.languageCode}');
      }
    } else {
      Logger.warning('Unsupported locale: ${locale.languageCode}');
    }
  }
  
  /// Alternar entre español e inglés
  Future<void> toggleLanguage() async {
    if (_currentLocale.languageCode == 'es') {
      await setEnglish();
    } else {
      await setSpanish();
    }
  }
  
  /// Obtener el nombre del idioma actual para mostrar en UI
  String getCurrentLanguageName() {
    switch (_currentLocale.languageCode) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      default:
        return 'Español';
    }
  }
  
  /// Obtener el nombre del idioma en el idioma actual
  String getCurrentLanguageLocalizedName() {
    switch (_currentLocale.languageCode) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      default:
        return 'Español';
    }
  }
  
  /// Obtener icono de bandera para el idioma actual
  String getCurrentLanguageFlag() {
    switch (_currentLocale.languageCode) {
      case 'es':
        return '🇪🇸';
      case 'en':
        return '🇺🇸';
      default:
        return '🇪🇸';
    }
  }
  
  /// Obtener lista de idiomas disponibles
  List<LanguageOption> getAvailableLanguages() {
    return [
      const LanguageOption(
        locale: Locale('es'),
        name: 'Español',
        nativeName: 'Español',
        flag: '🇪🇸',
      ),
      const LanguageOption(
        locale: Locale('en'),
        name: 'English',
        nativeName: 'English',
        flag: '🇺🇸',
      ),
    ];
  }
  
  /// Resolver locale basado en configuración del sistema
  Locale? localeResolutionCallback(Locale? locale, Iterable<Locale> supportedLocales) {
    if (_followSystemLocale && locale != null) {
      if (supportedLocales.any((supported) => supported.languageCode == locale.languageCode)) {
        return Locale(locale.languageCode);
      }
    }

    return _currentLocale;
  }
  
  /// Resetear a configuración por defecto
  Future<void> resetToDefault() async {
    _currentLocale = const Locale('es');
    _followSystemLocale = true;
    await _saveLocalePreferences();
    notifyListeners();
    Logger.info('Localization reset to default');
  }
  
  /// Obtener estadísticas de localización
  Map<String, dynamic> getLocalizationStats() {
    return {
      'current_locale': _currentLocale.languageCode,
      'follow_system_locale': _followSystemLocale,
      'supported_locales': supportedLocales.map((l) => l.languageCode).toList(),
      'is_spanish': isSpanish,
      'is_english': isEnglish,
    };
  }
}

/// Clase para representar una opción de idioma
class LanguageOption {
  final Locale locale;
  final String name;
  final String nativeName;
  final String flag;
  
  const LanguageOption({
    required this.locale,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageOption && other.locale == locale;
  }
  
  @override
  int get hashCode => locale.hashCode;
}
