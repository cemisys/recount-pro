import 'dart:io';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sku_model.dart';
import '../models/vh_model.dart';
import '../models/user_model.dart';

class DataImportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Importa datos desde el archivo DBReCountPro.xlsx
  /// El archivo debe estar en la carpeta assets o ser seleccionado por el usuario
  Future<bool> importarDatosDesdeExcel(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('Archivo no encontrado: $filePath');
        return false;
      }

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // Importar cada hoja del Excel
      await _importarSKUs(excel);
      await _importarFlota(excel);
      await _importarAuxiliares(excel);
      await _importarVerificadores(excel);
      await _importarInventario(excel);

      print('Importación completada exitosamente');
      return true;
    } catch (e) {
      print('Error durante la importación: $e');
      return false;
    }
  }

  /// Importa SKUs desde la hoja "SKU"
  Future<void> _importarSKUs(Excel excel) async {
    try {
      final sheet = excel.tables['SKU'];
      if (sheet == null) {
        print('Hoja SKU no encontrada');
        return;
      }

      final batch = _firestore.batch();
      int count = 0;

      // Saltar la primera fila (headers)
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        if (row.length >= 4) {
          final sku = row[0]?.value?.toString() ?? '';
          final descripcion = row[1]?.value?.toString() ?? '';
          final unidad = row[2]?.value?.toString() ?? '';
          final categoria = row[3]?.value?.toString() ?? '';

          if (sku.isNotEmpty) {
            final skuModel = SkuModel(
              sku: sku,
              descripcion: descripcion,
              unidad: unidad,
              categoria: categoria,
            );

            final docRef = _firestore.collection('sku').doc(sku);
            batch.set(docRef, skuModel.toMap());
            count++;

            // Commit en lotes de 500
            if (count % 500 == 0) {
              await batch.commit();
            }
          }
        }
      }

      if (count % 500 != 0) {
        await batch.commit();
      }

      print('SKUs importados: $count');
    } catch (e) {
      print('Error importando SKUs: $e');
    }
  }

  /// Importa la flota desde la hoja "Flota"
  Future<void> _importarFlota(Excel excel) async {
    try {
      final sheet = excel.tables['Flota'];
      if (sheet == null) {
        print('Hoja Flota no encontrada');
        return;
      }

      final batch = _firestore.batch();
      int count = 0;

      // Saltar la primera fila (headers)
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        if (row.length >= 3) {
          final vhId = row[0]?.value?.toString() ?? '';
          final placa = row[1]?.value?.toString() ?? '';
          final fechaStr = row[2]?.value?.toString() ?? '';

          if (vhId.isNotEmpty && placa.isNotEmpty) {
            // Parsear fecha (asumiendo formato dd/MM/yyyy)
            DateTime fecha = DateTime.now();
            try {
              final parts = fechaStr.split('/');
              if (parts.length == 3) {
                fecha = DateTime(
                  int.parse(parts[2]),
                  int.parse(parts[1]),
                  int.parse(parts[0]),
                );
              }
            } catch (e) {
              print('Error parseando fecha: $fechaStr');
            }

            final vhProgramado = VhProgramado(
              vhId: vhId,
              placa: placa,
              fecha: fecha,
              productos: const [], // Los productos se pueden agregar después
            );

            final docRef = _firestore.collection('vh_programados').doc();
            batch.set(docRef, vhProgramado.toMap());
            count++;

            // Commit en lotes de 500
            if (count % 500 == 0) {
              await batch.commit();
            }
          }
        }
      }

      if (count % 500 != 0) {
        await batch.commit();
      }

      print('VH programados importados: $count');
    } catch (e) {
      print('Error importando flota: $e');
    }
  }

  /// Importa auxiliares desde la hoja "Auxiliares"
  Future<void> _importarAuxiliares(Excel excel) async {
    try {
      final sheet = excel.tables['Auxiliares'];
      if (sheet == null) {
        print('Hoja Auxiliares no encontrada');
        return;
      }

      final batch = _firestore.batch();
      int count = 0;

      // Saltar la primera fila (headers)
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        if (row.length >= 5) {
          final nombre = row[0]?.value?.toString() ?? '';
          final cedula = row[1]?.value?.toString() ?? '';
          final cargo = row[2]?.value?.toString() ?? '';
          final correo = row[3]?.value?.toString() ?? '';
          final telefono = row[4]?.value?.toString() ?? '';

          if (nombre.isNotEmpty && cedula.isNotEmpty) {
            final auxiliar = AuxiliarModel(
              nombre: nombre,
              cedula: cedula,
              cargo: cargo,
              correo: correo,
              telefono: telefono,
              activo: true,
            );

            final docRef = _firestore.collection('auxiliares').doc(cedula);
            batch.set(docRef, auxiliar.toMap());
            count++;

            // Commit en lotes de 500
            if (count % 500 == 0) {
              await batch.commit();
            }
          }
        }
      }

      if (count % 500 != 0) {
        await batch.commit();
      }

      print('Auxiliares importados: $count');
    } catch (e) {
      print('Error importando auxiliares: $e');
    }
  }

  /// Importa verificadores desde la hoja "Verificadores"
  Future<void> _importarVerificadores(Excel excel) async {
    try {
      final sheet = excel.tables['Verificadores'];
      if (sheet == null) {
        print('Hoja Verificadores no encontrada');
        return;
      }

      final batch = _firestore.batch();
      int count = 0;

      // Saltar la primera fila (headers)
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        if (row.length >= 4) {
          final uid = row[0]?.value?.toString() ?? '';
          final nombre = row[1]?.value?.toString() ?? '';
          final correo = row[2]?.value?.toString() ?? '';
          final rol = row[3]?.value?.toString() ?? 'verificador';

          if (uid.isNotEmpty && nombre.isNotEmpty && correo.isNotEmpty) {
            final verificador = UserModel(
              uid: uid,
              nombre: nombre,
              correo: correo,
              rol: rol,
              fechaCreacion: DateTime.now(),
            );

            final docRef = _firestore.collection('verificadores').doc(uid);
            batch.set(docRef, verificador.toMap());
            count++;

            // Commit en lotes de 500
            if (count % 500 == 0) {
              await batch.commit();
            }
          }
        }
      }

      if (count % 500 != 0) {
        await batch.commit();
      }

      print('Verificadores importados: $count');
    } catch (e) {
      print('Error importando verificadores: $e');
    }
  }

  /// Importa inventario desde la hoja "Inventario"
  Future<void> _importarInventario(Excel excel) async {
    try {
      final sheet = excel.tables['Inventario'];
      if (sheet == null) {
        print('Hoja Inventario no encontrada');
        return;
      }

      final batch = _firestore.batch();
      int count = 0;

      // Saltar la primera fila (headers)
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.rows[i];
        if (row.length >= 4) {
          final sku = row[0]?.value?.toString() ?? '';
          final stockStr = row[1]?.value?.toString() ?? '0';
          final ubicacion = row[2]?.value?.toString() ?? '';
          final fechaStr = row[3]?.value?.toString() ?? '';

          if (sku.isNotEmpty) {
            int stock = 0;
            try {
              stock = int.parse(stockStr);
            } catch (e) {
              print('Error parseando stock: $stockStr');
            }

            // Parsear fecha
            DateTime fechaActualizacion = DateTime.now();
            try {
              final parts = fechaStr.split('/');
              if (parts.length == 3) {
                fechaActualizacion = DateTime(
                  int.parse(parts[2]),
                  int.parse(parts[1]),
                  int.parse(parts[0]),
                );
              }
            } catch (e) {
              print('Error parseando fecha: $fechaStr');
            }

            final inventario = InventarioModel(
              sku: sku,
              stock: stock,
              ubicacion: ubicacion,
              fechaActualizacion: fechaActualizacion,
            );

            final docRef = _firestore.collection('inventario').doc(sku);
            batch.set(docRef, inventario.toMap());
            count++;

            // Commit en lotes de 500
            if (count % 500 == 0) {
              await batch.commit();
            }
          }
        }
      }

      if (count % 500 != 0) {
        await batch.commit();
      }

      print('Inventario importado: $count');
    } catch (e) {
      print('Error importando inventario: $e');
    }
  }

  /// Verifica si las colecciones ya tienen datos
  Future<bool> datosYaImportados() async {
    try {
      final skuSnapshot = await _firestore.collection('sku').limit(1).get();
      return skuSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error verificando datos: $e');
      return false;
    }
  }

  /// Limpia todas las colecciones (usar con precaución)
  Future<void> limpiarDatos() async {
    try {
      final collections = ['sku', 'vh_programados', 'auxiliares', 'verificadores', 'inventario'];
      
      for (final collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        final batch = _firestore.batch();
        
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        print('Colección $collection limpiada');
      }
    } catch (e) {
      print('Error limpiando datos: $e');
    }
  }
}