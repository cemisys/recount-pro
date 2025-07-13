import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:recount_pro/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ReCount Pro Integration Tests', () {
    testWidgets('App should start and show splash screen', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify that splash screen is shown
      expect(find.text('CD-3M'), findsOneWidget);
      expect(find.text('ReCount Pro'), findsOneWidget);
      
      // Wait for splash screen to finish (3 seconds + navigation time)
      await tester.pumpAndSettle(const Duration(seconds: 4));
      
      // Should navigate to login screen after splash
      expect(find.text('Iniciar Sesión'), findsOneWidget);
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
    });

    testWidgets('Login form validation should work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Wait for navigation to login screen
      await tester.pumpAndSettle(const Duration(seconds: 4));
      
      // Try to login without entering credentials
      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();
      
      // Should show validation errors
      expect(find.text('El correo electrónico es requerido'), findsOneWidget);
      expect(find.text('La contraseña es requerida'), findsOneWidget);
    });

    testWidgets('Login form should accept valid input', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Wait for navigation to login screen
      await tester.pumpAndSettle(const Duration(seconds: 4));
      
      // Enter valid email
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      
      // Enter valid password
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );
      
      await tester.pumpAndSettle();
      
      // Tap login button
      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();
      
      // Should not show validation errors
      expect(find.text('El correo electrónico es requerido'), findsNothing);
      expect(find.text('La contraseña es requerida'), findsNothing);
      
      // Note: In a real integration test, you would test actual authentication
      // For now, we're just testing that the form validation works
    });

    testWidgets('Password visibility toggle should work', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Wait for navigation to login screen
      await tester.pumpAndSettle(const Duration(seconds: 4));
      
      // Find password field
      final passwordField = find.byType(TextFormField).last;
      
      // Enter password
      await tester.enterText(passwordField, 'testpassword');
      await tester.pumpAndSettle();
      
      // Check that visibility toggle works by looking for the icon changes
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      // Icon should change to visibility_off
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Tap again to hide password
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      // Icon should change back to visibility
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('App should handle navigation correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Should start with splash screen
      expect(find.text('CD-3M'), findsOneWidget);
      expect(find.text('ReCount Pro'), findsOneWidget);
      
      // Wait for automatic navigation
      await tester.pumpAndSettle(const Duration(seconds: 4));
      
      // Should navigate to login screen
      expect(find.text('Iniciar Sesión'), findsOneWidget);
      expect(find.text('Correo electrónico'), findsOneWidget);
      
      // Splash screen elements should no longer be visible
      expect(find.text('Cargando...'), findsNothing);
    });

    testWidgets('App theme should be applied correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Wait for navigation to login screen
      await tester.pumpAndSettle(const Duration(seconds: 4));
      
      // Check that the app uses the correct theme colors
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
      
      // Check for specific theme elements
      expect(find.byType(ElevatedButton), findsOneWidget);
      
      final elevatedButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(elevatedButton.style, isNotNull);
    });

    testWidgets('Form fields should be interactive', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for navigation to login screen
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Tap on email field and enter text
      await tester.tap(find.byType(TextFormField).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('test@example.com'), findsOneWidget);

      // Tap on password field and enter text
      await tester.tap(find.byType(TextFormField).last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.pumpAndSettle();

      // Verify password field accepts input (text should be obscured)
      expect(find.text('password123'), findsNothing); // Password is obscured
    });
  });
}
