/// Excepción base para la aplicación
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const AppException(this.message, {this.code, this.originalError});
  
  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Excepciones relacionadas con autenticación
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
  
  factory AuthException.invalidCredentials() {
    return const AuthException('Credenciales inválidas', code: 'invalid-credentials');
  }
  
  factory AuthException.userNotFound() {
    return const AuthException('Usuario no encontrado', code: 'user-not-found');
  }
  
  factory AuthException.weakPassword() {
    return const AuthException('La contraseña es muy débil', code: 'weak-password');
  }
  
  factory AuthException.emailAlreadyInUse() {
    return const AuthException('El correo ya está en uso', code: 'email-already-in-use');
  }
  
  factory AuthException.networkError() {
    return const AuthException('Error de conexión', code: 'network-error');
  }
  
  factory AuthException.unknown(dynamic error) {
    return AuthException('Error de autenticación desconocido', 
        code: 'unknown', originalError: error);
  }
}

/// Excepciones relacionadas con Firestore
class FirestoreException extends AppException {
  const FirestoreException(super.message, {super.code, super.originalError});
  
  factory FirestoreException.permissionDenied() {
    return const FirestoreException('Permisos insuficientes', code: 'permission-denied');
  }
  
  factory FirestoreException.notFound(String document) {
    return FirestoreException('Documento no encontrado: $document', code: 'not-found');
  }
  
  factory FirestoreException.networkError() {
    return const FirestoreException('Error de conexión a la base de datos', code: 'network-error');
  }
  
  factory FirestoreException.quotaExceeded() {
    return const FirestoreException('Cuota de base de datos excedida', code: 'quota-exceeded');
  }
  
  factory FirestoreException.unknown(dynamic error) {
    return FirestoreException('Error de base de datos desconocido', 
        code: 'unknown', originalError: error);
  }
}

/// Excepciones relacionadas con validación de datos
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.originalError});
  
  factory ValidationException.required(String field) {
    return ValidationException('El campo $field es requerido', code: 'required');
  }
  
  factory ValidationException.invalidFormat(String field) {
    return ValidationException('Formato inválido para $field', code: 'invalid-format');
  }
  
  factory ValidationException.outOfRange(String field, dynamic min, dynamic max) {
    return ValidationException('$field debe estar entre $min y $max', code: 'out-of-range');
  }
  
  factory ValidationException.custom(String message) {
    return ValidationException(message, code: 'custom');
  }
}

/// Excepciones relacionadas con operaciones de negocio
class BusinessException extends AppException {
  const BusinessException(super.message, {super.code, super.originalError});
  
  factory BusinessException.vhAlreadyCounted() {
    return const BusinessException('Este VH ya fue contado hoy', code: 'vh-already-counted');
  }
  
  factory BusinessException.vhNotFound() {
    return const BusinessException('VH no encontrado para la fecha actual', code: 'vh-not-found');
  }
  
  factory BusinessException.invalidSku() {
    return const BusinessException('SKU no válido o no encontrado', code: 'invalid-sku');
  }
  
  factory BusinessException.insufficientPermissions() {
    return const BusinessException('Permisos insuficientes para esta operación', code: 'insufficient-permissions');
  }
}

/// Excepciones relacionadas con la red
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
  
  factory NetworkException.noConnection() {
    return const NetworkException('Sin conexión a internet', code: 'no-connection');
  }
  
  factory NetworkException.timeout() {
    return const NetworkException('Tiempo de espera agotado', code: 'timeout');
  }
  
  factory NetworkException.serverError() {
    return const NetworkException('Error del servidor', code: 'server-error');
  }
}
