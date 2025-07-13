import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../core/services/validation_service.dart';
import '../core/exceptions/app_exceptions.dart';

class VhProgramado extends Equatable {
  final String vhId;
  final String placa;
  final DateTime fecha;
  final List<ProductoVh> productos;
  final String? estado;
  final String? conductor;
  final String? ruta;
  final String? flotaId; // Referencia a la colección flota
  final Map<String, dynamic>? flotaInfo; // Información de la flota

  const VhProgramado({
    required this.vhId,
    required this.placa,
    required this.fecha,
    required this.productos,
    this.estado,
    this.conductor,
    this.ruta,
    this.flotaId,
    this.flotaInfo,
  });

  /// Constructor con validaciones
  factory VhProgramado.create({
    required String vhId,
    required String placa,
    required DateTime fecha,
    required List<ProductoVh> productos,
    String? estado,
    String? conductor,
    String? ruta,
    String? flotaId,
    Map<String, dynamic>? flotaInfo,
  }) {
    // Validaciones
    ValidationService.validateRequired(vhId, 'VH ID').throwIfInvalid();
    ValidationService.validatePlaca(placa).throwIfInvalid();
    ValidationService.validateDateNotFuture(fecha, 'Fecha').throwIfInvalid();

    if (productos.isEmpty) {
      throw ValidationException.custom('El VH debe tener al menos un producto');
    }

    return VhProgramado(
      vhId: ValidationService.sanitizeText(vhId),
      placa: ValidationService.sanitizePlaca(placa),
      fecha: fecha,
      productos: productos,
      estado: estado != null ? ValidationService.sanitizeText(estado) : null,
      conductor: conductor != null ? ValidationService.sanitizeText(conductor) : null,
      ruta: ruta != null ? ValidationService.sanitizeText(ruta) : null,
      flotaId: flotaId != null ? ValidationService.sanitizeText(flotaId) : null,
      flotaInfo: flotaInfo,
    );
  }

  @override
  List<Object?> get props => [
        vhId,
        placa,
        fecha,
        productos,
        estado,
        conductor,
        ruta,
        flotaId,
        flotaInfo,
      ];

  factory VhProgramado.fromMap(Map<String, dynamic> map) {
    try {
      return VhProgramado(
        vhId: map['vh_id'] ?? '',
        placa: map['placa'] ?? '',
        fecha: map['fecha'] is Timestamp
            ? (map['fecha'] as Timestamp).toDate()
            : map['fecha'] is String
                ? DateTime.tryParse(map['fecha']) ?? DateTime.now()
                : DateTime.now(),
        productos: (map['productos'] as List<dynamic>? ?? [])
            .map((p) => ProductoVh.fromMap(p as Map<String, dynamic>))
            .toList(),
        estado: map['estado'],
        conductor: map['conductor'],
        ruta: map['ruta'],
        flotaId: map['flota_id'],
        flotaInfo: map['flota_info'] as Map<String, dynamic>?,
      );
    } catch (e) {
      throw ValidationException.custom('Error al parsear VhProgramado: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'vh_id': vhId,
      'placa': placa,
      'fecha': fecha,
      'productos': productos.map((p) => p.toMap()).toList(),
      'estado': estado,
      'conductor': conductor,
      'ruta': ruta,
      'flota_id': flotaId,
      'flota_info': flotaInfo,
    };
  }

  /// Crear mapa para Firestore (con Timestamps)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'vh_id': vhId,
      'placa': placa,
      'fecha': Timestamp.fromDate(fecha),
      'productos': productos.map((p) => p.toMap()).toList(),
      'estado': estado,
      'conductor': conductor,
      'ruta': ruta,
      'flota_id': flotaId,
      'flota_info': flotaInfo,
    };
  }

  /// Verificar si el VH está programado para hoy
  bool get isProgrammedForToday {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return fecha.isAfter(startOfDay) && fecha.isBefore(endOfDay);
  }

  /// Obtener total de productos programados
  int get totalProductos => productos.fold(0, (total, p) => total + p.cantidadProgramada);

  /// Verificar si el modelo es válido
  bool get isValid {
    try {
      ValidationService.validateRequired(vhId, 'VH ID').throwIfInvalid();
      ValidationService.validatePlaca(placa).throwIfInvalid();
      return productos.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  String toString() {
    return 'VhProgramado(vhId: $vhId, placa: $placa, fecha: $fecha, productos: ${productos.length})';
  }
}

class ProductoVh extends Equatable {
  final String sku;
  final String descripcion;
  final int cantidadProgramada;
  final String? unidad;
  final String? categoria;
  final double? peso;

  const ProductoVh({
    required this.sku,
    required this.descripcion,
    required this.cantidadProgramada,
    this.unidad,
    this.categoria,
    this.peso,
  });

  /// Constructor con validaciones
  factory ProductoVh.create({
    required String sku,
    required String descripcion,
    required int cantidadProgramada,
    String? unidad,
    String? categoria,
    double? peso,
  }) {
    // Validaciones
    ValidationService.validateSku(sku).throwIfInvalid();
    ValidationService.validateRequired(descripcion, 'Descripción').throwIfInvalid();
    ValidationService.validateQuantity(cantidadProgramada.toString()).throwIfInvalid();

    return ProductoVh(
      sku: ValidationService.sanitizeSku(sku),
      descripcion: ValidationService.sanitizeText(descripcion),
      cantidadProgramada: cantidadProgramada,
      unidad: unidad != null ? ValidationService.sanitizeText(unidad) : null,
      categoria: categoria != null ? ValidationService.sanitizeText(categoria) : null,
      peso: peso,
    );
  }

  @override
  List<Object?> get props => [
        sku,
        descripcion,
        cantidadProgramada,
        unidad,
        categoria,
        peso,
      ];

  factory ProductoVh.fromMap(Map<String, dynamic> map) {
    try {
      return ProductoVh(
        sku: map['sku'] ?? '',
        descripcion: map['descripcion'] ?? '',
        cantidadProgramada: map['cantidad_programada'] ?? 0,
        unidad: map['unidad'],
        categoria: map['categoria'],
        peso: map['peso']?.toDouble(),
      );
    } catch (e) {
      throw ValidationException.custom('Error al parsear ProductoVh: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'sku': sku,
      'descripcion': descripcion,
      'cantidad_programada': cantidadProgramada,
      'unidad': unidad,
      'categoria': categoria,
      'peso': peso,
    };
  }

  /// Verificar si el modelo es válido
  bool get isValid {
    try {
      ValidationService.validateSku(sku).throwIfInvalid();
      ValidationService.validateRequired(descripcion, 'Descripción').throwIfInvalid();
      ValidationService.validateQuantity(cantidadProgramada.toString()).throwIfInvalid();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtener peso total (cantidad * peso unitario)
  double? get pesoTotal => peso != null ? cantidadProgramada * peso! : null;

  @override
  String toString() {
    return 'ProductoVh(sku: $sku, descripcion: $descripcion, cantidad: $cantidadProgramada)';
  }
}

class ConteoVh {
  final String? id;
  final DateTime fecha;
  final String verificadorUid;
  final String verificadorNombre;
  final String vhId;
  final String placa;
  final bool tieneNovedad;
  final List<NovedadConteo>? novedades;
  final DateTime fechaCreacion;

  ConteoVh({
    this.id,
    required this.fecha,
    required this.verificadorUid,
    required this.verificadorNombre,
    required this.vhId,
    required this.placa,
    required this.tieneNovedad,
    this.novedades,
    required this.fechaCreacion,
  });

  factory ConteoVh.fromMap(Map<String, dynamic> map) {
    return ConteoVh(
      id: map['id'],
      fecha: map['fecha']?.toDate() ?? DateTime.now(),
      verificadorUid: map['verificador_uid'] ?? '',
      verificadorNombre: map['verificador_nombre'] ?? '',
      vhId: map['vh_id'] ?? '',
      placa: map['placa'] ?? '',
      tieneNovedad: map['tiene_novedad'] ?? false,
      novedades: (map['novedades'] as List<dynamic>? ?? [])
          .map((n) => NovedadConteo.fromMap(n))
          .toList(),
      fechaCreacion: map['fecha_creacion']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fecha': fecha,
      'verificador_uid': verificadorUid,
      'verificador_nombre': verificadorNombre,
      'vh_id': vhId,
      'placa': placa,
      'tiene_novedad': tieneNovedad,
      'novedades': novedades?.map((n) => n.toMap()).toList(),
      'fecha_creacion': fechaCreacion,
    };
  }
}

// Clase VhSegundoConteo movida al final del archivo para evitar duplicados

class ProductoSegundoConteo extends Equatable {
  final String sku;
  final String descripcion;
  final int cantidadProgramada;
  final int cantidadContada;
  final String? unidad;
  final String? observaciones;

  const ProductoSegundoConteo({
    required this.sku,
    required this.descripcion,
    required this.cantidadProgramada,
    required this.cantidadContada,
    this.unidad,
    this.observaciones,
  });

  @override
  List<Object?> get props => [
        sku,
        descripcion,
        cantidadProgramada,
        cantidadContada,
        unidad,
        observaciones,
      ];

  factory ProductoSegundoConteo.fromMap(Map<String, dynamic> map) {
    return ProductoSegundoConteo(
      sku: map['sku'] ?? '',
      descripcion: map['descripcion'] ?? '',
      cantidadProgramada: map['cantidad_programada'] ?? 0,
      cantidadContada: map['cantidad_contada'] ?? 0,
      unidad: map['unidad'],
      observaciones: map['observaciones'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sku': sku,
      'descripcion': descripcion,
      'cantidad_programada': cantidadProgramada,
      'cantidad_contada': cantidadContada,
      'unidad': unidad,
      'observaciones': observaciones,
    };
  }

  /// Calcular diferencia
  int get diferencia => cantidadContada - cantidadProgramada;

  /// Verificar si hay diferencia
  bool get tieneDiferencia => diferencia != 0;

  /// Tipo de diferencia
  String get tipoDiferencia {
    if (diferencia > 0) return 'Sobrante';
    if (diferencia < 0) return 'Faltante';
    return 'Sin diferencia';
  }

  @override
  String toString() {
    return 'ProductoSegundoConteo(sku: $sku, programada: $cantidadProgramada, contada: $cantidadContada)';
  }
}

class NovedadConteo {
  final String tipo; // 'Faltante' o 'Sobrante'
  final String dt;
  final String sku;
  final String descripcion;
  final int alistado;
  final int fisico;
  final int diferencia;
  final int verificado;
  final String armador;

  NovedadConteo({
    required this.tipo,
    required this.dt,
    required this.sku,
    required this.descripcion,
    required this.alistado,
    required this.fisico,
    required this.diferencia,
    required this.verificado,
    required this.armador,
  });

  factory NovedadConteo.fromMap(Map<String, dynamic> map) {
    return NovedadConteo(
      tipo: map['tipo'] ?? '',
      dt: map['dt'] ?? '',
      sku: map['sku'] ?? '',
      descripcion: map['descripcion'] ?? '',
      alistado: map['alistado'] ?? 0,
      fisico: map['fisico'] ?? 0,
      diferencia: map['diferencia'] ?? 0,
      verificado: map['verificado'] ?? 0,
      armador: map['armador'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'dt': dt,
      'sku': sku,
      'descripcion': descripcion,
      'alistado': alistado,
      'fisico': fisico,
      'diferencia': diferencia,
      'verificado': verificado,
      'armador': armador,
    };
  }
}

/// Modelo simplificado para el segundo conteo
class VhSegundoConteo extends Equatable {
  final String placa;
  final DateTime fechaConteo;
  final String verificadorUid;
  final String verificadorNombre;
  final bool tieneNovedad;
  final List<NovedadConteo> novedades;
  final DateTime timestamp;
  final String? observaciones;

  const VhSegundoConteo({
    required this.placa,
    required this.fechaConteo,
    required this.verificadorUid,
    required this.verificadorNombre,
    required this.tieneNovedad,
    required this.novedades,
    required this.timestamp,
    this.observaciones,
  });

  factory VhSegundoConteo.create({
    required String placa,
    required String verificadorUid,
    required String verificadorNombre,
    required bool tieneNovedad,
    List<NovedadConteo>? novedades,
    String? observaciones,
  }) {
    // Validaciones
    ValidationService.validateRequired(placa, 'Placa').throwIfInvalid();
    ValidationService.validatePlaca(placa).throwIfInvalid();
    ValidationService.validateRequired(verificadorUid, 'Verificador UID').throwIfInvalid();
    ValidationService.validateRequired(verificadorNombre, 'Verificador Nombre').throwIfInvalid();

    final now = DateTime.now();
    return VhSegundoConteo(
      placa: placa.toUpperCase(),
      fechaConteo: DateTime(now.year, now.month, now.day),
      verificadorUid: verificadorUid,
      verificadorNombre: verificadorNombre,
      tieneNovedad: tieneNovedad,
      novedades: novedades ?? [],
      timestamp: now,
      observaciones: observaciones,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'placa': placa,
      'fechaConteo': Timestamp.fromDate(fechaConteo),
      'verificadorUid': verificadorUid,
      'verificadorNombre': verificadorNombre,
      'tieneNovedad': tieneNovedad,
      'novedades': novedades.map((n) => n.toMap()).toList(),
      'timestamp': Timestamp.fromDate(timestamp),
      'observaciones': observaciones,
    };
  }

  factory VhSegundoConteo.fromMap(Map<String, dynamic> map) {
    return VhSegundoConteo(
      placa: map['placa'] ?? '',
      fechaConteo: (map['fechaConteo'] as Timestamp).toDate(),
      verificadorUid: map['verificadorUid'] ?? '',
      verificadorNombre: map['verificadorNombre'] ?? '',
      tieneNovedad: map['tieneNovedad'] ?? false,
      novedades: (map['novedades'] as List<dynamic>?)
          ?.map((n) => NovedadConteo.fromMap(n as Map<String, dynamic>))
          .toList() ?? [],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      observaciones: map['observaciones'],
    );
  }

  VhSegundoConteo copyWith({
    String? placa,
    DateTime? fechaConteo,
    String? verificadorUid,
    String? verificadorNombre,
    bool? tieneNovedad,
    List<NovedadConteo>? novedades,
    DateTime? timestamp,
    String? observaciones,
  }) {
    return VhSegundoConteo(
      placa: placa ?? this.placa,
      fechaConteo: fechaConteo ?? this.fechaConteo,
      verificadorUid: verificadorUid ?? this.verificadorUid,
      verificadorNombre: verificadorNombre ?? this.verificadorNombre,
      tieneNovedad: tieneNovedad ?? this.tieneNovedad,
      novedades: novedades ?? this.novedades,
      timestamp: timestamp ?? this.timestamp,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  @override
  List<Object?> get props => [
    placa,
    fechaConteo,
    verificadorUid,
    verificadorNombre,
    tieneNovedad,
    novedades,
    timestamp,
    observaciones,
  ];
}