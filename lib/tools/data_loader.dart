import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataLoader {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Carga todos los datos del archivo Excel a Firebase
  static Future<void> loadAllData() async {
    try {
      print('Iniciando carga de datos desde Excel...');

      // Leer el archivo Excel
      final ByteData data = await rootBundle.load('assets/data/DBReCountPro.xlsx');
      final List<int> bytes = data.buffer.asUint8List();
      final Excel excel = Excel.decodeBytes(bytes);

      print('Archivo Excel cargado exitosamente');
      print('Hojas disponibles: ${excel.tables.keys.toList()}');

      // Cargar cada hoja del Excel
      for (String tableName in excel.tables.keys) {
        await _loadTableData(excel, tableName);
      }

      print('Carga de datos completada exitosamente');

    } catch (e, stackTrace) {
      print('Error cargando datos desde Excel: $e');
      print('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Carga los datos de una hoja específica
  static Future<void> _loadTableData(Excel excel, String tableName) async {
    try {
      print('Procesando hoja: $tableName');

      final Sheet? sheet = excel.tables[tableName];
      if (sheet == null) {
        print('Hoja $tableName no encontrada');
        return;
      }

      // Obtener los headers (primera fila)
      final List<String> headers = [];
      final firstRow = sheet.rows.first;
      for (var cell in firstRow) {
        headers.add(cell?.value?.toString() ?? '');
      }

      print('Headers encontrados en $tableName: $headers');

      // Procesar cada fila de datos (saltando la primera que son headers)
      final List<Map<String, dynamic>> documents = [];

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final Map<String, dynamic> document = {};

        for (int j = 0; j < headers.length && j < row.length; j++) {
          final header = headers[j];
          final cellValue = row[j]?.value;

          if (header.isNotEmpty && cellValue != null) {
            document[header] = _convertCellValue(cellValue);
          }
        }

        if (document.isNotEmpty) {
          documents.add(document);
        }
      }

      print('Documentos a cargar en $tableName: ${documents.length}');

      // Cargar documentos a Firebase
      await _uploadToFirestore(tableName, documents);

    } catch (e) {
      print('Error procesando hoja $tableName: $e');
    }
  }

  /// Convierte el valor de la celda al tipo apropiado
  static dynamic _convertCellValue(dynamic cellValue) {
    if (cellValue == null) return null;
    
    // Si es un número
    if (cellValue is num) {
      return cellValue;
    }
    
    // Si es texto
    String stringValue = cellValue.toString().trim();
    
    // Intentar convertir a número si es posible
    if (RegExp(r'^\d+$').hasMatch(stringValue)) {
      return int.tryParse(stringValue) ?? stringValue;
    }
    
    if (RegExp(r'^\d+\.\d+$').hasMatch(stringValue)) {
      return double.tryParse(stringValue) ?? stringValue;
    }
    
    // Convertir valores booleanos
    if (stringValue.toLowerCase() == 'true' || stringValue.toLowerCase() == 'verdadero') {
      return true;
    }
    if (stringValue.toLowerCase() == 'false' || stringValue.toLowerCase() == 'falso') {
      return false;
    }
    
    // Retornar como string
    return stringValue;
  }

  /// Sube los documentos a Firestore conservando nombres originales
  static Future<void> _uploadToFirestore(String originalSheetName, List<Map<String, dynamic>> documents) async {
    try {
      // Usar el nombre original de la hoja como nombre de colección
      // Convertir a minúsculas y reemplazar espacios con guiones bajos
      String collectionName = originalSheetName
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll('-', '_')
          .replaceAll('(', '')
          .replaceAll(')', '');

      print('Subiendo ${documents.length} documentos a colección: $collectionName (hoja original: $originalSheetName)');

      final CollectionReference collection = _firestore.collection(collectionName);

      // Usar batch para operaciones más eficientes
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (var document in documents) {
        // Agregar metadatos de origen
        document['_metadata'] = {
          'source_sheet': originalSheetName,
          'imported_at': FieldValue.serverTimestamp(),
          'import_version': '1.0',
        };

        // Agregar timestamp de creación
        document['created_at'] = FieldValue.serverTimestamp();
        document['updated_at'] = FieldValue.serverTimestamp();

        // Crear documento con ID automático
        DocumentReference docRef = collection.doc();
        batch.set(docRef, document);

        batchCount++;

        // Firestore tiene límite de 500 operaciones por batch
        if (batchCount >= 500) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
          print('Batch de 500 documentos enviado a $collectionName');
        }
      }

      // Enviar el último batch si tiene documentos
      if (batchCount > 0) {
        await batch.commit();
        print('Último batch de $batchCount documentos enviado a $collectionName');
      }

      print('Colección $collectionName cargada exitosamente: ${documents.length} documentos');

    } catch (e) {
      print('Error subiendo datos a Firestore para $originalSheetName: $e');
      rethrow;
    }
  }

  /// Limpia una colección específica (usar con cuidado)
  static Future<void> clearCollection(String collectionName) async {
    try {
      print('Limpiando colección: $collectionName');

      final QuerySnapshot snapshot = await _firestore.collection(collectionName).get();

      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
        batchCount++;

        if (batchCount >= 500) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      print('Colección $collectionName limpiada: ${snapshot.docs.length} documentos eliminados');

    } catch (e) {
      print('Error limpiando colección $collectionName: $e');
      rethrow;
    }
  }

  /// Verifica el estado de las colecciones
  static Future<Map<String, int>> getCollectionsStatus() async {
    try {
      final Map<String, int> status = {};

      // Lista de colecciones esperadas (incluye las del Excel y las nuevas)
      final List<String> expectedCollections = [
        // Colecciones originales
        'verificadores',
        'conteos',
        'vh_programados',
        'skus',
        'auxiliares',
        'configuracion',

        // Nuevas colecciones
        'segundo_conteos',
        'flota',

        // Posibles nombres del Excel (convertidos)
        'dbrecountpro',
        'vh',
        'productos',
        'inventario',
        'usuarios',
        'clientes',
        'proveedores',

        // Nombres comunes en español
        'vehiculos',
        'conductores',
        'rutas',
        'almacenes',
        'bodegas',
      ];

      print('🔍 Verificando ${expectedCollections.length} colecciones posibles...');

      for (String collectionName in expectedCollections) {
        try {
          final int count = await _getCollectionCount(collectionName);
          if (count > 0) {
            status[collectionName] = count;
            print('✅ $collectionName: $count documentos');
          }
        } catch (e) {
          // Colección no existe o error de acceso, ignorar
        }
      }

      print('📊 Total de colecciones con datos: ${status.length}');
      return status;

    } catch (e) {
      print('❌ Error obteniendo estado de colecciones: $e');
      return {};
    }
  }

  /// Obtiene el conteo aproximado de documentos en una colección
  static Future<int> _getCollectionCount(String collectionName) async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection(collectionName).get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Obtiene información detallada de una colección
  static Future<Map<String, dynamic>> getCollectionDetails(String collectionName) async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection(collectionName).limit(5).get();

      if (snapshot.docs.isEmpty) {
        return {
          'count': 0,
          'sample_documents': [],
          'fields': [],
          'has_metadata': false,
        };
      }

      // Obtener muestra de documentos
      final List<Map<String, dynamic>> sampleDocs = [];
      final Set<String> allFields = {};
      bool hasMetadata = false;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        sampleDocs.add({
          'id': doc.id,
          'data': data,
        });

        // Recopilar todos los campos
        allFields.addAll(data.keys);

        // Verificar si tiene metadatos de importación
        if (data.containsKey('_metadata')) {
          hasMetadata = true;
        }
      }

      // Obtener conteo total
      final int totalCount = await _getCollectionCount(collectionName);

      return {
        'count': totalCount,
        'sample_documents': sampleDocs,
        'fields': allFields.toList()..sort(),
        'has_metadata': hasMetadata,
        'collection_name': collectionName,
      };

    } catch (e) {
      print('Error obteniendo detalles de $collectionName: $e');
      return {
        'count': 0,
        'sample_documents': [],
        'fields': [],
        'has_metadata': false,
        'error': e.toString(),
      };
    }
  }
}
