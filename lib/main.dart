import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'core/services/app_state_service.dart';
import 'core/services/cache_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/metrics_service.dart';
import 'core/services/localization_service.dart';
import 'core/services/performance_service.dart';
import 'core/services/update_service.dart';
import 'core/repositories/conteo_repository.dart';
import 'core/repositories/sku_repository.dart';
// import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Deshabilitar validación de Provider para desarrollo
  Provider.debugCheckInvalidValueType = null;
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar servicios
  await CacheService.initialize();

  // Inicializar Performance Service (debe ser uno de los primeros)
  await PerformanceService.initialize();

  // Inicializar Analytics y Metrics
  await AnalyticsService.initialize();
  final metricsService = MetricsService();
  await metricsService.initialize();

  // Inicializar servicio de actualizaciones
  await UpdateService.initialize();

  // Inicializar ThemeService y LocalizationService
  final themeService = ThemeService();
  await themeService.initialize();

  final localizationService = LocalizationService();
  await localizationService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        // Servicios de estado
        ChangeNotifierProvider(create: (_) => AppStateService()),
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: metricsService),
        ChangeNotifierProvider.value(value: localizationService),
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => FirebaseService()),

        // Repositorios
        Provider(create: (_) => ConteoRepository()),
        Provider(create: (_) => SkuRepository()),
        Provider(create: (_) => AuxiliarRepository()),
      ],
      child: const ReCountProApp(),
    ),
  );
}