import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recount_pro/core/utils/error_handler.dart';
import 'package:recount_pro/core/exceptions/app_exceptions.dart';

void main() {
  group('ErrorHandler', () {
    group('handleFirebaseAuthError', () {
      test('should handle user-not-found error', () {
        final firebaseError = FirebaseAuthException(
          code: 'user-not-found',
          message: 'User not found',
        );

        final result = ErrorHandler.handleFirebaseAuthError(firebaseError);

        expect(result, isA<AuthException>());
        expect(result.code, 'user-not-found');
        expect(result.message, 'Usuario no encontrado');
      });

      test('should handle wrong-password error', () {
        final firebaseError = FirebaseAuthException(
          code: 'wrong-password',
          message: 'Wrong password',
        );

        final result = ErrorHandler.handleFirebaseAuthError(firebaseError);

        expect(result, isA<AuthException>());
        expect(result.code, 'invalid-credentials');
        expect(result.message, 'Credenciales inválidas');
      });

      test('should handle invalid-credential error', () {
        final firebaseError = FirebaseAuthException(
          code: 'invalid-credential',
          message: 'Invalid credential',
        );

        final result = ErrorHandler.handleFirebaseAuthError(firebaseError);

        expect(result, isA<AuthException>());
        expect(result.code, 'invalid-credentials');
        expect(result.message, 'Credenciales inválidas');
      });

      test('should handle weak-password error', () {
        final firebaseError = FirebaseAuthException(
          code: 'weak-password',
          message: 'Weak password',
        );

        final result = ErrorHandler.handleFirebaseAuthError(firebaseError);

        expect(result, isA<AuthException>());
        expect(result.code, 'weak-password');
        expect(result.message, 'La contraseña es muy débil');
      });

      test('should handle email-already-in-use error', () {
        final firebaseError = FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Email already in use',
        );

        final result = ErrorHandler.handleFirebaseAuthError(firebaseError);

        expect(result, isA<AuthException>());
        expect(result.code, 'email-already-in-use');
        expect(result.message, 'El correo ya está en uso');
      });

      test('should handle network-request-failed error', () {
        final firebaseError = FirebaseAuthException(
          code: 'network-request-failed',
          message: 'Network request failed',
        );

        final result = ErrorHandler.handleFirebaseAuthError(firebaseError);

        expect(result, isA<AuthException>());
        expect(result.code, 'network-error');
        expect(result.message, 'Error de conexión');
      });

      test('should handle unknown error', () {
        final firebaseError = FirebaseAuthException(
          code: 'unknown-error',
          message: 'Unknown error',
        );

        final result = ErrorHandler.handleFirebaseAuthError(firebaseError);

        expect(result, isA<AuthException>());
        expect(result.code, 'unknown');
        expect(result.message, 'Error de autenticación desconocido');
      });
    });

    group('getUserFriendlyMessage', () {
      test('should return friendly message for AuthException', () {
        final exception = AuthException.invalidCredentials();
        final message = ErrorHandler.getUserFriendlyMessage(exception);
        expect(message, 'Correo o contraseña incorrectos');
      });

      test('should return friendly message for ValidationException', () {
        final exception = ValidationException.required('email');
        final message = ErrorHandler.getUserFriendlyMessage(exception);
        expect(message, 'El campo email es requerido');
      });

      test('should return friendly message for BusinessException', () {
        final exception = BusinessException.vhAlreadyCounted();
        final message = ErrorHandler.getUserFriendlyMessage(exception);
        expect(message, 'Este VH ya fue contado hoy');
      });

      test('should return generic message for unknown exception type', () {
        final exception = ValidationException.custom('Custom error');
        final message = ErrorHandler.getUserFriendlyMessage(exception);
        expect(message, 'Custom error');
      });
    });

    group('isRecoverable', () {
      test('should return true for network errors', () {
        final exception = AuthException.networkError();
        final isRecoverable = ErrorHandler.isRecoverable(exception);
        expect(isRecoverable, true);
      });

      test('should return false for invalid credentials', () {
        final exception = AuthException.invalidCredentials();
        final isRecoverable = ErrorHandler.isRecoverable(exception);
        expect(isRecoverable, false);
      });

      test('should return false for user not found', () {
        final exception = AuthException.userNotFound();
        final isRecoverable = ErrorHandler.isRecoverable(exception);
        expect(isRecoverable, false);
      });

      test('should return true for unknown errors by default', () {
        final exception = ValidationException.custom('Unknown error');
        final isRecoverable = ErrorHandler.isRecoverable(exception);
        expect(isRecoverable, true);
      });
    });

    group('handleGenericError', () {
      test('should return the same exception if already AppException', () {
        final originalException = AuthException.invalidCredentials();
        final result = ErrorHandler.handleGenericError(originalException);
        expect(result, same(originalException));
      });

      test('should handle FirebaseAuthException', () {
        final firebaseError = FirebaseAuthException(
          code: 'user-not-found',
          message: 'User not found',
        );
        final result = ErrorHandler.handleGenericError(firebaseError);
        expect(result, isA<AuthException>());
        expect(result.code, 'user-not-found');
      });

      test('should handle generic Exception', () {
        final genericError = Exception('Generic error');
        final result = ErrorHandler.handleGenericError(genericError);
        expect(result, isA<ValidationException>());
        expect(result.message, contains('Error inesperado'));
      });

      test('should handle string errors', () {
        const stringError = 'String error';
        final result = ErrorHandler.handleGenericError(stringError);
        expect(result, isA<ValidationException>());
        expect(result.message, contains('Error inesperado'));
      });
    });
  });
}
