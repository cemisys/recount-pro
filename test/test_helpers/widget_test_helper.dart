import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:recount_pro/services/auth_service.dart';
import 'package:recount_pro/core/theme/app_theme.dart';
import 'package:recount_pro/core/exceptions/app_exceptions.dart';

/// Helper para crear widgets de test con todos los providers necesarios
class WidgetTestHelper {
  /// Crea un widget de test con providers mockeados
  static Widget createTestWidget({
    required Widget child,
    AuthService? authService,
  }) {
    // Crear mocks por defecto si no se proporcionan
    final mockAuthService = authService ?? _createMockAuthService();

    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: ChangeNotifierProvider<AuthService>.value(
        value: mockAuthService,
        child: child,
      ),
    );
  }

  /// Crea un mock básico de AuthService
  static AuthService _createMockAuthService() {
    final mock = MockAuthService();
    
    // Setup comportamiento por defecto
    when(mock.isLoading).thenReturn(false);
    when(mock.errorMessage).thenReturn(null);
    when(mock.lastError).thenReturn(null);
    
    return mock;
  }


}

/// Mock básico de AuthService para tests
class MockAuthService extends Mock implements AuthService {
  @override
  bool get isLoading => super.noSuchMethod(
    Invocation.getter(#isLoading),
    returnValue: false,
  );

  @override
  String? get errorMessage => super.noSuchMethod(
    Invocation.getter(#errorMessage),
    returnValue: null,
  );

  @override
  AppException? get lastError => super.noSuchMethod(
    Invocation.getter(#lastError),
    returnValue: null,
  );


}


