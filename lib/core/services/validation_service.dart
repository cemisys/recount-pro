import '../exceptions/app_exceptions.dart';

/// Servicio de validación centralizado
class ValidationService {
  
  /// Validar email
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return ValidationResult.error('El correo electrónico es requerido');
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return ValidationResult.error('Ingresa un correo electrónico válido');
    }
    
    return ValidationResult.success();
  }
  
  /// Validar contraseña
  static ValidationResult validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return ValidationResult.error('La contraseña es requerida');
    }
    
    if (password.length < 6) {
      return ValidationResult.error('La contraseña debe tener al menos 6 caracteres');
    }
    
    return ValidationResult.success();
  }
  
  /// Validar placa de vehículo
  static ValidationResult validatePlaca(String? placa) {
    if (placa == null || placa.trim().isEmpty) {
      return ValidationResult.error('La placa es requerida');
    }
    
    final placaTrimmed = placa.trim().toUpperCase();
    
    // Validar formato básico (letras y números)
    final placaRegex = RegExp(r'^[A-Z0-9]{3,8}$');
    if (!placaRegex.hasMatch(placaTrimmed)) {
      return ValidationResult.error('Formato de placa inválido');
    }
    
    return ValidationResult.success();
  }
  
  /// Validar SKU
  static ValidationResult validateSku(String? sku) {
    if (sku == null || sku.trim().isEmpty) {
      return ValidationResult.error('El SKU es requerido');
    }
    
    final skuTrimmed = sku.trim().toUpperCase();
    
    // Validar que no contenga caracteres especiales problemáticos
    final skuRegex = RegExp(r'^[A-Z0-9\-_]{1,20}$');
    if (!skuRegex.hasMatch(skuTrimmed)) {
      return ValidationResult.error('El SKU contiene caracteres inválidos');
    }
    
    return ValidationResult.success();
  }
  
  /// Validar cantidad numérica
  static ValidationResult validateQuantity(String? quantity, {int min = 0, int? max}) {
    if (quantity == null || quantity.trim().isEmpty) {
      return ValidationResult.error('La cantidad es requerida');
    }
    
    final parsedQuantity = int.tryParse(quantity.trim());
    if (parsedQuantity == null) {
      return ValidationResult.error('Ingresa un número válido');
    }
    
    if (parsedQuantity < min) {
      return ValidationResult.error('La cantidad debe ser mayor o igual a $min');
    }
    
    if (max != null && parsedQuantity > max) {
      return ValidationResult.error('La cantidad debe ser menor o igual a $max');
    }
    
    return ValidationResult.success();
  }
  
  /// Validar texto requerido
  static ValidationResult validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.error('$fieldName es requerido');
    }
    
    return ValidationResult.success();
  }
  
  /// Validar longitud de texto
  static ValidationResult validateLength(String? value, String fieldName, {int? min, int? max}) {
    if (value == null) {
      return ValidationResult.error('$fieldName es requerido');
    }
    
    final length = value.trim().length;
    
    if (min != null && length < min) {
      return ValidationResult.error('$fieldName debe tener al menos $min caracteres');
    }
    
    if (max != null && length > max) {
      return ValidationResult.error('$fieldName debe tener máximo $max caracteres');
    }
    
    return ValidationResult.success();
  }
  
  /// Validar número de teléfono
  static ValidationResult validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return ValidationResult.success(); // Teléfono es opcional
    }
    
    final phoneRegex = RegExp(r'^[0-9+\-\s()]{7,15}$');
    if (!phoneRegex.hasMatch(phone.trim())) {
      return ValidationResult.error('Formato de teléfono inválido');
    }
    
    return ValidationResult.success();
  }
  
  /// Validar cédula/documento
  static ValidationResult validateDocument(String? document) {
    if (document == null || document.trim().isEmpty) {
      return ValidationResult.error('El documento es requerido');
    }
    
    final documentTrimmed = document.trim();
    
    // Validar que solo contenga números
    final documentRegex = RegExp(r'^[0-9]{6,12}$');
    if (!documentRegex.hasMatch(documentTrimmed)) {
      return ValidationResult.error('El documento debe contener entre 6 y 12 dígitos');
    }
    
    return ValidationResult.success();
  }
  
  /// Validar diferencia en conteo (puede ser negativa, positiva o cero)
  static ValidationResult validateDifference(int? alistado, int? fisico) {
    if (alistado == null || fisico == null) {
      return ValidationResult.error('Las cantidades alistado y físico son requeridas');
    }
    
    if (alistado < 0 || fisico < 0) {
      return ValidationResult.error('Las cantidades no pueden ser negativas');
    }
    
    return ValidationResult.success();
  }
  
  /// Validar que una fecha no sea futura
  static ValidationResult validateDateNotFuture(DateTime? date, String fieldName) {
    if (date == null) {
      return ValidationResult.error('$fieldName es requerida');
    }
    
    final now = DateTime.now();
    if (date.isAfter(now)) {
      return ValidationResult.error('$fieldName no puede ser una fecha futura');
    }
    
    return ValidationResult.success();
  }
  
  /// Validar múltiples campos a la vez
  static ValidationResult validateMultiple(List<ValidationResult> results) {
    for (final result in results) {
      if (!result.isValid) {
        return result;
      }
    }
    return ValidationResult.success();
  }
  
  /// Sanitizar texto (remover caracteres peligrosos)
  static String sanitizeText(String? text) {
    if (text == null) return '';

    return text
        .trim()
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(RegExp(r'\s+'), ' '); // Normalizar espacios
  }
  
  /// Sanitizar SKU
  static String sanitizeSku(String? sku) {
    if (sku == null) return '';
    
    return sku
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9\-_]'), ''); // Solo permitir caracteres válidos
  }
  
  /// Sanitizar placa
  static String sanitizePlaca(String? placa) {
    if (placa == null) return '';
    
    return placa
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), ''); // Solo letras y números
  }
}

/// Resultado de validación
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  
  const ValidationResult._(this.isValid, this.errorMessage);
  
  factory ValidationResult.success() => const ValidationResult._(true, null);
  factory ValidationResult.error(String message) => ValidationResult._(false, message);
  
  /// Lanzar excepción si la validación falló
  void throwIfInvalid() {
    if (!isValid && errorMessage != null) {
      throw ValidationException.custom(errorMessage!);
    }
  }
}
