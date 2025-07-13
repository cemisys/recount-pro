import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/sku_model.dart';
import '../utils/logger.dart';
import '../utils/error_handler.dart';
import '../exceptions/app_exceptions.dart';

/// Repositorio para manejar operaciones relacionadas con SKUs
class SkuRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtener todos los SKUs ordenados por descripción
  Future<List<SkuModel>> getAllSkus() async {
    try {
      Logger.firebaseOperation('QUERY', 'sku', {'orderBy': 'descripcion'});
      
      final querySnapshot = await _firestore
          .collection('sku')
          .orderBy('descripcion')
          .get();
      
      final skus = querySnapshot.docs
          .map((doc) => SkuModel.fromMap(doc.data()))
          .toList();
      
      Logger.info('SKUs obtenidos: ${skus.length}');
      return skus;
    } catch (e, stackTrace) {
      Logger.error('Error obteniendo SKUs', e, stackTrace);
      throw ErrorHandler.handleGenericError(e, stackTrace);
    }
  }

  /// Buscar SKU por código
  Future<SkuModel?> getSkuByCodigo(String codigo) async {
    try {
      if (codigo.trim().isEmpty) {
        throw ValidationException.required('código SKU');
      }

      Logger.firebaseOperation('GET', 'sku', {'codigo': codigo});
      
      final doc = await _firestore
          .collection('sku')
          .doc(codigo.trim().toUpperCase())
          .get();
      
      if (!doc.exists) {
        Logger.info('SKU no encontrado: $codigo');
        return null;
      }
      
      final sku = SkuModel.fromMap(doc.data()!);
      Logger.info('SKU encontrado: ${sku.sku} - ${sku.descripcion}');
      return sku;
    } catch (e, stackTrace) {
      Logger.error('Error buscando SKU por código', e, stackTrace);
      throw ErrorHandler.handleGenericError(e, stackTrace);
    }
  }

  /// Buscar SKUs por descripción (búsqueda parcial)
  Future<List<SkuModel>> searchSkusByDescripcion(String descripcion) async {
    try {
      if (descripcion.trim().isEmpty) {
        return [];
      }

      Logger.firebaseOperation('QUERY', 'sku', {
        'search_type': 'descripcion',
        'query': descripcion
      });
      
      // Firestore no soporta búsqueda de texto completo nativa,
      // por lo que usamos un rango de búsqueda por prefijo
      final searchTerm = descripcion.trim().toLowerCase();
      final endTerm = searchTerm.substring(0, searchTerm.length - 1) + 
          String.fromCharCode(searchTerm.codeUnitAt(searchTerm.length - 1) + 1);
      
      final querySnapshot = await _firestore
          .collection('sku')
          .where('descripcion_lower', isGreaterThanOrEqualTo: searchTerm)
          .where('descripcion_lower', isLessThan: endTerm)
          .limit(20)
          .get();
      
      final skus = querySnapshot.docs
          .map((doc) => SkuModel.fromMap(doc.data()))
          .toList();
      
      Logger.info('SKUs encontrados por descripción "$descripcion": ${skus.length}');
      return skus;
    } catch (e, stackTrace) {
      Logger.error('Error buscando SKUs por descripción', e, stackTrace);
      throw ErrorHandler.handleGenericError(e, stackTrace);
    }
  }

  /// Obtener SKUs por categoría
  Future<List<SkuModel>> getSkusByCategoria(String categoria) async {
    try {
      if (categoria.trim().isEmpty) {
        throw ValidationException.required('categoría');
      }

      Logger.firebaseOperation('QUERY', 'sku', {'categoria': categoria});
      
      final querySnapshot = await _firestore
          .collection('sku')
          .where('categoria', isEqualTo: categoria.trim())
          .orderBy('descripcion')
          .get();
      
      final skus = querySnapshot.docs
          .map((doc) => SkuModel.fromMap(doc.data()))
          .toList();
      
      Logger.info('SKUs obtenidos por categoría "$categoria": ${skus.length}');
      return skus;
    } catch (e, stackTrace) {
      Logger.error('Error obteniendo SKUs por categoría', e, stackTrace);
      throw ErrorHandler.handleGenericError(e, stackTrace);
    }
  }

  /// Obtener todas las categorías disponibles
  Future<List<String>> getCategorias() async {
    try {
      Logger.firebaseOperation('QUERY', 'sku', {'distinct': 'categoria'});
      
      final querySnapshot = await _firestore
          .collection('sku')
          .get();
      
      final categorias = querySnapshot.docs
          .map((doc) => doc.data()['categoria'] as String?)
          .where((categoria) => categoria != null && categoria.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      
      categorias.sort();
      
      Logger.info('Categorías obtenidas: ${categorias.length}');
      return categorias;
    } catch (e, stackTrace) {
      Logger.error('Error obteniendo categorías', e, stackTrace);
      throw ErrorHandler.handleGenericError(e, stackTrace);
    }
  }

  /// Validar que un SKU existe
  Future<bool> skuExists(String codigo) async {
    try {
      if (codigo.trim().isEmpty) {
        return false;
      }

      final sku = await getSkuByCodigo(codigo);
      return sku != null;
    } catch (e, stackTrace) {
      Logger.error('Error validando existencia de SKU', e, stackTrace);
      return false;
    }
  }
}

/// Modelo para auxiliares/armadores
class AuxiliarModel {
  final String cedula;
  final String nombre;
  final String cargo;
  final String? correo;
  final String? telefono;
  final bool activo;

  AuxiliarModel({
    required this.cedula,
    required this.nombre,
    required this.cargo,
    this.correo,
    this.telefono,
    this.activo = true,
  });

  factory AuxiliarModel.fromMap(Map<String, dynamic> map) {
    return AuxiliarModel(
      cedula: map['cedula'] ?? '',
      nombre: map['nombre'] ?? '',
      cargo: map['cargo'] ?? '',
      correo: map['correo'],
      telefono: map['telefono'],
      activo: map['activo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cedula': cedula,
      'nombre': nombre,
      'cargo': cargo,
      'correo': correo,
      'telefono': telefono,
      'activo': activo,
    };
  }
}

/// Repositorio para manejar operaciones relacionadas con auxiliares
class AuxiliarRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtener todos los auxiliares activos
  Future<List<AuxiliarModel>> getAuxiliaresActivos() async {
    try {
      Logger.firebaseOperation('QUERY', 'auxiliares', {'activo': true});
      
      final querySnapshot = await _firestore
          .collection('auxiliares')
          .where('activo', isEqualTo: true)
          .orderBy('nombre')
          .get();
      
      final auxiliares = querySnapshot.docs
          .map((doc) => AuxiliarModel.fromMap(doc.data()))
          .toList();
      
      Logger.info('Auxiliares activos obtenidos: ${auxiliares.length}');
      return auxiliares;
    } catch (e, stackTrace) {
      Logger.error('Error obteniendo auxiliares activos', e, stackTrace);
      throw ErrorHandler.handleGenericError(e, stackTrace);
    }
  }

  /// Obtener auxiliares por cargo (ej: armadores)
  Future<List<AuxiliarModel>> getAuxiliaresPorCargo(String cargo) async {
    try {
      if (cargo.trim().isEmpty) {
        throw ValidationException.required('cargo');
      }

      Logger.firebaseOperation('QUERY', 'auxiliares', {
        'cargo': cargo,
        'activo': true
      });
      
      final querySnapshot = await _firestore
          .collection('auxiliares')
          .where('activo', isEqualTo: true)
          .orderBy('nombre')
          .get();
      
      // Filtrar por cargo (búsqueda case-insensitive)
      final auxiliares = querySnapshot.docs
          .map((doc) => AuxiliarModel.fromMap(doc.data()))
          .where((aux) => aux.cargo.toLowerCase().contains(cargo.toLowerCase()))
          .toList();
      
      Logger.info('Auxiliares obtenidos por cargo "$cargo": ${auxiliares.length}');
      return auxiliares;
    } catch (e, stackTrace) {
      Logger.error('Error obteniendo auxiliares por cargo', e, stackTrace);
      throw ErrorHandler.handleGenericError(e, stackTrace);
    }
  }
}
