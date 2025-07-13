import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/vh_model.dart';
import '../utils/logger.dart';
import '../utils/error_handler.dart';
import '../exceptions/app_exceptions.dart';

/// Repositorio para manejar todas las operaciones relacionadas con conteos
class ConteoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtener VH programados para una fecha específica
  Future<List<VhProgramado>> getVhProgramados({DateTime? fecha}) async {
    try {
      final targetDate = fecha ?? DateTime.now();
      final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      Logger.firebaseOperation('QUERY', 'vh_programados', {
        'fecha_range': 'specific_day',
        'date': targetDate.toIso8601String()
      });
      
      final querySnapshot = await _firestore
          .collection('vh_programados')
          .where('fecha', isGreaterThanOrEqualTo: startOfDay)
          .where('fecha', isLessThan: endOfDay)
          .get();
      
      final vhProgramados = querySnapshot.docs
          .map((doc) => VhProgramado.fromMap(doc.data()))
          .toList();
      
      Logger.info('VH programados obtenidos: ${vhProgramados.length} para fecha: ${targetDate.toIso8601String()}');
      return vhProgramados;
    } catch (e, stackTrace) {
      Logger.error('Error obteniendo VH programados', e, stackTrace);
      throw ErrorHandler.handleGenericError(e, stackTrace);
    }
  }

  /// Buscar VH por placa para la fecha actual
  Future<VhProgramado?> getVhPorPlaca(String placa) async {
    try {
      if (placa.trim().isEmpty) {
        throw ValidationException.required('placa');
      }

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      Logger.firebaseOperation('QUERY', 'vh_programados', {
        'placa': placa,
        'fecha_range': 'today'
      });
      
      final querySnapshot = await _firestore
          .collection('vh_programados')
          .where('placa', isEqualTo: placa.trim().toUpperCase())
          .where('fecha', isGreaterThanOrEqualTo: startOfDay)
          .where('fecha', isLessThan: endOfDay)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        Logger.info('VH no encontrado para placa: $placa');
        return null;
      }
      
      final vh = VhProgramado.fromMap(querySnapshot.docs.first.data());
      Logger.info('VH encontrado: ${vh.vhId} para placa: $placa');
      return vh;
    } catch (e, stackTrace) {
      Logger.error('Error buscando VH por placa', e, stackTrace);
      throw ErrorHandler.handleGenericError(e, stackTrace);
    }
  }

  /// Verificar si un VH ya fue contado por un verificador
  Future<bool> vhYaContado(String vhId, String verificadorUid) async {
    try {
      if (vhId.trim().isEmpty || verificadorUid.trim().isEmpty) {
        throw ValidationException.required('vhId o verificadorUid');
      }

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      Logger.firebaseOperation('QUERY', 'conteos', {
        'vh_id': vhId,
        'verificador_uid': verificadorUid,
        'fecha_range': 'today'
      });
      
      final querySnapshot = await _firestore
          .collection('conteos')
          .where('vh_id', isEqualTo: vhId)
          .where('verificador_uid', isEqualTo: verificadorUid)
          .where('fecha', isGreaterThanOrEqualTo: startOfDay)
          .where('fecha', isLessThan: endOfDay)
          .limit(1)
          .get();
      
      final yaContado = querySnapshot.docs.isNotEmpty;
      Logger.info('VH $vhId ${yaContado ? 'ya fue contado' : 'no ha sido contado'} por verificador $verificadorUid');
      return yaContado;
    } catch (e, stackTrace) {
      Logger.error('Error verificando si VH ya fue contado', e, stackTrace);
      throw ErrorHandler.handleGenericError(e, stackTrace);
    }
  }

  /// Guardar un nuevo conteo
  Future<String> guardarConteo(ConteoVh conteo) async {
    try {
      // Validaciones
      if (conteo.vhId.trim().isEmpty) {
        throw ValidationException.required('VH ID');
      }
      if (conteo.verificadorUid.trim().isEmpty) {
        throw ValidationException.required('Verificador UID');
      }
      if (conteo.placa.trim().isEmpty) {
        throw ValidationException.required('Placa');
      }

      // Verificar que el VH no haya sido contado ya
      final yaContado = await vhYaContado(conteo.vhId, conteo.verificadorUid);
      if (yaContado) {
        throw BusinessException.vhAlreadyCounted();
      }

      Logger.firebaseOperation('ADD', 'conteos', conteo.toMap());
      
      final docRef = await _firestore.collection('conteos').add(conteo.toMap());
      
      Logger.info('Conteo guardado exitosamente: ${docRef.id} para VH: ${conteo.vhId}');
      return docRef.id;
    } catch (e, stackTrace) {
      Logger.error('Error guardando conteo', e, stackTrace);
      throw ErrorHandler.handleGenericError(e, stackTrace);
    }
  }

  /// Obtener conteos de un verificador para una fecha específica
  Future<List<ConteoVh>> getConteosPorVerificador(String verificadorUid, {DateTime? fecha}) async {
    try {
      if (verificadorUid.trim().isEmpty) {
        throw ValidationException.required('verificadorUid');
      }

      final targetDate = fecha ?? DateTime.now();
      final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      Logger.firebaseOperation('QUERY', 'conteos', {
        'verificador_uid': verificadorUid,
        'fecha_range': 'specific_day',
        'date': targetDate.toIso8601String()
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
      
      Logger.info('Conteos obtenidos: ${conteos.length} para verificador: $verificadorUid');
      return conteos;
    } catch (e, stackTrace) {
      Logger.error('Error obteniendo conteos por verificador', e, stackTrace);
      throw ErrorHandler.handleGenericError(e, stackTrace);
    }
  }

  /// Obtener estadísticas de un verificador
  Future<Map<String, int>> getEstadisticasVerificador(String verificadorUid) async {
    try {
      if (verificadorUid.trim().isEmpty) {
        throw ValidationException.required('verificadorUid');
      }

      final now = DateTime.now();
      
      // Conteos de hoy
      final conteosHoy = await getConteosPorVerificador(verificadorUid);
      
      // VH programados para hoy
      final vhProgramadosHoy = await getVhProgramados();
      
      // Errores del mes (conteos con novedades)
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
      
      final estadisticas = {
        'vhContadosHoy': conteosHoy.length,
        'vhProgramadosHoy': vhProgramadosHoy.length,
        'erroresDelMes': erroresSnapshot.docs.length,
      };
      
      Logger.info('Estadísticas calculadas para verificador $verificadorUid: $estadisticas');
      return estadisticas;
    } catch (e, stackTrace) {
      Logger.error('Error obteniendo estadísticas del verificador', e, stackTrace);
      throw ErrorHandler.handleGenericError(e, stackTrace);
    }
  }
}
