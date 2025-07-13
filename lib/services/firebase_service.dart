import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vh_model.dart';
import '../models/sku_model.dart';
import '../core/utils/logger.dart';

class FirebaseService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Estadísticas del verificador
  int _vhContadosHoy = 0;
  int _vhProgramadosHoy = 0;
  int _erroresDelMes = 0;
  
  int get vhContadosHoy => _vhContadosHoy;
  int get vhProgramadosHoy => _vhProgramadosHoy;
  int get erroresDelMes => _erroresDelMes;
  double get porcentajeAvance => _vhProgramadosHoy > 0 
      ? (_vhContadosHoy / _vhProgramadosHoy) * 100 
      : 0.0;

  // Obtener VH programados para hoy
  Future<List<VhProgramado>> getVhProgramadosHoy() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      Logger.firebaseOperation('QUERY', 'vh_programados', {'fecha_range': 'today'});

      final querySnapshot = await _firestore
          .collection('vh_programados')
          .where('fecha', isGreaterThanOrEqualTo: startOfDay)
          .where('fecha', isLessThan: endOfDay)
          .get();

      final vhProgramados = querySnapshot.docs
          .map((doc) => VhProgramado.fromMap(doc.data()))
          .toList();

      Logger.info('VH programados para hoy: ${vhProgramados.length}');
      return vhProgramados;
    } catch (e, stackTrace) {
      Logger.error('Error obteniendo VH programados', e, stackTrace);
      return [];
    }
  }

  // Obtener conteos del día actual para un verificador
  Future<List<ConteoVh>> getConteosHoy(String verificadorUid) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      Logger.firebaseOperation('QUERY', 'conteos', {
        'verificador_uid': verificadorUid,
        'fecha_range': 'today'
      });

      final querySnapshot = await _firestore
          .collection('conteos')
          .where('verificador_uid', isEqualTo: verificadorUid)
          .where('fecha', isGreaterThanOrEqualTo: startOfDay)
          .where('fecha', isLessThan: endOfDay)
          .orderBy('fecha', descending: true)
          .get();

      final conteos = querySnapshot.docs
          .map((doc) => ConteoVh.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      Logger.info('Conteos de hoy para verificador $verificadorUid: ${conteos.length}');
      return conteos;
    } catch (e, stackTrace) {
      Logger.error('Error obteniendo conteos', e, stackTrace);
      return [];
    }
  }

  // Guardar un nuevo conteo
  Future<bool> guardarConteo(ConteoVh conteo) async {
    try {
      Logger.firebaseOperation('ADD', 'conteos', conteo.toMap());
      await _firestore.collection('conteos').add(conteo.toMap());
      await _actualizarEstadisticas(conteo.verificadorUid);
      Logger.info('Conteo guardado exitosamente para VH: ${conteo.vhId}');
      return true;
    } catch (e, stackTrace) {
      Logger.error('Error guardando conteo', e, stackTrace);
      return false;
    }
  }

  // Obtener SKUs disponibles
  Future<List<SkuModel>> getSKUs() async {
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
      return [];
    }
  }

  // Buscar SKU por código
  Future<SkuModel?> buscarSKU(String skuCode) async {
    try {
      final doc = await _firestore
          .collection('sku')
          .doc(skuCode)
          .get();
      
      if (doc.exists) {
        return SkuModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error buscando SKU: $e');
      return null;
    }
  }

  // Obtener auxiliares disponibles
  Future<List<AuxiliarModel>> getAuxiliares() async {
    try {
      final querySnapshot = await _firestore
          .collection('auxiliares')
          .where('activo', isEqualTo: true)
          .orderBy('nombre')
          .get();
      
      return querySnapshot.docs
          .map((doc) => AuxiliarModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error obteniendo auxiliares: $e');
      return [];
    }
  }

  // Actualizar estadísticas del verificador
  Future<void> _actualizarEstadisticas(String verificadorUid) async {
    try {
      Logger.info('Actualizando estadísticas para verificador: $verificadorUid');

      // Contar VH del día
      final conteosHoy = await getConteosHoy(verificadorUid);
      _vhContadosHoy = conteosHoy.length;

      // Contar VH programados del día
      final vhProgramados = await getVhProgramadosHoy();
      _vhProgramadosHoy = vhProgramados.length;

      // Contar errores del mes
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1);

      Logger.firebaseOperation('QUERY', 'conteos', {
        'verificador_uid': verificadorUid,
        'tiene_novedad': true,
        'fecha_range': 'current_month'
      });

      final erroresSnapshot = await _firestore
          .collection('conteos')
          .where('verificador_uid', isEqualTo: verificadorUid)
          .where('tiene_novedad', isEqualTo: true)
          .where('fecha', isGreaterThanOrEqualTo: startOfMonth)
          .where('fecha', isLessThan: endOfMonth)
          .get();

      _erroresDelMes = erroresSnapshot.docs.length;

      Logger.info('Estadísticas actualizadas: VH contados: $_vhContadosHoy, VH programados: $_vhProgramadosHoy, Errores del mes: $_erroresDelMes');
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.error('Error actualizando estadísticas', e, stackTrace);
      // No lanzar la excepción para no interrumpir el flujo principal
    }
  }

  // Cargar estadísticas iniciales
  Future<void> cargarEstadisticas(String verificadorUid) async {
    await _actualizarEstadisticas(verificadorUid);
  }

  // Verificar si un VH ya fue contado hoy
  Future<bool> vhYaContado(String vhId, String verificadorUid) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final querySnapshot = await _firestore
          .collection('conteos')
          .where('vh_id', isEqualTo: vhId)
          .where('verificador_uid', isEqualTo: verificadorUid)
          .where('fecha', isGreaterThanOrEqualTo: startOfDay)
          .where('fecha', isLessThan: endOfDay)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error verificando VH: $e');
      return false;
    }
  }

  // Obtener VH por placa
  Future<VhProgramado?> getVhPorPlaca(String placa) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('vh_programados')
          .where('placa', isEqualTo: placa.toUpperCase())
          .where('fecha', isGreaterThanOrEqualTo: startOfDay)
          .where('fecha', isLessThan: endOfDay)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return VhProgramado.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error obteniendo VH por placa: $e');
      return null;
    }
  }

  /// Obtener placas disponibles para búsqueda incremental
  Future<List<String>> buscarPlacas(String query) async {
    try {
      print('🔍 [FIREBASE] Iniciando buscarPlacas con query: "$query"');

      if (query.isEmpty) {
        print('📝 [FIREBASE] Query vacío, retornando lista vacía');
        return [];
      }

      // Buscar en un rango más amplio: desde ayer hasta mañana
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final tomorrow = DateTime(now.year, now.month, now.day + 2);

      print('📅 [FIREBASE] Buscando VH programados en rango amplio:');
      print('  - Desde: $yesterday');
      print('  - Hasta: $tomorrow');

      // Primero intentar con filtro de fecha
      var querySnapshot = await _firestore
          .collection('vh_programados')
          .where('fecha', isGreaterThanOrEqualTo: yesterday)
          .where('fecha', isLessThan: tomorrow)
          .get();

      print('📊 [FIREBASE] Documentos encontrados con filtro de fecha: ${querySnapshot.docs.length}');

      // Si no hay resultados con filtro de fecha, buscar sin filtro
      if (querySnapshot.docs.isEmpty) {
        print('⚠️ [FIREBASE] No hay documentos con filtro de fecha, buscando sin filtro...');
        querySnapshot = await _firestore
            .collection('vh_programados')
            .limit(100) // Limitar para evitar cargar demasiados documentos
            .get();
        print('📊 [FIREBASE] Documentos encontrados sin filtro: ${querySnapshot.docs.length}');
      }

      print('📊 [FIREBASE] Documentos encontrados en vh_programados: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isEmpty) {
        print('❌ [FIREBASE] No hay VH programados para hoy');
        return [];
      }

      // Mostrar algunos documentos de ejemplo
      for (int i = 0; i < querySnapshot.docs.length && i < 3; i++) {
        final doc = querySnapshot.docs[i];
        final data = doc.data();
        print('  📄 Ejemplo ${i + 1}: ${doc.id} -> placa: ${data['placa']}, fecha: ${data['fecha']}');
      }

      final todasLasPlacas = querySnapshot.docs
          .map((doc) => doc.data()['placa'] as String? ?? '')
          .where((placa) => placa.isNotEmpty)
          .toList();

      print('🚛 [FIREBASE] Todas las placas encontradas: ${todasLasPlacas.length}');
      print('  Placas: ${todasLasPlacas.take(5).join(', ')}${todasLasPlacas.length > 5 ? '...' : ''}');

      // Debug: mostrar TODAS las placas para verificar qué hay en la colección
      if (todasLasPlacas.length <= 20) {
        print('🔍 [FIREBASE] TODAS las placas disponibles: ${todasLasPlacas.join(', ')}');
      } else {
        print('🔍 [FIREBASE] Primeras 20 placas: ${todasLasPlacas.take(20).join(', ')}...');
      }

      final placasFiltradas = todasLasPlacas
          .where((placa) => placa.toUpperCase().contains(query.toUpperCase()))
          .toSet() // Eliminar duplicados
          .toList();

      print('🔍 [FIREBASE] Placas que coinciden con "$query": ${placasFiltradas.length}');
      print('  Coincidencias: ${placasFiltradas.join(', ')}');

      placasFiltradas.sort(); // Ordenar alfabéticamente
      final resultado = placasFiltradas.take(10).toList(); // Limitar a 10 resultados

      print('✅ [FIREBASE] Resultado final: ${resultado.length} placas');
      return resultado;
    } catch (e, stackTrace) {
      print('❌ [FIREBASE] Error buscando placas: $e');
      print('📍 [FIREBASE] StackTrace: $stackTrace');
      Logger.error('Error buscando placas: $e');
      return [];
    }
  }

  /// Buscar SKUs de forma incremental para autocompletado en detalle de novedad
  Future<List<Map<String, String>>> buscarSkusIncremental(String query) async {
    try {
      if (query.isEmpty) return [];

      print('🔍 [FIREBASE] Consultando colección "sku" con query: "$query"');
      Logger.firebaseOperation('QUERY', 'sku', {'search': query});

      // Obtener todos los documentos de la colección sku
      final querySnapshot = await _firestore
          .collection('sku')
          .get();

      print('📊 [FIREBASE] Documentos encontrados en colección sku: ${querySnapshot.docs.length}');

      final skus = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            final sku = data['sku'] as String? ?? '';
            final descripcion = data['descripcion'] as String? ?? '';
            final activo = data['activo'] as bool? ?? true;

            print('  📄 Doc: ${doc.id} -> SKU: $sku, Desc: $descripcion, Activo: $activo');

            return {
              'sku': sku,
              'descripcion': descripcion,
              'activo': activo.toString(),
            };
          })
          .where((sku) =>
            sku['sku']!.isNotEmpty &&
            sku['descripcion']!.isNotEmpty &&
            (sku['sku']!.toUpperCase().contains(query.toUpperCase()) ||
             sku['descripcion']!.toUpperCase().contains(query.toUpperCase()))
          )
          .map((sku) => {
            'sku': sku['sku']!,
            'descripcion': sku['descripcion']!,
          })
          .toList();

      // Ordenar por SKU
      skus.sort((a, b) => a['sku']!.compareTo(b['sku']!));

      print('✅ [FIREBASE] SKUs filtrados para "$query": ${skus.length}');
      for (var sku in skus.take(5)) {
        print('  ✓ ${sku['sku']}: ${sku['descripcion']}');
      }

      Logger.info('SKUs encontrados para búsqueda incremental: ${skus.length}');
      return skus.take(10).toList(); // Limitar a 10 resultados
    } catch (e, stackTrace) {
      print('❌ [FIREBASE] Error buscando SKUs: $e');
      Logger.error('Error buscando SKUs incremental', e, stackTrace);
      return [];
    }
  }

  /// Buscar Verificadores de forma incremental para autocompletado en detalle de novedad
  Future<List<Map<String, String>>> buscarVerificadoresIncremental(String query) async {
    try {
      if (query.isEmpty) return [];

      print('🔍 [FIREBASE] Consultando colección "verificadores" con query: "$query"');
      Logger.firebaseOperation('QUERY', 'verificadores', {'search': query});

      // Obtener todos los documentos de la colección verificadores
      final querySnapshot = await _firestore
          .collection('verificadores')
          .get();

      print('📊 [FIREBASE] Documentos encontrados en colección verificadores: ${querySnapshot.docs.length}');

      final verificadores = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            final nombre = data['nombre'] as String? ?? '';
            final email = data['email'] as String? ?? '';
            final activo = data['activo'] as bool? ?? true;

            print('  📄 Doc: ${doc.id} -> Nombre: $nombre, Email: $email, Activo: $activo');

            return {
              'nombre': nombre,
              'email': email,
              'activo': activo.toString(),
            };
          })
          .where((verificador) =>
            verificador['nombre']!.isNotEmpty &&
            (verificador['nombre']!.toUpperCase().contains(query.toUpperCase()) ||
             verificador['email']!.toUpperCase().contains(query.toUpperCase()))
          )
          .map((verificador) => {
            'nombre': verificador['nombre']!,
            'email': verificador['email']!,
          })
          .toList();

      // Ordenar por nombre
      verificadores.sort((a, b) => a['nombre']!.compareTo(b['nombre']!));

      print('✅ [FIREBASE] Verificadores filtrados para "$query": ${verificadores.length}');
      for (var verificador in verificadores.take(5)) {
        print('  ✓ ${verificador['nombre']}: ${verificador['email']}');
      }

      Logger.info('Verificadores encontrados para búsqueda incremental: ${verificadores.length}');
      return verificadores.take(10).toList(); // Limitar a 10 resultados
    } catch (e, stackTrace) {
      print('❌ [FIREBASE] Error buscando verificadores: $e');
      Logger.error('Error buscando verificadores incremental', e, stackTrace);
      return [];
    }
  }

  /// Buscar VH por placa para el día actual
  Future<VhProgramado?> buscarVhPorPlaca(String placa) async {
    try {
      if (placa.isEmpty) return null;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      Logger.firebaseOperation('QUERY', 'vh_programados', {'placa': placa});

      final querySnapshot = await _firestore
          .collection('vh_programados')
          .where('placa', isEqualTo: placa.toUpperCase())
          .where('fecha', isGreaterThanOrEqualTo: startOfDay)
          .where('fecha', isLessThan: endOfDay)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final vh = VhProgramado.fromMap({...doc.data(), 'id': doc.id});
        Logger.info('VH encontrado para placa $placa: ${vh.vhId}');
        return vh;
      }

      Logger.info('No se encontró VH para placa $placa en la fecha actual');
      return null;
    } catch (e, stackTrace) {
      Logger.error('Error buscando VH por placa', e, stackTrace);
      return null;
    }
  }

  // ========== MÉTODOS PARA SEGUNDO CONTEO ==========

  /// Guardar un segundo conteo
  Future<bool> guardarSegundoConteo(VhSegundoConteo segundoConteo) async {
    try {
      Logger.firebaseOperation('ADD', 'segundo_conteos', segundoConteo.toMap());
      await _firestore.collection('segundo_conteos').add(segundoConteo.toMap());
      Logger.info('Segundo conteo guardado exitosamente para VH: ${segundoConteo.placa}');
      return true;
    } catch (e, stackTrace) {
      Logger.error('Error guardando segundo conteo', e, stackTrace);
      return false;
    }
  }

  /// Verificar si un VH ya fue contado en segundo conteo hoy
  Future<bool> vhYaContadoSegundo(String vhId, String verificadorUid) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('segundo_conteos')
          .where('vh_id', isEqualTo: vhId)
          .where('verificador_uid', isEqualTo: verificadorUid)
          .where('fecha', isGreaterThanOrEqualTo: startOfDay)
          .where('fecha', isLessThan: endOfDay)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      Logger.error('Error verificando segundo conteo de VH', e);
      return false;
    }
  }

  /// Obtener segundos conteos del día actual para un verificador
  Future<List<VhSegundoConteo>> getSegundosConteosHoy(String verificadorUid) async {
    try {
      print('🔍 [FIREBASE] Obteniendo segundos conteos para verificador: $verificadorUid');

      Logger.firebaseOperation('QUERY', 'segundo_conteos', {
        'verificadorUid': verificadorUid,
        'simple_query': true
      });

      // Consulta muy simple sin orderBy para evitar problemas de índice
      final querySnapshot = await _firestore
          .collection('segundo_conteos')
          .where('verificadorUid', isEqualTo: verificadorUid)
          .limit(100) // Limitar a los últimos 100 para rendimiento
          .get();

      print('📊 [FIREBASE] Documentos encontrados en segundo_conteos: ${querySnapshot.docs.length}');

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final segundosConteos = querySnapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              print('📄 [FIREBASE] Procesando documento: ${doc.id}');
              print('  - Placa: ${data['placa']}');
              print('  - Timestamp: ${data['timestamp']}');
              print('  - VerificadorUid: ${data['verificadorUid']}');

              return VhSegundoConteo.fromMap({...data, 'id': doc.id});
            } catch (e) {
              print('❌ [FIREBASE] Error procesando documento ${doc.id}: $e');
              return null;
            }
          })
          .where((conteo) => conteo != null)
          .cast<VhSegundoConteo>()
          .where((conteo) {
            // Filtrar por fecha en el cliente
            final fechaConteo = conteo.fechaConteo;
            final isToday = fechaConteo.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
                           fechaConteo.isBefore(endOfDay);
            print('  - ${conteo.placa}: ${isToday ? "HOY" : "OTRO DÍA"} ($fechaConteo)');
            return isToday;
          })
          .toList();

      print('✅ [FIREBASE] Segundos conteos de hoy filtrados: ${segundosConteos.length}');
      for (var conteo in segundosConteos) {
        print('  ✓ ${conteo.placa} - ${conteo.tieneNovedad ? "con novedad" : "sin novedad"}');
      }

      Logger.info('Segundos conteos de hoy para verificador $verificadorUid: ${segundosConteos.length}');
      return segundosConteos;
    } catch (e, stackTrace) {
      print('❌ [FIREBASE] Error obteniendo segundos conteos: $e');
      Logger.error('Error obteniendo segundos conteos', e, stackTrace);
      return [];
    }
  }

  /// Obtener estadísticas de segundo conteo
  Future<Map<String, int>> getEstadisticasSegundoConteo(String verificadorUid) async {
    try {
      // Contar segundos conteos de hoy
      final segundosConteosHoy = await getSegundosConteosHoy(verificadorUid);

      // Contar VH con novedades
      int vhConNovedades = 0;
      int totalNovedades = 0;

      for (var conteo in segundosConteosHoy) {
        if (conteo.tieneNovedad) {
          vhConNovedades++;
          totalNovedades += conteo.novedades.length;
        }
      }

      return {
        'segundos_conteos_hoy': segundosConteosHoy.length,
        'vh_con_novedades': vhConNovedades,
        'total_novedades': totalNovedades,
        'vh_sin_novedades': segundosConteosHoy.length - vhConNovedades,
      };
    } catch (e, stackTrace) {
      Logger.error('Error obteniendo estadísticas de segundo conteo', e, stackTrace);
      return {
        'segundos_conteos_hoy': 0,
        'vh_con_diferencias': 0,
        'total_diferencias': 0,
        'vh_sin_diferencias': 0,
      };
    }
  }

  /// Obtener reporte de novedades de segundo conteo
  Future<List<Map<String, dynamic>>> getReporteNovedadesSegundoConteo(String verificadorUid) async {
    try {
      final segundosConteos = await getSegundosConteosHoy(verificadorUid);
      final List<Map<String, dynamic>> novedades = [];

      for (var conteo in segundosConteos) {
        if (conteo.tieneNovedad) {
          for (var novedad in conteo.novedades) {
            novedades.add({
              'placa': conteo.placa,
              'tipo': novedad.tipo,
              'dt': novedad.dt,
              'sku': novedad.sku,
              'descripcion': novedad.descripcion,
              'alistado': novedad.alistado,
              'fisico': novedad.fisico,
              'diferencia': novedad.diferencia,
              'verificado': novedad.verificado,
              'armador': novedad.armador,
              'fecha': conteo.fechaConteo,
              'verificador': conteo.verificadorNombre,
            });
          }
        }
      }

      return novedades;
    } catch (e, stackTrace) {
      Logger.error('Error obteniendo reporte de novedades', e, stackTrace);
      return [];
    }
  }
}