# Guía de Desarrollo - ReCount Pro

## 📋 Índice

1. [Configuración del Entorno](#configuración-del-entorno)
2. [Estándares de Código](#estándares-de-código)
3. [Flujo de Desarrollo](#flujo-de-desarrollo)
4. [Testing](#testing)
5. [Debugging](#debugging)
6. [Performance](#performance)
7. [Deployment](#deployment)

## 🛠️ Configuración del Entorno

### Requisitos Previos

```bash
# Verificar versiones
flutter --version  # >= 3.24.5
dart --version     # >= 3.5.4
git --version      # >= 2.0
```

### Configuración Inicial

```bash
# 1. Clonar repositorio
git clone https://github.com/tu-usuario/recount-pro.git
cd recount-pro

# 2. Instalar dependencias
flutter pub get

# 3. Generar archivos de localización
flutter gen-l10n

# 4. Verificar configuración
flutter doctor

# 5. Ejecutar tests
flutter test
```

### Configuración de IDE

#### VS Code (Recomendado)

Extensiones necesarias:
```json
{
  "recommendations": [
    "dart-code.flutter",
    "dart-code.dart-code",
    "ms-vscode.vscode-json",
    "bradlc.vscode-tailwindcss",
    "usernamehw.errorlens"
  ]
}
```

Configuración en `.vscode/settings.json`:
```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.lineLength": 100,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "dart.showTodos": true,
  "dart.debugExternalPackageLibraries": false,
  "dart.debugSdkLibraries": false
}
```

#### Android Studio

1. Instalar plugins: Flutter, Dart
2. Configurar SDK paths
3. Habilitar análisis de código
4. Configurar formateo automático

### Variables de Entorno

Crear archivo `.env` en la raíz:
```env
# Firebase
FIREBASE_PROJECT_ID=recount-pro-dev
FIREBASE_API_KEY=your-api-key

# Analytics
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=true

# Debug
DEBUG_MODE=true
VERBOSE_LOGGING=true
```

## 📝 Estándares de Código

### Convenciones de Nomenclatura

```dart
// Clases: PascalCase
class UserModel extends Equatable { }
class AuthService extends ChangeNotifier { }

// Variables y métodos: camelCase
String userName = 'John Doe';
void getUserData() { }

// Constantes: camelCase con const
const String apiBaseUrl = 'https://api.example.com';
const Duration defaultTimeout = Duration(seconds: 30);

// Archivos: snake_case
user_model.dart
auth_service.dart
conteo_screen.dart
```

### Estructura de Archivos

```dart
// 1. Imports de Dart/Flutter
import 'dart:async';
import 'package:flutter/material.dart';

// 2. Imports de packages externos
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 3. Imports relativos (ordenados por profundidad)
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../core/utils/logger.dart';

// 4. Clase principal
class LoginScreen extends StatefulWidget {
  // Constantes estáticas
  static const String routeName = '/login';
  
  // Constructor
  const LoginScreen({super.key});
  
  // Métodos override
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
```

### Documentación de Código

```dart
/// Servicio para gestionar la autenticación de usuarios.
/// 
/// Proporciona métodos para login, logout y gestión de estado
/// de autenticación usando Firebase Auth.
/// 
/// Ejemplo de uso:
/// ```dart
/// final authService = AuthService();
/// await authService.signInWithEmailAndPassword(email, password);
/// ```
class AuthService extends ChangeNotifier {
  
  /// Inicia sesión con email y contraseña.
  /// 
  /// Lanza [AuthException] si las credenciales son inválidas.
  /// Lanza [NetworkException] si no hay conexión.
  /// 
  /// [email] debe ser un email válido
  /// [password] debe tener al menos 6 caracteres
  Future<UserCredential> signInWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    // Implementación...
  }
}
```

### Manejo de Errores

```dart
// ✅ Correcto: Manejo específico de errores
try {
  await authService.signIn(email, password);
} on AuthException catch (e) {
  _showAuthError(e.message);
} on NetworkException catch (e) {
  _showNetworkError(e.message);
} catch (e, stackTrace) {
  Logger.error('Unexpected error during login', e, stackTrace);
  _showGenericError();
}

// ❌ Incorrecto: Manejo genérico
try {
  await authService.signIn(email, password);
} catch (e) {
  print('Error: $e'); // No usar print en producción
}
```

### Widgets

```dart
// ✅ Correcto: Widget con const constructor
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  
  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading 
          ? const CircularProgressIndicator()
          : Text(text),
    );
  }
}

// ❌ Incorrecto: Sin const, sin key
class CustomButton extends StatelessWidget {
  String text;
  VoidCallback onPressed;
  
  CustomButton(this.text, this.onPressed);
  
  Widget build(context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
```

## 🔄 Flujo de Desarrollo

### Git Workflow

```bash
# 1. Crear rama para nueva feature
git checkout -b feature/nueva-funcionalidad

# 2. Hacer cambios y commits frecuentes
git add .
git commit -m "feat: agregar validación de email"

# 3. Mantener rama actualizada
git fetch origin
git rebase origin/main

# 4. Push y crear PR
git push origin feature/nueva-funcionalidad
```

### Convenciones de Commits

Usar [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Tipos de commits
feat: nueva funcionalidad
fix: corrección de bug
docs: cambios en documentación
style: formateo, punto y coma faltante, etc.
refactor: refactoring de código
test: agregar o modificar tests
chore: tareas de mantenimiento

# Ejemplos
git commit -m "feat: agregar modo oscuro"
git commit -m "fix: corregir error de validación en login"
git commit -m "docs: actualizar README con nuevas instrucciones"
git commit -m "test: agregar tests para AuthService"
```

### Code Review Checklist

- [ ] ¿El código sigue las convenciones de nomenclatura?
- [ ] ¿Hay documentación adecuada para métodos públicos?
- [ ] ¿Se manejan todos los casos de error?
- [ ] ¿Los tests cubren la nueva funcionalidad?
- [ ] ¿Se actualizó la documentación si es necesario?
- [ ] ¿El código es performante y no introduce memory leaks?
- [ ] ¿Se siguieron los principios SOLID?

## 🧪 Testing

### Estructura de Tests

```
test/
├── core/
│   ├── services/
│   │   ├── analytics_service_test.dart
│   │   ├── cache_service_test.dart
│   │   └── validation_service_test.dart
│   └── utils/
│       ├── error_handler_test.dart
│       └── logger_test.dart
├── models/
│   ├── user_model_test.dart
│   └── vh_model_test.dart
├── features/
│   └── auth/
│       └── login_screen_test.dart
└── test_helpers/
    ├── mock_services.dart
    └── test_data.dart
```

### Tipos de Tests

#### 1. Unit Tests

```dart
// test/core/services/validation_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:recount_pro/core/services/validation_service.dart';

void main() {
  group('ValidationService', () {
    group('validateEmail', () {
      test('should return valid for correct email', () {
        // Arrange
        const email = 'test@example.com';
        
        // Act
        final result = ValidationService.validateEmail(email);
        
        // Assert
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });
      
      test('should return invalid for incorrect email', () {
        // Arrange
        const email = 'invalid-email';
        
        // Act
        final result = ValidationService.validateEmail(email);
        
        // Assert
        expect(result.isValid, false);
        expect(result.errorMessage, isNotNull);
      });
    });
  });
}
```

#### 2. Widget Tests

```dart
// test/features/auth/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:recount_pro/features/auth/login_screen.dart';
import 'package:recount_pro/services/auth_service.dart';

import '../../test_helpers/mock_services.dart';

void main() {
  group('LoginScreen', () {
    late MockAuthService mockAuthService;
    
    setUp(() {
      mockAuthService = MockAuthService();
    });
    
    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<AuthService>.value(
          value: mockAuthService,
          child: const LoginScreen(),
        ),
      );
    }
    
    testWidgets('should display email and password fields', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      
      // Assert
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
    });
    
    testWidgets('should call signIn when login button is pressed', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      
      // Act
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      
      // Assert
      verify(mockAuthService.signInWithEmailAndPassword('test@example.com', 'password123'));
    });
  });
}
```

#### 3. Integration Tests

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:recount_pro/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('App Integration Tests', () {
    testWidgets('complete login flow', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();
      
      // Act - Navigate to login
      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();
      
      // Act - Enter credentials
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      
      // Assert - Should navigate to main screen
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
```

### Ejecutar Tests

```bash
# Todos los tests
flutter test

# Tests específicos
flutter test test/core/services/
flutter test test/models/user_model_test.dart

# Tests con cobertura
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Integration tests
flutter test integration_test/

# Script automatizado
./scripts/run_tests.sh
```

## 🐛 Debugging

### Logging

```dart
// Usar Logger en lugar de print
import 'package:recount_pro/core/utils/logger.dart';

// Diferentes niveles
Logger.debug('Debug information');
Logger.info('General information');
Logger.warning('Warning message');
Logger.error('Error occurred', error, stackTrace);

// En producción, solo se muestran warnings y errores
```

### Flutter Inspector

```bash
# Abrir Flutter Inspector
flutter inspector

# Debug con breakpoints
flutter run --debug

# Profile mode para performance
flutter run --profile
```

### Debugging Tips

```dart
// 1. Usar debugPrint para widgets
debugPrint('Widget built: ${widget.runtimeType}');

// 2. Usar assert para validaciones en desarrollo
assert(user != null, 'User should not be null');

// 3. Usar debugger() para breakpoints programáticos
import 'dart:developer';

void someMethod() {
  debugger(); // Pausa aquí en debug mode
  // resto del código...
}

// 4. Inspeccionar estado de widgets
class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    debugPrint('Building with data: $_data');
    return Container(/* ... */);
  }
}
```

## ⚡ Performance

### Mejores Prácticas

```dart
// 1. Usar const constructors
const Text('Hello World');
const SizedBox(height: 16);

// 2. Evitar rebuilds innecesarios
class ExpensiveWidget extends StatelessWidget {
  const ExpensiveWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<SomeService>(
      builder: (context, service, child) {
        return Column(
          children: [
            Text(service.data),
            child!, // Widget que no cambia
          ],
        );
      },
      child: const ExpensiveChildWidget(), // Se construye una sola vez
    );
  }
}

// 3. Usar ListView.builder para listas grandes
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
);

// 4. Optimizar imágenes
Image.network(
  url,
  cacheWidth: 300, // Redimensionar en caché
  cacheHeight: 200,
);
```

### Profiling

```bash
# Performance profiling
flutter run --profile
# Luego usar DevTools para analizar

# Memory profiling
flutter run --debug
# Usar Flutter Inspector para memory leaks

# Análisis de tamaño de app
flutter build apk --analyze-size
```

## 🚀 Deployment

### Build para Producción

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Análisis antes del build
flutter analyze
flutter test
```

### Configuración de Release

#### Android (`android/app/build.gradle`)

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

#### iOS (`ios/Runner/Info.plist`)

```xml
<key>CFBundleVersion</key>
<string>$(FLUTTER_BUILD_NUMBER)</string>
<key>CFBundleShortVersionString</key>
<string>$(FLUTTER_BUILD_NAME)</string>
```

### CI/CD Pipeline

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.5'
      
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      
  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - run: flutter pub get
      - run: flutter build apk --release
      
      - uses: actions/upload-artifact@v3
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

### Checklist de Release

- [ ] Todos los tests pasan
- [ ] Análisis estático sin errores
- [ ] Documentación actualizada
- [ ] Versión incrementada en `pubspec.yaml`
- [ ] Changelog actualizado
- [ ] Build de release exitoso
- [ ] Testing en dispositivos físicos
- [ ] Configuración de Firebase para producción
