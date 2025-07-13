import 'package:flutter_test/flutter_test.dart';
import 'package:recount_pro/core/services/validation_service.dart';

void main() {
  group('ValidationService', () {
    group('validateEmail', () {
      test('should return success for valid email', () {
        final result = ValidationService.validateEmail('test@example.com');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('should return error for null email', () {
        final result = ValidationService.validateEmail(null);
        expect(result.isValid, false);
        expect(result.errorMessage, 'El correo electrónico es requerido');
      });

      test('should return error for empty email', () {
        final result = ValidationService.validateEmail('');
        expect(result.isValid, false);
        expect(result.errorMessage, 'El correo electrónico es requerido');
      });

      test('should return error for invalid email format', () {
        final result = ValidationService.validateEmail('invalid-email');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Ingresa un correo electrónico válido');
      });

      test('should return error for email without domain', () {
        final result = ValidationService.validateEmail('test@');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Ingresa un correo electrónico válido');
      });
    });

    group('validatePassword', () {
      test('should return success for valid password', () {
        final result = ValidationService.validatePassword('password123');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('should return error for null password', () {
        final result = ValidationService.validatePassword(null);
        expect(result.isValid, false);
        expect(result.errorMessage, 'La contraseña es requerida');
      });

      test('should return error for empty password', () {
        final result = ValidationService.validatePassword('');
        expect(result.isValid, false);
        expect(result.errorMessage, 'La contraseña es requerida');
      });

      test('should return error for short password', () {
        final result = ValidationService.validatePassword('12345');
        expect(result.isValid, false);
        expect(result.errorMessage, 'La contraseña debe tener al menos 6 caracteres');
      });
    });

    group('validatePlaca', () {
      test('should return success for valid placa', () {
        final result = ValidationService.validatePlaca('ABC123');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('should return error for null placa', () {
        final result = ValidationService.validatePlaca(null);
        expect(result.isValid, false);
        expect(result.errorMessage, 'La placa es requerida');
      });

      test('should return error for empty placa', () {
        final result = ValidationService.validatePlaca('');
        expect(result.isValid, false);
        expect(result.errorMessage, 'La placa es requerida');
      });

      test('should return error for invalid placa format', () {
        final result = ValidationService.validatePlaca('AB');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Formato de placa inválido');
      });

      test('should return error for placa with special characters', () {
        final result = ValidationService.validatePlaca('ABC-123@');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Formato de placa inválido');
      });
    });

    group('validateSku', () {
      test('should return success for valid SKU', () {
        final result = ValidationService.validateSku('SKU001');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('should return error for null SKU', () {
        final result = ValidationService.validateSku(null);
        expect(result.isValid, false);
        expect(result.errorMessage, 'El SKU es requerido');
      });

      test('should return error for empty SKU', () {
        final result = ValidationService.validateSku('');
        expect(result.isValid, false);
        expect(result.errorMessage, 'El SKU es requerido');
      });

      test('should return error for SKU with invalid characters', () {
        final result = ValidationService.validateSku('SKU@001');
        expect(result.isValid, false);
        expect(result.errorMessage, 'El SKU contiene caracteres inválidos');
      });
    });

    group('validateQuantity', () {
      test('should return success for valid quantity', () {
        final result = ValidationService.validateQuantity('10');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('should return error for null quantity', () {
        final result = ValidationService.validateQuantity(null);
        expect(result.isValid, false);
        expect(result.errorMessage, 'La cantidad es requerida');
      });

      test('should return error for empty quantity', () {
        final result = ValidationService.validateQuantity('');
        expect(result.isValid, false);
        expect(result.errorMessage, 'La cantidad es requerida');
      });

      test('should return error for non-numeric quantity', () {
        final result = ValidationService.validateQuantity('abc');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Ingresa un número válido');
      });

      test('should return error for negative quantity', () {
        final result = ValidationService.validateQuantity('-5');
        expect(result.isValid, false);
        expect(result.errorMessage, 'La cantidad debe ser mayor o igual a 0');
      });

      test('should respect min and max constraints', () {
        final result1 = ValidationService.validateQuantity('5', min: 10);
        expect(result1.isValid, false);
        expect(result1.errorMessage, 'La cantidad debe ser mayor o igual a 10');

        final result2 = ValidationService.validateQuantity('15', max: 10);
        expect(result2.isValid, false);
        expect(result2.errorMessage, 'La cantidad debe ser menor o igual a 10');
      });
    });

    group('sanitizeText', () {
      test('should remove dangerous characters', () {
        final result = ValidationService.sanitizeText('<script>alert("xss")</script>');
        expect(result, 'scriptalert(xss)/script');
      });

      test('should normalize whitespace', () {
        final result = ValidationService.sanitizeText('  multiple   spaces  ');
        expect(result, 'multiple spaces');
      });

      test('should handle null input', () {
        final result = ValidationService.sanitizeText(null);
        expect(result, '');
      });
    });

    group('sanitizePlaca', () {
      test('should convert to uppercase and remove invalid characters', () {
        final result = ValidationService.sanitizePlaca('abc-123@');
        expect(result, 'ABC123');
      });

      test('should handle null input', () {
        final result = ValidationService.sanitizePlaca(null);
        expect(result, '');
      });
    });

    group('sanitizeSku', () {
      test('should convert to uppercase and remove invalid characters', () {
        final result = ValidationService.sanitizeSku('sku@001!');
        expect(result, 'SKU001');
      });

      test('should handle null input', () {
        final result = ValidationService.sanitizeSku(null);
        expect(result, '');
      });
    });
  });
}
