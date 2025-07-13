import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/theme_service.dart';
import 'core/services/localization_service.dart';
import 'core/widgets/auto_update_checker.dart';
import 'generated/l10n/app_localizations.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/conteo/conteo_screen.dart';
import 'features/pdf_generator/pdf_generator_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/admin/data_admin_screen.dart';
import 'features/admin/excel_preview_screen.dart';
import 'features/admin/data_import_screen.dart';
import 'features/conteo/segundo_conteo_screen_new.dart';
import 'features/data_management/data_management_screen.dart';
import 'services/auth_service.dart';

class ReCountProApp extends StatelessWidget {
  const ReCountProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Consumer<LocalizationService>(
          builder: (context, localizationService, child) {
        return MaterialApp(
          title: 'ReCount Pro',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          debugShowCheckedModeBanner: false,

          // Localización
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocalizationService.supportedLocales,
          locale: localizationService.currentLocale,
          localeResolutionCallback: localizationService.localeResolutionCallback,

          home: const AutoUpdateChecker(
            enableAutoCheck: true,
            delayBeforeCheck: Duration(seconds: 3),
            showOnlyForceUpdates: false, // Mostrar todas las actualizaciones en desarrollo
            child: AuthWrapper(),
          ),
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/conteo': (context) => const ConteoScreen(),
            '/segundo-conteo': (context) => const SegundoConteoScreenNew(),
            '/pdf': (context) => const PdfGeneratorScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/admin': (context) => const DataAdminScreen(),
            '/excel-preview': (context) => const ExcelPreviewScreen(),
            '/data-import': (context) => const DataImportScreen(),
            '/data-management': (context) => const DataManagementScreen(),
          },
        );
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verificando sesión...'),
                ],
              ),
            ),
          );
        }

        if (authService.user != null) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}