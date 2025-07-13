class SkuModel {
  final String sku;
  final String descripcion;
  final String unidad;
  final String categoria;
  final DateTime? fechaActualizacion;

  SkuModel({
    required this.sku,
    required this.descripcion,
    required this.unidad,
    required this.categoria,
    this.fechaActualizacion,
  });

  factory SkuModel.fromMap(Map<String, dynamic> map) {
    return SkuModel(
      sku: map['sku'] ?? '',
      descripcion: map['descripcion'] ?? '',
      unidad: map['unidad'] ?? '',
      categoria: map['categoria'] ?? '',
      fechaActualizacion: map['fecha_actualizacion']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sku': sku,
      'descripcion': descripcion,
      'unidad': unidad,
      'categoria': categoria,
      'fecha_actualizacion': fechaActualizacion,
    };
  }
}

class AuxiliarModel {
  final String nombre;
  final String cedula;
  final String cargo;
  final String correo;
  final String telefono;
  final bool activo;

  AuxiliarModel({
    required this.nombre,
    required this.cedula,
    required this.cargo,
    required this.correo,
    required this.telefono,
    this.activo = true,
  });

  factory AuxiliarModel.fromMap(Map<String, dynamic> map) {
    return AuxiliarModel(
      nombre: map['nombre'] ?? '',
      cedula: map['cedula'] ?? '',
      cargo: map['cargo'] ?? '',
      correo: map['correo'] ?? '',
      telefono: map['telefono'] ?? '',
      activo: map['activo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'cedula': cedula,
      'cargo': cargo,
      'correo': correo,
      'telefono': telefono,
      'activo': activo,
    };
  }
}

class InventarioModel {
  final String sku;
  final int stock;
  final String ubicacion;
  final DateTime fechaActualizacion;
  final String? observaciones;

  InventarioModel({
    required this.sku,
    required this.stock,
    required this.ubicacion,
    required this.fechaActualizacion,
    this.observaciones,
  });

  factory InventarioModel.fromMap(Map<String, dynamic> map) {
    return InventarioModel(
      sku: map['sku'] ?? '',
      stock: map['stock'] ?? 0,
      ubicacion: map['ubicacion'] ?? '',
      fechaActualizacion: map['fecha_actualizacion']?.toDate() ?? DateTime.now(),
      observaciones: map['observaciones'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sku': sku,
      'stock': stock,
      'ubicacion': ubicacion,
      'fecha_actualizacion': fechaActualizacion,
      'observaciones': observaciones,
    };
  }
}