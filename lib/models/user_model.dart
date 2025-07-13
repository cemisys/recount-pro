import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../core/services/validation_service.dart';
import '../core/exceptions/app_exceptions.dart';

class UserModel extends Equatable {
  final String uid;
  final String nombre;
  final String correo;
  final String rol;
  final DateTime? fechaCreacion;
  final bool activo;
  final DateTime? ultimoAcceso;

  const UserModel({
    required this.uid,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.fechaCreacion,
    this.activo = true,
    this.ultimoAcceso,
  });

  /// Constructor con validaciones
  factory UserModel.create({
    required String uid,
    required String nombre,
    required String correo,
    required String rol,
    DateTime? fechaCreacion,
    bool activo = true,
    DateTime? ultimoAcceso,
  }) {
    // Validaciones
    ValidationService.validateRequired(uid, 'UID').throwIfInvalid();
    ValidationService.validateRequired(nombre, 'Nombre').throwIfInvalid();
    ValidationService.validateEmail(correo).throwIfInvalid();
    ValidationService.validateRequired(rol, 'Rol').throwIfInvalid();

    // Validar rol válido
    const rolesValidos = ['verificador', 'supervisor', 'admin'];
    if (!rolesValidos.contains(rol.toLowerCase())) {
      throw ValidationException.custom('Rol inválido: $rol');
    }

    return UserModel(
      uid: ValidationService.sanitizeText(uid),
      nombre: ValidationService.sanitizeText(nombre),
      correo: ValidationService.sanitizeText(correo).toLowerCase(),
      rol: rol.toLowerCase(),
      fechaCreacion: fechaCreacion,
      activo: activo,
      ultimoAcceso: ultimoAcceso,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        nombre,
        correo,
        rol,
        fechaCreacion,
        activo,
        ultimoAcceso,
      ];

  factory UserModel.fromMap(Map<String, dynamic> map) {
    try {
      return UserModel(
        uid: map['uid'] ?? '',
        nombre: map['nombre'] ?? '',
        correo: map['correo'] ?? '',
        rol: map['rol'] ?? 'verificador',
        fechaCreacion: map['fechaCreacion'] is Timestamp
            ? (map['fechaCreacion'] as Timestamp).toDate()
            : map['fechaCreacion'] is String
                ? DateTime.tryParse(map['fechaCreacion'])
                : null,
        activo: map['activo'] ?? true,
        ultimoAcceso: map['ultimoAcceso'] is Timestamp
            ? (map['ultimoAcceso'] as Timestamp).toDate()
            : map['ultimoAcceso'] is String
                ? DateTime.tryParse(map['ultimoAcceso'])
                : null,
      );
    } catch (e) {
      throw ValidationException.custom('Error al parsear UserModel: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'fechaCreacion': fechaCreacion,
      'activo': activo,
      'ultimoAcceso': ultimoAcceso,
    };
  }

  /// Crear mapa para Firestore (con Timestamps)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'fechaCreacion': fechaCreacion != null ? Timestamp.fromDate(fechaCreacion!) : null,
      'activo': activo,
      'ultimoAcceso': ultimoAcceso != null ? Timestamp.fromDate(ultimoAcceso!) : null,
    };
  }

  UserModel copyWith({
    String? uid,
    String? nombre,
    String? correo,
    String? rol,
    DateTime? fechaCreacion,
    bool? activo,
    DateTime? ultimoAcceso,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      activo: activo ?? this.activo,
      ultimoAcceso: ultimoAcceso ?? this.ultimoAcceso,
    );
  }

  /// Actualizar último acceso
  UserModel updateLastAccess() {
    return copyWith(ultimoAcceso: DateTime.now());
  }

  /// Verificar si el usuario está activo
  bool get isActive => activo;

  /// Verificar si es administrador
  bool get isAdmin => rol == 'admin';

  /// Verificar si es supervisor o admin
  bool get isSupervisorOrAdmin => rol == 'supervisor' || rol == 'admin';

  /// Obtener nombre para mostrar
  String get displayName => nombre.isNotEmpty ? nombre : correo.split('@').first;

  /// Métodos de permisos basados en rol
  bool get canManageUsers => rol == 'admin';
  bool get canManageData => rol == 'admin' || rol == 'supervisor';
  bool get canViewReports => rol == 'admin' || rol == 'supervisor' || rol == 'verificador';
  bool get canPerformCounts => rol == 'admin' || rol == 'supervisor' || rol == 'verificador';
  bool get canAccessAdmin => rol == 'admin';

  /// Alias para compatibilidad
  String get email => correo;

  /// Validar que el modelo es válido
  bool get isValid {
    try {
      ValidationService.validateRequired(uid, 'UID').throwIfInvalid();
      ValidationService.validateRequired(nombre, 'Nombre').throwIfInvalid();
      ValidationService.validateEmail(correo).throwIfInvalid();
      ValidationService.validateRequired(rol, 'Rol').throwIfInvalid();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, nombre: $nombre, correo: $correo, rol: $rol, activo: $activo)';
  }
}