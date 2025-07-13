import 'package:firebase_auth/firebase_auth.dart';
import '../exceptions/app_exceptions.dart';
import 'logger.dart';

class ErrorHandler {
  /// Convierte errores de Firebase Auth a excepciones de la app
  static AppException handleFirebaseAuthError(FirebaseAuthException error) {
    Logger.error('Firebase Auth Error', error, error.stackTrace);
    
    switch (error.code) {
      case 'user-not-found':
        return AuthException.userNotFound();
      case 'wrong-password':
      case 'invalid-credential':
        return AuthException.invalidCredentials();
      case 'weak-password':
        return AuthException.weakPassword();
      case 'email-already-in-use':
        return AuthException.emailAlreadyInUse();
      case 'network-request-failed':
        return AuthException.networkError();
      default:
        return AuthException.unknown(error);
    }
  }
  
  /// Convierte errores de Firestore a excepciones de la app
  static AppException handleFirestoreError(FirebaseException error) {
    Logger.error('Firestore Error', error, error.stackTrace);
    
    switch (error.code) {
      case 'permission-denied':
        return FirestoreException.permissionDenied();
      case 'not-found':
        return FirestoreException.notFound(error.message ?? 'Unknown document');
      case 'unavailable':
      case 'deadline-exceeded':
        return FirestoreException.networkError();
      case 'resource-exhausted':
        return FirestoreException.quotaExceeded();
      default:
        return FirestoreException.unknown(error);
    }
  }
  
  /// Maneja errores generales y los convierte a excepciones de la app
  static AppException handleGenericError(dynamic error, [StackTrace? stackTrace]) {
    Logger.error('Generic Error', error, stackTrace);
    
    if (error is AppException) {
      return error;
    }
    
    if (error is FirebaseAuthException) {
      return handleFirebaseAuthError(error);
    }
    
    if (error is FirebaseException) {
      return handleFirestoreError(error);
    }
    
    // Error desconocido - crear una excepción genérica
    return ValidationException.custom('Error inesperado: ${error.toString()}');
  }
  
  /// Obtiene un mensaje de error amigable para el usuario
  static String getUserFriendlyMessage(AppException exception) {
    if (exception is AuthException) {
      return _getAuthMessage(exception);
    } else if (exception is FirestoreException) {
      return _getFirestoreMessage(exception);
    } else if (exception is ValidationException) {
      return exception.message;
    } else if (exception is BusinessException) {
      return exception.message;
    } else if (exception is NetworkException) {
      return _getNetworkMessage(exception);
    } else {
      return 'Ha ocurrido un error inesperado. Por favor, intenta nuevamente.';
    }
  }
  
  static String _getAuthMessage(AuthException exception) {
    switch (exception.code) {
      case 'invalid-credentials':
        return 'Correo o contraseña incorrectos';
      case 'user-not-found':
        return 'No existe una cuenta con este correo';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo';
      case 'network-error':
        return 'Verifica tu conexión a internet';
      default:
        return 'Error de autenticación. Intenta nuevamente.';
    }
  }
  
  static String _getFirestoreMessage(FirestoreException exception) {
    switch (exception.code) {
      case 'permission-denied':
        return 'No tienes permisos para realizar esta acción';
      case 'not-found':
        return 'La información solicitada no fue encontrada';
      case 'network-error':
        return 'Error de conexión. Verifica tu internet.';
      case 'quota-exceeded':
        return 'Servicio temporalmente no disponible';
      default:
        return 'Error al acceder a los datos. Intenta nuevamente.';
    }
  }
  
  static String _getNetworkMessage(NetworkException exception) {
    switch (exception.code) {
      case 'no-connection':
        return 'Sin conexión a internet';
      case 'timeout':
        return 'La operación tardó demasiado. Intenta nuevamente.';
      case 'server-error':
        return 'Error del servidor. Intenta más tarde.';
      default:
        return 'Error de conexión';
    }
  }
  
  /// Determina si un error es recuperable (el usuario puede reintentar)
  static bool isRecoverable(AppException exception) {
    switch (exception.code) {
      case 'network-error':
      case 'timeout':
      case 'server-error':
      case 'unavailable':
        return true;
      case 'permission-denied':
      case 'invalid-credentials':
      case 'user-not-found':
        return false;
      default:
        return true; // Por defecto, permitir reintentos
    }
  }
}
