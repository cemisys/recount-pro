# API Documentation - ReCount Pro

## 📋 Índice

1. [Visión General](#visión-general)
2. [Autenticación](#autenticación)
3. [Servicios Principales](#servicios-principales)
4. [Modelos de Datos](#modelos-de-datos)
5. [Repositorios](#repositorios)
6. [Manejo de Errores](#manejo-de-errores)
7. [Ejemplos de Uso](#ejemplos-de-uso)

## 🎯 Visión General

Esta documentación describe las APIs internas de ReCount Pro, incluyendo servicios, repositorios y modelos de datos. La aplicación utiliza Firebase como backend principal y implementa una capa de abstracción para facilitar el testing y mantenimiento.

## 🔐 Autenticación

### AuthService

Servicio principal para manejo de autenticación de usuarios.

#### Métodos Principales

```dart
class AuthService extends ChangeNotifier {
  // Estado actual del usuario
  User? get currentUser;
  bool get isAuthenticated;
  
  // Métodos de autenticación
  Future<UserCredential> signInWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  
  // Gestión de estado
  Stream<User?> get authStateChanges;
}
```

#### Ejemplo de Uso

```dart
// Login
try {
  final authService = Provider.of<AuthService>(context, listen: false);
  await authService.signInWithEmailAndPassword(email, password);
  // Navegar a pantalla principal
} catch (e) {
  // Manejar error de autenticación
}

// Logout
await authService.signOut();
```

## 🛠️ Servicios Principales

### 1. AnalyticsService

Servicio estático para recopilación de métricas y eventos.

#### Métodos Principales

```dart
class AnalyticsService {
  // Inicialización
  static Future<void> initialize();
  
  // Eventos de usuario
  static Future<void> logLogin(String method);
  static Future<void> logLogout();
  static Future<void> logScreenView(String screenName);
  
  // Eventos de conteo
  static Future<void> logConteoCompleted({
    required String vhId,
    required int productosContados,
    required bool tieneNovedades,
    required Duration tiempoConteo,
  });
  
  // Eventos de error
  static Future<void> logUserError({
    required String errorType,
    required String screen,
    String? description,
  });
  
  // Propiedades de usuario
  static Future<void> setUserProperties({
    required String userId,
    required String userRole,
    String? userName,
  });
  
  // Crashlytics
  static Future<void> recordError({
    required dynamic exception,
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? customKeys,
    bool fatal = false,
  });
}
```

### 2. CacheService

Servicio para gestión de caché local con TTL.

#### Métodos Principales

```dart
class CacheService {
  // Inicialización
  static Future<void> initialize();
  
  // Operaciones básicas
  static Future<void> set<T>(String key, T value, {Duration? ttl});
  static Future<T?> get<T>(String key);
  static Future<void> remove(String key);
  static Future<void> clear();
  
  // Gestión de TTL
  static Future<bool> isExpired(String key);
  static Future<void> cleanExpired();
  
  // Estadísticas
  static Future<Map<String, dynamic>> getStats();
}
```

#### Ejemplo de Uso

```dart
// Guardar datos con TTL de 1 hora
await CacheService.set('user_data', userData, ttl: Duration(hours: 1));

// Recuperar datos
final userData = await CacheService.get<Map<String, dynamic>>('user_data');

// Verificar si expiró
final isExpired = await CacheService.isExpired('user_data');
```

### 3. PerformanceService

Servicio para optimización de rendimiento.

#### Métodos Principales

```dart
class PerformanceService {
  // Inicialización
  static Future<void> initialize();
  
  // Configuraciones
  static Future<void> setImageQuality(ImageQuality quality);
  static Future<void> setAnimationsEnabled(bool enabled);
  static Future<void> setPreloadData(bool enabled);
  static Future<void> setLowMemoryMode(bool enabled);
  
  // Getters
  static ImageQuality get imageQuality;
  static bool get animationsEnabled;
  static bool get preloadData;
  static bool get lowMemoryMode;
  
  // Utilidades
  static Duration getAnimationDuration(Duration defaultDuration);
  static double getImageScaleFactor();
  static bool shouldPreloadData();
  static int getImageCacheSize();
  
  // Optimizaciones
  static Future<void> clearImageCache();
  static void optimizeImageCache();
  static Future<void> applyRecommendedSettings();
}
```

### 4. MetricsService

Servicio para recopilación de métricas de la aplicación.

#### Métodos Principales

```dart
class MetricsService extends ChangeNotifier {
  // Inicialización
  Future<void> initialize();
  
  // Getters de métricas actuales
  int get currentSessionConteos;
  int get currentSessionErrors;
  Duration get currentSessionDuration;
  
  // Getters de métricas totales
  int get totalSessions;
  int get totalConteos;
  int get totalErrors;
  
  // Registro de eventos
  Future<void> recordConteo({
    required String vhId,
    required int productosContados,
    required bool tieneNovedades,
    required Duration tiempoConteo,
  });
  
  Future<void> recordError({
    required String errorType,
    required String screen,
    String? description,
  });
  
  Future<void> recordScreenView(String screenName);
  
  // Gestión de sesión
  Future<void> endSession();
  
  // Utilidades
  Map<String, dynamic> getMetricsSummary();
  Map<String, dynamic> getDashboardMetrics();
  Map<String, dynamic> exportMetrics();
  Future<void> resetMetrics();
}
```

### 5. LocalizationService

Servicio para gestión de internacionalización.

#### Métodos Principales

```dart
class LocalizationService extends ChangeNotifier {
  // Inicialización
  Future<void> initialize();
  
  // Getters
  Locale get currentLocale;
  bool get followSystemLocale;
  bool get isSpanish;
  bool get isEnglish;
  
  // Cambio de idioma
  Future<void> setSpanish();
  Future<void> setEnglish();
  Future<void> setSystemLocale();
  Future<void> setLocale(Locale locale);
  Future<void> toggleLanguage();
  
  // Utilidades
  String getCurrentLanguageName();
  String getCurrentLanguageFlag();
  List<LanguageOption> getAvailableLanguages();
  
  // Resolución de locale
  Locale? localeResolutionCallback(Locale? locale, Iterable<Locale> supportedLocales);
}
```

## 📊 Modelos de Datos

### UserModel

Modelo para representar usuarios del sistema.

```dart
class UserModel extends Equatable {
  final String uid;
  final String nombre;
  final String correo;
  final String rol;
  final DateTime? fechaCreacion;
  final bool activo;
  final DateTime? ultimoAcceso;

  const UserModel({
    required this.uid,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.fechaCreacion,
    this.activo = true,
    this.ultimoAcceso,
  });

  // Constructor con validaciones
  factory UserModel.create({
    required String uid,
    required String nombre,
    required String correo,
    required String rol,
    DateTime? fechaCreacion,
    bool activo = true,
    DateTime? ultimoAcceso,
  });

  // Serialización
  factory UserModel.fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap();
  Map<String, dynamic> toFirestoreMap();

  // Utilidades
  UserModel copyWith({...});
  UserModel updateLastAccess();
  bool get isActive;
  bool get isAdmin;
  bool get isSupervisorOrAdmin;
  String get displayName;
  bool get isValid;
}
```

### VhProgramado

Modelo para vehículos programados.

```dart
class VhProgramado extends Equatable {
  final String vhId;
  final String placa;
  final DateTime fecha;
  final List<ProductoVh> productos;
  final String? estado;
  final String? conductor;
  final String? ruta;

  const VhProgramado({
    required this.vhId,
    required this.placa,
    required this.fecha,
    required this.productos,
    this.estado,
    this.conductor,
    this.ruta,
  });

  // Constructor con validaciones
  factory VhProgramado.create({...});

  // Serialización
  factory VhProgramado.fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap();
  Map<String, dynamic> toFirestoreMap();

  // Utilidades
  bool get isProgrammedForToday;
  int get totalProductos;
  bool get isValid;
}
```

### ProductoVh

Modelo para productos en vehículos.

```dart
class ProductoVh extends Equatable {
  final String sku;
  final String descripcion;
  final int cantidadProgramada;
  final String? unidad;
  final String? categoria;
  final double? peso;

  const ProductoVh({
    required this.sku,
    required this.descripcion,
    required this.cantidadProgramada,
    this.unidad,
    this.categoria,
    this.peso,
  });

  // Constructor con validaciones
  factory ProductoVh.create({...});

  // Serialización
  factory ProductoVh.fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap();

  // Utilidades
  bool get isValid;
  double? get pesoTotal;
}
```

## 🗄️ Repositorios

### ConteoRepository

Repositorio para gestión de conteos.

```dart
class ConteoRepository {
  // Operaciones CRUD
  Future<List<Conteo>> getConteos();
  Future<Conteo?> getConteoById(String id);
  Future<void> saveConteo(Conteo conteo);
  Future<void> updateConteo(Conteo conteo);
  Future<void> deleteConteo(String id);
  
  // Consultas específicas
  Future<List<Conteo>> getConteosByUser(String userId);
  Future<List<Conteo>> getConteosByDate(DateTime date);
  Future<List<Conteo>> getConteosByVh(String vhId);
}
```

### SkuRepository

Repositorio para gestión de SKUs.

```dart
class SkuRepository {
  // Operaciones básicas
  Future<List<Sku>> getAllSkus();
  Future<Sku?> getSkuByCode(String code);
  Future<List<Sku>> searchSkus(String query);
  
  // Caché
  Future<void> cacheSkus(List<Sku> skus);
  Future<List<Sku>> getCachedSkus();
}
```

## ❌ Manejo de Errores

### Tipos de Excepciones

```dart
// Excepción base
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const AppException(this.message, {this.code, this.originalError});
}

// Excepciones específicas
class ValidationException extends AppException {
  factory ValidationException.custom(String message);
  factory ValidationException.required(String field);
  factory ValidationException.invalidFormat(String field);
}

class NetworkException extends AppException {
  factory NetworkException.noConnection();
  factory NetworkException.timeout();
  factory NetworkException.serverError(int statusCode);
}

class AuthException extends AppException {
  factory AuthException.invalidCredentials();
  factory AuthException.userNotFound();
  factory AuthException.emailAlreadyInUse();
}
```

### ErrorHandler

Utilidad para manejo centralizado de errores.

```dart
class ErrorHandler {
  static String getErrorMessage(dynamic error);
  static void logError(dynamic error, StackTrace? stackTrace);
  static Future<void> reportError(dynamic error, StackTrace? stackTrace);
  static void showErrorSnackBar(BuildContext context, dynamic error);
  static void showErrorDialog(BuildContext context, dynamic error);
}
```

## 💡 Ejemplos de Uso

### Ejemplo Completo: Realizar Conteo

```dart
class ConteoScreen extends StatefulWidget {
  @override
  _ConteoScreenState createState() => _ConteoScreenState();
}

class _ConteoScreenState extends State<ConteoScreen> {
  final _conteoRepository = ConteoRepository();
  final _metricsService = Provider.of<MetricsService>(context, listen: false);
  
  Future<void> _realizarConteo(VhProgramado vh) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Registrar inicio en métricas
      await _metricsService.recordScreenView('conteo_detail');
      
      // Crear conteo
      final conteo = Conteo.create(
        vhId: vh.vhId,
        userId: AuthService.currentUser!.uid,
        productos: vh.productos,
        fecha: DateTime.now(),
      );
      
      // Guardar en repositorio
      await _conteoRepository.saveConteo(conteo);
      
      // Registrar métricas de éxito
      stopwatch.stop();
      await _metricsService.recordConteo(
        vhId: vh.vhId,
        productosContados: vh.productos.length,
        tieneNovedades: conteo.tieneNovedades,
        tiempoConteo: stopwatch.elapsed,
      );
      
      // Registrar en analytics
      await AnalyticsService.logConteoCompleted(
        vhId: vh.vhId,
        productosContados: vh.productos.length,
        tieneNovedades: conteo.tieneNovedades,
        tiempoConteo: stopwatch.elapsed,
      );
      
      // Mostrar éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conteo guardado exitosamente')),
      );
      
    } catch (error, stackTrace) {
      // Registrar error en métricas
      await _metricsService.recordError(
        errorType: error.runtimeType.toString(),
        screen: 'conteo_detail',
        description: error.toString(),
      );
      
      // Reportar error
      await AnalyticsService.recordError(
        exception: error,
        stackTrace: stackTrace,
        reason: 'Error al guardar conteo',
      );
      
      // Mostrar error al usuario
      ErrorHandler.showErrorSnackBar(context, error);
    }
  }
}
```

### Ejemplo: Uso de Caché

```dart
class VhService {
  static const String _vhCacheKey = 'vh_programados';
  static const Duration _cacheTtl = Duration(hours: 2);
  
  Future<List<VhProgramado>> getVhProgramados() async {
    try {
      // Intentar obtener del caché primero
      final cachedVhs = await CacheService.get<List<dynamic>>(_vhCacheKey);
      
      if (cachedVhs != null && !await CacheService.isExpired(_vhCacheKey)) {
        return cachedVhs
            .map((vh) => VhProgramado.fromMap(vh as Map<String, dynamic>))
            .toList();
      }
      
      // Si no hay caché o expiró, obtener de Firebase
      final vhs = await _fetchFromFirebase();
      
      // Guardar en caché
      await CacheService.set(
        _vhCacheKey,
        vhs.map((vh) => vh.toMap()).toList(),
        ttl: _cacheTtl,
      );
      
      return vhs;
      
    } catch (error) {
      // En caso de error, intentar usar caché expirado
      final cachedVhs = await CacheService.get<List<dynamic>>(_vhCacheKey);
      if (cachedVhs != null) {
        return cachedVhs
            .map((vh) => VhProgramado.fromMap(vh as Map<String, dynamic>))
            .toList();
      }
      
      rethrow;
    }
  }
}
```
