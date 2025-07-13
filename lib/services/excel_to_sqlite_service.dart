import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import '../core/services/logger_service.dart';

class ExcelToFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Importar todos los datos del Excel a Firebase
  static Future<bool> importExcelToFirebase() async {
    try {
      print('🔄 Iniciando importación de Excel a Firebase...');

      // Leer el archivo Excel
      final ByteData data = await rootBundle.load('assets/data/DBReCountPro.xlsx');
      final List<int> bytes = data.buffer.asUint8List();
      final Excel excel = Excel.decodeBytes(bytes);

      print('📊 Archivo Excel cargado, hojas encontradas: ${excel.tables.keys.toList()}');

      // Importar cada hoja según su tipo
      for (String sheetName in excel.tables.keys) {
        await _importSheet(excel, sheetName);
      }

      print('✅ Importación de Excel a Firebase completada exitosamente');
      return true;

    } catch (e) {
      print('❌ Error importando Excel a Firebase: $e');
      return false;
    }
  }

  /// Importar una hoja específica
  static Future<void> _importSheet(Excel excel, String sheetName) async {
    try {
      print('📋 Importando hoja: $sheetName');

      final Sheet? sheet = excel.tables[sheetName];
      if (sheet == null || sheet.rows.isEmpty) {
        print('⚠️ Hoja $sheetName está vacía o no existe');
        return;
      }

      // Obtener headers (primera fila)
      final List<String> headers = [];
      final firstRow = sheet.rows.first;

      for (var cell in firstRow) {
        final headerValue = cell?.value?.toString().trim() ?? '';
        if (headerValue.isNotEmpty) {
          headers.add(headerValue.toLowerCase().replaceAll(' ', '_'));
        }
      }

      if (headers.isEmpty) {
        print('⚠️ No se encontraron headers en la hoja $sheetName');
        return;
      }

      print('📝 Headers encontrados en $sheetName: $headers');

      // Crear nombre de colección basado en el nombre de la hoja
      final String collectionName = _getCollectionName(sheetName);

      // Importar datos a Firebase
      await _importToFirebaseCollection(sheet, headers, collectionName, sheetName);

    } catch (e) {
      print('❌ Error importando hoja $sheetName: $e');
    }
  }

  /// Obtener nombre de colección Firebase basado en el nombre de la hoja
  static String _getCollectionName(String sheetName) {
    final String normalized = sheetName.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');

    // Mapear nombres específicos si es necesario
    switch (normalized) {
      case 'usuarios':
        return 'verificadores';
      case 'vehiculos':
        return 'flota';
      case 'vh':
      case 'programados':
        return 'vh_programados';
      case 'productos':
      case 'inventario':
        return 'skus';
      case 'config':
        return 'configuracion';
      default:
        return normalized;
    }
  }

  /// Importar datos a una colección de Firebase
  static Future<void> _importToFirebaseCollection(
    Sheet sheet,
    List<String> headers,
    String collectionName,
    String originalSheetName
  ) async {
    try {
      print('📤 Importando a colección Firebase: $collectionName');

      final CollectionReference collection = _firestore.collection(collectionName);
      int imported = 0;

      // Usar batch para operaciones más eficientes
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final Map<String, dynamic> data = _extractRowData(row, headers);

        if (data.isEmpty) continue;

        // Agregar metadatos
        data['_metadata'] = {
          'source_sheet': originalSheetName,
          'imported_at': FieldValue.serverTimestamp(),
          'import_version': '1.0',
        };

        // Agregar timestamps
        data['created_at'] = FieldValue.serverTimestamp();
        data['updated_at'] = FieldValue.serverTimestamp();

        // Crear documento con ID automático
        DocumentReference docRef = collection.doc();
        batch.set(docRef, data);

        batchCount++;
        imported++;

        // Firestore tiene límite de 500 operaciones por batch
        if (batchCount >= 500) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
          print('📦 Batch de 500 documentos enviado a $collectionName');
        }
      }

      // Enviar el último batch si tiene documentos
      if (batchCount > 0) {
        await batch.commit();
        print('📦 Último batch de $batchCount documentos enviado a $collectionName');
      }

      print('✅ Colección $collectionName: $imported documentos importados');

    } catch (e) {
      print('❌ Error importando a colección $collectionName: $e');
    }
  }



  /// Extraer datos de una fila
  static Map<String, dynamic> _extractRowData(List<Data?> row, List<String> headers) {
    final Map<String, dynamic> data = {};
    
    for (int j = 0; j < headers.length && j < row.length; j++) {
      final cellValue = row[j]?.value;
      if (cellValue != null && cellValue.toString().trim().isNotEmpty) {
        data[headers[j]] = cellValue.toString().trim();
      }
    }
    
    return data;
  }

  /// Obtener estadísticas de importación desde Firebase
  static Future<Map<String, dynamic>> getImportStats() async {
    try {
      final Map<String, int> collectionCounts = {};

      // Lista de colecciones esperadas
      final List<String> collections = [
        'verificadores',
        'flota',
        'vh_programados',
        'skus',
        'configuracion',
        'auxiliares',
        'conteos',
        'segundo_conteos',
      ];

      int totalRecords = 0;

      for (String collection in collections) {
        try {
          final QuerySnapshot snapshot = await _firestore.collection(collection).get();
          final count = snapshot.docs.length;
          collectionCounts[collection] = count;
          totalRecords += count;
        } catch (e) {
          collectionCounts[collection] = 0;
        }
      }

      return {
        'total_records': totalRecords,
        'collection_counts': collectionCounts,
        'import_date': DateTime.now().toIso8601String(),
        'source': 'firebase',
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas de importación: $e');
      return {
        'total_records': 0,
        'collection_counts': <String, int>{},
        'import_date': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }
}
