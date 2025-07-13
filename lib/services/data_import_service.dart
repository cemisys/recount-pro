import 'package:cloud_firestore/cloud_firestore.dart';

class DataImportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> importInitialData() async {
    try {
      print('🚀 Iniciando importación de datos iniciales...');
      
      // Verificar si ya existen datos
      final existingData = await _firestore.collection('sku').limit(1).get();
      if (existingData.docs.isNotEmpty) {
        print('⚠️ Ya existen datos en Firestore');
        return;
      }

      await _importSKUs();
      await _importVerificadores();
      await _importAuxiliares();
      await _importVHProgramados();
      
      print('🎉 Importación completada exitosamente');
    } catch (e) {
      print('❌ Error durante la importación: $e');
      rethrow;
    }
  }

  Future<void> _importSKUs() async {
    try {
      final batch = _firestore.batch();
      
      // Datos de ejemplo de SKUs
      final skus = [
        {
          'sku': 'SKU001',
          'descripcion': 'Producto de ejemplo 1',
          'unidad': 'UND',
          'categoria': 'Categoria A'
        },
        {
          'sku': 'SKU002',
          'descripcion': 'Producto de ejemplo 2',
          'unidad': 'KG',
          'categoria': 'Categoria B'
        },
        {
          'sku': 'SKU003',
          'descripcion': 'Producto de ejemplo 3',
          'unidad': 'LT',
          'categoria': 'Categoria A'
        },
        {
          'sku': 'SKU004',
          'descripcion': 'Producto de ejemplo 4',
          'unidad': 'UND',
          'categoria': 'Categoria C'
        },
        {
          'sku': 'SKU005',
          'descripcion': 'Producto de ejemplo 5',
          'unidad': 'MT',
          'categoria': 'Categoria B'
        },
      ];

      for (final sku in skus) {
        final docRef = _firestore.collection('sku').doc(sku['sku'] as String);
        batch.set(docRef, sku);
      }

      await batch.commit();
      print('✅ SKUs importados: ${skus.length}');
    } catch (e) {
      print('❌ Error importando SKUs: $e');
    }
  }

  Future<void> _importVerificadores() async {
    try {
      final batch = _firestore.batch();
      
      // Datos de ejemplo de verificadores
      final verificadores = [
        {
          'uid': 'verificador1',
          'nombre': 'Juan Pérez',
          'correo': 'juan.perez@3m.com',
          'rol': 'verificador',
          'fecha_creacion': DateTime.now(),
        },
        {
          'uid': 'verificador2',
          'nombre': 'María García',
          'correo': 'maria.garcia@3m.com',
          'rol': 'supervisor',
          'fecha_creacion': DateTime.now(),
        },
        {
          'uid': 'verificador3',
          'nombre': 'Carlos López',
          'correo': 'carlos.lopez@3m.com',
          'rol': 'verificador',
          'fecha_creacion': DateTime.now(),
        },
      ];

      for (final verificador in verificadores) {
        final docRef = _firestore.collection('verificadores').doc(verificador['uid'] as String);
        batch.set(docRef, verificador);
      }

      await batch.commit();
      print('✅ Verificadores importados: ${verificadores.length}');
    } catch (e) {
      print('❌ Error importando verificadores: $e');
    }
  }

  Future<void> _importAuxiliares() async {
    try {
      final batch = _firestore.batch();
      
      // Datos de ejemplo de auxiliares
      final auxiliares = [
        {
          'cedula': '12345678',
          'nombre': 'Pedro Martínez',
          'cargo': 'Auxiliar de Bodega',
          'correo': 'pedro.martinez@3m.com',
          'telefono': '3001234567',
          'activo': true,
        },
        {
          'cedula': '87654321',
          'nombre': 'Ana Rodríguez',
          'cargo': 'Auxiliar de Inventario',
          'correo': 'ana.rodriguez@3m.com',
          'telefono': '3007654321',
          'activo': true,
        },
        {
          'cedula': '11223344',
          'nombre': 'Luis Hernández',
          'cargo': 'Auxiliar de Carga',
          'correo': 'luis.hernandez@3m.com',
          'telefono': '3001122334',
          'activo': true,
        },
      ];

      for (final auxiliar in auxiliares) {
        final docRef = _firestore.collection('auxiliares').doc(auxiliar['cedula'] as String);
        batch.set(docRef, auxiliar);
      }

      await batch.commit();
      print('✅ Auxiliares importados: ${auxiliares.length}');
    } catch (e) {
      print('❌ Error importando auxiliares: $e');
    }
  }

  Future<void> _importVHProgramados() async {
    try {
      final batch = _firestore.batch();
      
      // Datos de ejemplo de VH programados
      final vhProgramados = [
        {
          'vh_id': 'VH001',
          'placa': 'ABC123',
          'fecha': DateTime.now(),
          'productos': [],
        },
        {
          'vh_id': 'VH002',
          'placa': 'DEF456',
          'fecha': DateTime.now().add(const Duration(days: 1)),
          'productos': [],
        },
        {
          'vh_id': 'VH003',
          'placa': 'GHI789',
          'fecha': DateTime.now().add(const Duration(days: 2)),
          'productos': [],
        },
        {
          'vh_id': 'VH004',
          'placa': 'JKL012',
          'fecha': DateTime.now().subtract(const Duration(days: 1)),
          'productos': [],
        },
        {
          'vh_id': 'VH005',
          'placa': 'MNO345',
          'fecha': DateTime.now(),
          'productos': [],
        },
      ];

      for (final vh in vhProgramados) {
        final docRef = _firestore.collection('vh_programados').doc();
        batch.set(docRef, vh);
      }

      await batch.commit();
      print('✅ VH programados importados: ${vhProgramados.length}');
    } catch (e) {
      print('❌ Error importando VH programados: $e');
    }
  }

  Future<void> createSampleInventory() async {
    try {
      final batch = _firestore.batch();
      
      // Crear inventario de ejemplo
      final inventario = [
        {
          'sku': 'SKU001',
          'stock': 100,
          'ubicacion': 'A1-B2',
          'fecha_actualizacion': DateTime.now(),
        },
        {
          'sku': 'SKU002',
          'stock': 250,
          'ubicacion': 'A2-B1',
          'fecha_actualizacion': DateTime.now(),
        },
        {
          'sku': 'SKU003',
          'stock': 75,
          'ubicacion': 'B1-C3',
          'fecha_actualizacion': DateTime.now(),
        },
        {
          'sku': 'SKU004',
          'stock': 180,
          'ubicacion': 'C2-D1',
          'fecha_actualizacion': DateTime.now(),
        },
        {
          'sku': 'SKU005',
          'stock': 320,
          'ubicacion': 'D3-E2',
          'fecha_actualizacion': DateTime.now(),
        },
      ];

      for (final item in inventario) {
        final docRef = _firestore.collection('inventario').doc(item['sku'] as String);
        batch.set(docRef, item);
      }

      await batch.commit();
      print('✅ Inventario de ejemplo creado: ${inventario.length} items');
    } catch (e) {
      print('❌ Error creando inventario: $e');
    }
  }
}