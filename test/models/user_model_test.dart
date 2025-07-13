import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recount_pro/models/user_model.dart';

void main() {
  group('UserModel', () {
    const testUid = 'test-uid-123';
    const testNombre = 'Juan Pérez';
    const testCorreo = 'juan.perez@example.com';
    const testRol = 'verificador';
    final testFechaCreacion = DateTime(2024, 1, 15, 10, 30);

    group('Constructor', () {
      test('should create UserModel with all required fields', () {
        final user = UserModel(
          uid: testUid,
          nombre: testNombre,
          correo: testCorreo,
          rol: testRol,
          fechaCreacion: testFechaCreacion,
        );

        expect(user.uid, testUid);
        expect(user.nombre, testNombre);
        expect(user.correo, testCorreo);
        expect(user.rol, testRol);
        expect(user.fechaCreacion, testFechaCreacion);
      });

      test('should create UserModel without optional fechaCreacion', () {
        const user = UserModel(
          uid: testUid,
          nombre: testNombre,
          correo: testCorreo,
          rol: testRol,
        );

        expect(user.uid, testUid);
        expect(user.nombre, testNombre);
        expect(user.correo, testCorreo);
        expect(user.rol, testRol);
        expect(user.fechaCreacion, null);
      });
    });

    group('fromMap', () {
      test('should create UserModel from complete map', () {
        final map = {
          'uid': testUid,
          'nombre': testNombre,
          'correo': testCorreo,
          'rol': testRol,
          'fechaCreacion': Timestamp.fromDate(testFechaCreacion),
        };

        final user = UserModel.fromMap(map);

        expect(user.uid, testUid);
        expect(user.nombre, testNombre);
        expect(user.correo, testCorreo);
        expect(user.rol, testRol);
        expect(user.fechaCreacion, testFechaCreacion);
      });

      test('should create UserModel from map with missing optional fields', () {
        final map = {
          'uid': testUid,
          'nombre': testNombre,
          'correo': testCorreo,
          'rol': testRol,
        };

        final user = UserModel.fromMap(map);

        expect(user.uid, testUid);
        expect(user.nombre, testNombre);
        expect(user.correo, testCorreo);
        expect(user.rol, testRol);
        expect(user.fechaCreacion, null);
      });

      test('should handle empty map with default values', () {
        final map = <String, dynamic>{};

        final user = UserModel.fromMap(map);

        expect(user.uid, '');
        expect(user.nombre, '');
        expect(user.correo, '');
        expect(user.rol, 'verificador');
        expect(user.fechaCreacion, null);
      });

      test('should handle null values in map', () {
        final map = {
          'uid': null,
          'nombre': null,
          'correo': null,
          'rol': null,
          'fechaCreacion': null,
        };

        final user = UserModel.fromMap(map);

        expect(user.uid, '');
        expect(user.nombre, '');
        expect(user.correo, '');
        expect(user.rol, 'verificador');
        expect(user.fechaCreacion, null);
      });
    });

    group('toMap', () {
      test('should convert UserModel to map with all fields', () {
        final user = UserModel(
          uid: testUid,
          nombre: testNombre,
          correo: testCorreo,
          rol: testRol,
          fechaCreacion: testFechaCreacion,
        );

        final map = user.toMap();

        expect(map['uid'], testUid);
        expect(map['nombre'], testNombre);
        expect(map['correo'], testCorreo);
        expect(map['rol'], testRol);
        expect(map['fechaCreacion'], testFechaCreacion);
      });

      test('should convert UserModel to map with null fechaCreacion', () {
        const user = UserModel(
          uid: testUid,
          nombre: testNombre,
          correo: testCorreo,
          rol: testRol,
        );

        final map = user.toMap();

        expect(map['uid'], testUid);
        expect(map['nombre'], testNombre);
        expect(map['correo'], testCorreo);
        expect(map['rol'], testRol);
        expect(map['fechaCreacion'], null);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        final originalUser = UserModel(
          uid: testUid,
          nombre: testNombre,
          correo: testCorreo,
          rol: testRol,
          fechaCreacion: testFechaCreacion,
        );

        const newNombre = 'María García';
        const newRol = 'supervisor';

        final updatedUser = originalUser.copyWith(
          nombre: newNombre,
          rol: newRol,
        );

        expect(updatedUser.uid, testUid); // unchanged
        expect(updatedUser.nombre, newNombre); // changed
        expect(updatedUser.correo, testCorreo); // unchanged
        expect(updatedUser.rol, newRol); // changed
        expect(updatedUser.fechaCreacion, testFechaCreacion); // unchanged
      });

      test('should create identical copy when no parameters provided', () {
        final originalUser = UserModel(
          uid: testUid,
          nombre: testNombre,
          correo: testCorreo,
          rol: testRol,
          fechaCreacion: testFechaCreacion,
        );

        final copiedUser = originalUser.copyWith();

        expect(copiedUser.uid, originalUser.uid);
        expect(copiedUser.nombre, originalUser.nombre);
        expect(copiedUser.correo, originalUser.correo);
        expect(copiedUser.rol, originalUser.rol);
        expect(copiedUser.fechaCreacion, originalUser.fechaCreacion);
      });

      test('should handle null values in copyWith', () {
        final originalUser = UserModel(
          uid: testUid,
          nombre: testNombre,
          correo: testCorreo,
          rol: testRol,
          fechaCreacion: testFechaCreacion,
        );

        final updatedUser = originalUser.copyWith(
          fechaCreacion: null,
        );

        expect(updatedUser.uid, testUid);
        expect(updatedUser.nombre, testNombre);
        expect(updatedUser.correo, testCorreo);
        expect(updatedUser.rol, testRol);
        expect(updatedUser.fechaCreacion, isNotNull); // copyWith no debería permitir null
      });
    });

    group('Equality and toString', () {
      test('should be equal when all fields are the same', () {
        final user1 = UserModel(
          uid: testUid,
          nombre: testNombre,
          correo: testCorreo,
          rol: testRol,
          fechaCreacion: testFechaCreacion,
        );

        final user2 = UserModel(
          uid: testUid,
          nombre: testNombre,
          correo: testCorreo,
          rol: testRol,
          fechaCreacion: testFechaCreacion,
        );

        // UserModel uses Equatable, so should be equal when all fields are same
        expect(user1 == user2, true);
        expect(user1.uid == user2.uid, true);
        expect(user1.nombre == user2.nombre, true);
      });
    });
  });
}
