import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recount_pro/features/auth/login_screen.dart';
import 'package:recount_pro/services/auth_service.dart';

import 'login_screen_test.mocks.dart';
import '../../test_helpers/widget_test_helper.dart' as helper;

@GenerateMocks([AuthService, UserCredential])
void main() {
  group('LoginScreen Widget Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();

      // Setup default mock behavior
      when(mockAuthService.isLoading).thenReturn(false);
      when(mockAuthService.errorMessage).thenReturn(null);
      when(mockAuthService.lastError).thenReturn(null);
    });

    Widget createLoginScreen() {
      return helper.WidgetTestHelper.createTestWidget(
        authService: mockAuthService,
        child: const LoginScreen(),
      );
    }

    group('UI Elements', () {
      testWidgets('should display all required UI elements', (WidgetTester tester) async {
        await tester.pumpWidget(createLoginScreen());

        // Check for logo
        expect(find.text('CD-3M'), findsOneWidget);
        
        // Check for title
        expect(find.text('ReCount Pro'), findsOneWidget);
        
        // Check for subtitle
        expect(find.text('Verificador - Segundo Conteo'), findsOneWidget);
        
        // Check for email field
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.text('Correo electrónico'), findsOneWidget);
        
        // Check for password field
        expect(find.text('Contraseña'), findsOneWidget);
        
        // Check for login button
        expect(find.text('Iniciar Sesión'), findsOneWidget);
        
        // Check for footer
        expect(find.text('ReCount Pro by 3M Technology®'), findsOneWidget);
      });

      testWidgets('should have password visibility toggle', (WidgetTester tester) async {
        await tester.pumpWidget(createLoginScreen());

        // Assert - Should have visibility toggle icon
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      });

      testWidgets('should toggle password visibility when icon is tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createLoginScreen());

        // Find the visibility toggle button
        final visibilityButton = find.byIcon(Icons.visibility_outlined);
        expect(visibilityButton, findsOneWidget);

        // Tap to show password
        await tester.tap(visibilityButton);
        await tester.pump();

        // Check that icon changed to visibility_off
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      });
    });

    group('Form Validation', () {
      testWidgets('should show validation errors for empty fields', (WidgetTester tester) async {
        await tester.pumpWidget(createLoginScreen());

        // Tap login button without entering any data
        await tester.tap(find.text('Iniciar Sesión'));
        await tester.pump();

        // Check for validation error messages
        expect(find.text('El correo electrónico es requerido'), findsOneWidget);
        expect(find.text('La contraseña es requerida'), findsOneWidget);
      });

      testWidgets('should show validation error for invalid email', (WidgetTester tester) async {
        await tester.pumpWidget(createLoginScreen());

        // Enter invalid email
        await tester.enterText(
          find.byType(TextFormField).first,
          'invalid-email',
        );
        
        // Tap login button
        await tester.tap(find.text('Iniciar Sesión'));
        await tester.pump();

        // Check for email validation error
        expect(find.text('Ingresa un correo electrónico válido'), findsOneWidget);
      });

      testWidgets('should show validation error for short password', (WidgetTester tester) async {
        await tester.pumpWidget(createLoginScreen());

        // Enter valid email but short password
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          '123',
        );
        
        // Tap login button
        await tester.tap(find.text('Iniciar Sesión'));
        await tester.pump();

        // Check for password validation error
        expect(find.text('La contraseña debe tener al menos 6 caracteres'), findsOneWidget);
      });

      testWidgets('should not show validation errors for valid input', (WidgetTester tester) async {
        when(mockAuthService.signInWithEmailAndPassword(any, any))
            .thenAnswer((_) async => true);

        await tester.pumpWidget(createLoginScreen());

        // Enter valid credentials
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@example.com',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'password123',
        );
        
        // Just verify fields without submitting
        await tester.pump();

        // Should not find validation error messages
        expect(find.text('El correo electrónico es requerido'), findsNothing);
        expect(find.text('La contraseña es requerida'), findsNothing);
        expect(find.text('Ingresa un correo electrónico válido'), findsNothing);
        expect(find.text('La contraseña debe tener al menos 6 caracteres'), findsNothing);
      });
    });

    group('Authentication Flow', () {
      testWidgets('should call AuthService.signInWithEmailAndPassword when form is submitted', (WidgetTester tester) async {
        when(mockAuthService.signInWithEmailAndPassword(any, any))
            .thenAnswer((_) async => false); // Return false to avoid navigation

        await tester.pumpWidget(createLoginScreen());

        const email = 'test@example.com';
        const password = 'password123';

        // Enter credentials
        await tester.enterText(find.byType(TextFormField).first, email);
        await tester.enterText(find.byType(TextFormField).last, password);
        
        // Tap login button
        await tester.tap(find.text('Iniciar Sesión'));
        await tester.pump();

        // Verify that signInWithEmailAndPassword was called with correct parameters
        verify(mockAuthService.signInWithEmailAndPassword(email, password)).called(1);
      });

      testWidgets('should show loading indicator when authentication is in progress', (WidgetTester tester) async {
        // Setup mock to simulate a slow authentication
        when(mockAuthService.signInWithEmailAndPassword(any, any))
            .thenAnswer((_) => Future.delayed(const Duration(milliseconds: 50), () => false));

        await tester.pumpWidget(createLoginScreen());

        // Enter credentials
        await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'password123');

        // Tap login button
        await tester.tap(find.text('Iniciar Sesión'));
        await tester.pump(); // Start the async operation

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for the operation to complete
        await tester.pumpAndSettle();
      });

      testWidgets('should show error message when authentication fails', (WidgetTester tester) async {
        const errorMessage = 'Credenciales inválidas';
        when(mockAuthService.signInWithEmailAndPassword(any, any))
            .thenAnswer((_) async => false);
        when(mockAuthService.errorMessage).thenReturn(errorMessage);

        await tester.pumpWidget(createLoginScreen());

        // Enter credentials
        await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
        await tester.enterText(find.byType(TextFormField).last, 'wrongpassword');
        
        // Tap login button
        await tester.tap(find.text('Iniciar Sesión'));
        await tester.pump();
        await tester.pump(); // Additional pump for SnackBar animation

        // Should show error in SnackBar
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantics for screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(createLoginScreen());

        // Check that form fields have proper labels
        expect(find.bySemanticsLabel('Correo electrónico'), findsOneWidget);
        expect(find.bySemanticsLabel('Contraseña'), findsOneWidget);
      });
    });
  });
}
