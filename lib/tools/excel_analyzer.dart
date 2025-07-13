import 'package:excel/excel.dart';
import 'package:flutter/services.dart';

class ExcelAnalyzer {
  /// Analiza el archivo Excel y muestra su estructura
  static Future<Map<String, dynamic>> analyzeExcelFile() async {
    try {
      print('🔍 Analizando archivo DBReCountPro.xlsx...');
      
      // Leer el archivo Excel
      final ByteData data = await rootBundle.load('assets/data/DBReCountPro.xlsx');
      final List<int> bytes = data.buffer.asUint8List();
      final Excel excel = Excel.decodeBytes(bytes);
      
      final Map<String, dynamic> analysis = {
        'fileName': 'DBReCountPro.xlsx',
        'totalSheets': excel.tables.length,
        'sheets': <String, Map<String, dynamic>>{},
        'summary': <String, dynamic>{},
      };
      
      print('📋 Archivo cargado exitosamente');
      print('📊 Total de hojas: ${excel.tables.length}');
      print('📝 Hojas encontradas: ${excel.tables.keys.toList()}');
      
      // Analizar cada hoja
      for (String sheetName in excel.tables.keys) {
        final sheetAnalysis = await _analyzeSheet(excel, sheetName);
        analysis['sheets'][sheetName] = sheetAnalysis;
      }
      
      // Crear resumen general
      analysis['summary'] = _createSummary(analysis['sheets']);
      
      return analysis;
      
    } catch (e) {
      print('❌ Error analizando archivo Excel: $e');
      rethrow;
    }
  }

  /// Analiza una hoja específica del Excel
  static Future<Map<String, dynamic>> _analyzeSheet(Excel excel, String sheetName) async {
    try {
      print('\n🔍 Analizando hoja: $sheetName');
      
      final Sheet? sheet = excel.tables[sheetName];
      if (sheet == null) {
        print('⚠️ Hoja $sheetName no encontrada');
        return {
          'name': sheetName,
          'exists': false,
          'error': 'Hoja no encontrada'
        };
      }

      final Map<String, dynamic> sheetInfo = {
        'name': sheetName,
        'exists': true,
        'totalRows': sheet.rows.length,
        'totalColumns': 0,
        'headers': <String>[],
        'dataRows': 0,
        'sampleData': <Map<String, dynamic>>[],
        'columnTypes': <String, String>{},
        'emptyRows': 0,
        'duplicateRows': 0,
      };

      if (sheet.rows.isEmpty) {
        print('⚠️ Hoja $sheetName está vacía');
        return sheetInfo;
      }

      // Obtener headers (primera fila)
      final List<String> headers = [];
      final firstRow = sheet.rows.first;
      
      for (var cell in firstRow) {
        final headerValue = cell?.value?.toString().trim() ?? '';
        headers.add(headerValue);
      }
      
      sheetInfo['headers'] = headers.where((h) => h.isNotEmpty).toList();
      sheetInfo['totalColumns'] = headers.where((h) => h.isNotEmpty).length;
      
      print('📋 Headers encontrados: ${sheetInfo['headers']}');
      print('📊 Columnas: ${sheetInfo['totalColumns']}, Filas totales: ${sheetInfo['totalRows']}');

      // Analizar tipos de datos y obtener muestras
      final List<Map<String, dynamic>> sampleData = [];
      final Map<String, Map<String, int>> columnTypeCount = {};
      int emptyRows = 0;
      final Set<String> uniqueRows = {};
      
      // Inicializar contadores de tipos por columna
      for (String header in sheetInfo['headers']) {
        columnTypeCount[header] = {
          'string': 0,
          'number': 0,
          'boolean': 0,
          'date': 0,
          'empty': 0,
        };
      }

      // Procesar filas de datos (saltando la primera que son headers)
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final Map<String, dynamic> rowData = {};
        bool isEmptyRow = true;
        
        // Crear string único para detectar duplicados
        String rowString = '';
        
        for (int j = 0; j < sheetInfo['headers'].length && j < row.length; j++) {
          final header = sheetInfo['headers'][j];
          final cellValue = row[j]?.value;
          
          if (cellValue != null && cellValue.toString().trim().isNotEmpty) {
            final convertedValue = _convertAndAnalyzeValue(cellValue);
            rowData[header] = convertedValue['value'];
            
            // Contar tipos
            columnTypeCount[header]![convertedValue['type']] = 
                (columnTypeCount[header]![convertedValue['type']] ?? 0) + 1;
            
            isEmptyRow = false;
            rowString += cellValue.toString().trim();
          } else {
            rowData[header] = null;
            columnTypeCount[header]!['empty'] = 
                (columnTypeCount[header]!['empty'] ?? 0) + 1;
          }
        }
        
        if (isEmptyRow) {
          emptyRows++;
        } else {
          // Verificar duplicados
          if (uniqueRows.contains(rowString)) {
            sheetInfo['duplicateRows'] = (sheetInfo['duplicateRows'] as int) + 1;
          } else {
            uniqueRows.add(rowString);
          }
          
          // Agregar a muestra (máximo 5 registros)
          if (sampleData.length < 5) {
            sampleData.add(rowData);
          }
        }
      }
      
      sheetInfo['dataRows'] = sheet.rows.length - 1 - emptyRows;
      sheetInfo['emptyRows'] = emptyRows;
      sheetInfo['sampleData'] = sampleData;
      
      // Determinar tipo predominante por columna
      final Map<String, String> columnTypes = {};
      for (String header in sheetInfo['headers']) {
        final typeCounts = columnTypeCount[header]!;
        String predominantType = 'string';
        int maxCount = 0;
        
        for (String type in typeCounts.keys) {
          if (type != 'empty' && typeCounts[type]! > maxCount) {
            maxCount = typeCounts[type]!;
            predominantType = type;
          }
        }
        columnTypes[header] = predominantType;
      }
      sheetInfo['columnTypes'] = columnTypes;
      
      print('📈 Filas con datos: ${sheetInfo['dataRows']}');
      print('🔢 Tipos de columnas: $columnTypes');
      if (sheetInfo['emptyRows'] > 0) {
        print('⚠️ Filas vacías: ${sheetInfo['emptyRows']}');
      }
      if (sheetInfo['duplicateRows'] > 0) {
        print('⚠️ Filas duplicadas: ${sheetInfo['duplicateRows']}');
      }
      
      return sheetInfo;
      
    } catch (e) {
      print('❌ Error analizando hoja $sheetName: $e');
      return {
        'name': sheetName,
        'exists': false,
        'error': e.toString()
      };
    }
  }

  /// Convierte y analiza el tipo de un valor de celda
  static Map<String, dynamic> _convertAndAnalyzeValue(dynamic cellValue) {
    if (cellValue == null) {
      return {'value': null, 'type': 'empty'};
    }
    
    // Si es un número
    if (cellValue is num) {
      return {'value': cellValue, 'type': 'number'};
    }
    
    String stringValue = cellValue.toString().trim();
    
    // Intentar convertir a número
    if (RegExp(r'^\d+$').hasMatch(stringValue)) {
      return {'value': int.tryParse(stringValue) ?? stringValue, 'type': 'number'};
    }
    
    if (RegExp(r'^\d+\.\d+$').hasMatch(stringValue)) {
      return {'value': double.tryParse(stringValue) ?? stringValue, 'type': 'number'};
    }
    
    // Verificar booleanos
    if (stringValue.toLowerCase() == 'true' || stringValue.toLowerCase() == 'verdadero' ||
        stringValue.toLowerCase() == 'false' || stringValue.toLowerCase() == 'falso' ||
        stringValue == '1' || stringValue == '0') {
      return {'value': stringValue, 'type': 'boolean'};
    }
    
    // Verificar fechas (formato básico)
    if (RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}$').hasMatch(stringValue) ||
        RegExp(r'^\d{4}[/-]\d{1,2}[/-]\d{1,2}$').hasMatch(stringValue)) {
      return {'value': stringValue, 'type': 'date'};
    }
    
    return {'value': stringValue, 'type': 'string'};
  }

  /// Crea un resumen general del análisis
  static Map<String, dynamic> _createSummary(Map<String, dynamic> sheets) {
    int totalDataRows = 0;
    int totalEmptyRows = 0;
    int totalDuplicateRows = 0;
    final List<String> allHeaders = [];
    final Map<String, int> headerFrequency = {};
    
    for (var sheetData in sheets.values) {
      if (sheetData['exists'] == true) {
        totalDataRows += (sheetData['dataRows'] as int? ?? 0);
        totalEmptyRows += (sheetData['emptyRows'] as int? ?? 0);
        totalDuplicateRows += (sheetData['duplicateRows'] as int? ?? 0);
        
        final List<String> headers = List<String>.from(sheetData['headers'] ?? []);
        for (String header in headers) {
          if (!allHeaders.contains(header)) {
            allHeaders.add(header);
          }
          headerFrequency[header] = (headerFrequency[header] ?? 0) + 1;
        }
      }
    }
    
    return {
      'totalDataRows': totalDataRows,
      'totalEmptyRows': totalEmptyRows,
      'totalDuplicateRows': totalDuplicateRows,
      'uniqueHeaders': allHeaders.length,
      'commonHeaders': headerFrequency.entries
          .where((e) => e.value > 1)
          .map((e) => e.key)
          .toList(),
      'headerFrequency': headerFrequency,
    };
  }

  /// Imprime un reporte detallado del análisis
  static void printDetailedReport(Map<String, dynamic> analysis) {
    print('\n${'='*60}');
    print('📊 REPORTE DETALLADO DEL ARCHIVO EXCEL');
    print('='*60);
    
    print('\n📁 Archivo: ${analysis['fileName']}');
    print('📋 Total de hojas: ${analysis['totalSheets']}');
    
    final summary = analysis['summary'];
    print('\n📈 RESUMEN GENERAL:');
    print('   • Total de filas con datos: ${summary['totalDataRows']}');
    print('   • Total de filas vacías: ${summary['totalEmptyRows']}');
    print('   • Total de filas duplicadas: ${summary['totalDuplicateRows']}');
    print('   • Headers únicos: ${summary['uniqueHeaders']}');
    
    print('\n📋 ANÁLISIS POR HOJA:');
    final sheets = analysis['sheets'] as Map<String, dynamic>;
    
    for (var entry in sheets.entries) {
      final sheetName = entry.key;
      final sheetData = entry.value as Map<String, dynamic>;
      
      print('\n  🔸 $sheetName:');
      if (sheetData['exists'] == true) {
        print('     • Filas: ${sheetData['totalRows']} (${sheetData['dataRows']} con datos)');
        print('     • Columnas: ${sheetData['totalColumns']}');
        print('     • Headers: ${sheetData['headers']}');
        
        if (sheetData['sampleData'] != null && (sheetData['sampleData'] as List).isNotEmpty) {
          print('     • Muestra de datos:');
          final sampleData = sheetData['sampleData'] as List<Map<String, dynamic>>;
          for (int i = 0; i < sampleData.length && i < 2; i++) {
            print('       ${i + 1}. ${sampleData[i]}');
          }
        }
      } else {
        print('     ❌ Error: ${sheetData['error']}');
      }
    }
    
    print('\n${'='*60}');
  }
}
