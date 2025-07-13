import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
// import '../core/services/logger_service.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'recount_pro.db';
  static const int _databaseVersion = 1;

  /// Singleton instance
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// Inicializar la base de datos
  static Future<void> initialize() async {
    try {
      // Configurar SQLite para web y desktop
      if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      print('🔄 Inicializando base de datos SQLite...');
      await _initDatabase();
      print('✅ Base de datos SQLite inicializada exitosamente');
    } catch (e) {
      print('❌ Error inicializando base de datos SQLite: $e');
      rethrow;
    }
  }

  /// Obtener la instancia de la base de datos
  static Future<Database> get database async {
    if (_database != null) return _database!;
    await _initDatabase();
    return _database!;
  }

  /// Inicializar la base de datos
  static Future<void> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final dbPath = path.join(databasesPath, _databaseName);

      _database = await openDatabase(
        dbPath,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

      print('📁 Base de datos creada en: $dbPath');
    } catch (e) {
      print('❌ Error creando base de datos: $e');
      rethrow;
    }
  }

  /// Crear las tablas de la base de datos
  static Future<void> _onCreate(Database db, int version) async {
    try {
      print('🔧 Creando tablas de la base de datos...');

      // Tabla de verificadores
      await db.execute('''
        CREATE TABLE verificadores (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uid TEXT UNIQUE NOT NULL,
          nombre TEXT NOT NULL,
          email TEXT NOT NULL,
          activo INTEGER DEFAULT 1,
          fecha_creacion TEXT NOT NULL,
          fecha_actualizacion TEXT NOT NULL
        )
      ''');

      // Tabla de flota
      await db.execute('''
        CREATE TABLE flota (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          flota_id TEXT UNIQUE NOT NULL,
          nombre TEXT NOT NULL,
          tipo TEXT,
          capacidad INTEGER,
          activo INTEGER DEFAULT 1,
          fecha_creacion TEXT NOT NULL,
          fecha_actualizacion TEXT NOT NULL
        )
      ''');

      // Tabla de VH programados
      await db.execute('''
        CREATE TABLE vh_programados (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          vh_id TEXT UNIQUE NOT NULL,
          placa TEXT NOT NULL,
          fecha TEXT NOT NULL,
          estado TEXT,
          conductor TEXT,
          ruta TEXT,
          flota_id TEXT,
          fecha_creacion TEXT NOT NULL,
          fecha_actualizacion TEXT NOT NULL,
          FOREIGN KEY (flota_id) REFERENCES flota (flota_id)
        )
      ''');

      // Tabla de productos VH
      await db.execute('''
        CREATE TABLE productos_vh (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          vh_id TEXT NOT NULL,
          sku TEXT NOT NULL,
          descripcion TEXT NOT NULL,
          cantidad_programada INTEGER NOT NULL,
          unidad TEXT,
          fecha_creacion TEXT NOT NULL,
          FOREIGN KEY (vh_id) REFERENCES vh_programados (vh_id)
        )
      ''');

      // Tabla de SKUs
      await db.execute('''
        CREATE TABLE skus (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sku TEXT UNIQUE NOT NULL,
          descripcion TEXT NOT NULL,
          categoria TEXT,
          unidad TEXT,
          activo INTEGER DEFAULT 1,
          fecha_creacion TEXT NOT NULL,
          fecha_actualizacion TEXT NOT NULL
        )
      ''');

      // Tabla de conteos
      await db.execute('''
        CREATE TABLE conteos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          conteo_id TEXT UNIQUE NOT NULL,
          vh_id TEXT NOT NULL,
          verificador_uid TEXT NOT NULL,
          fecha TEXT NOT NULL,
          tipo_conteo TEXT NOT NULL,
          estado TEXT DEFAULT 'completado',
          observaciones TEXT,
          fecha_creacion TEXT NOT NULL,
          FOREIGN KEY (vh_id) REFERENCES vh_programados (vh_id),
          FOREIGN KEY (verificador_uid) REFERENCES verificadores (uid)
        )
      ''');

      // Tabla de productos conteo
      await db.execute('''
        CREATE TABLE productos_conteo (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          conteo_id TEXT NOT NULL,
          sku TEXT NOT NULL,
          cantidad_programada INTEGER NOT NULL,
          cantidad_contada INTEGER NOT NULL,
          diferencia INTEGER NOT NULL,
          observaciones TEXT,
          fecha_creacion TEXT NOT NULL,
          FOREIGN KEY (conteo_id) REFERENCES conteos (conteo_id),
          FOREIGN KEY (sku) REFERENCES skus (sku)
        )
      ''');

      // Tabla de segundo conteos
      await db.execute('''
        CREATE TABLE segundo_conteos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          segundo_conteo_id TEXT UNIQUE NOT NULL,
          vh_id TEXT NOT NULL,
          verificador_uid TEXT NOT NULL,
          fecha TEXT NOT NULL,
          cantidad_vh_programados INTEGER NOT NULL,
          cantidad_vh_salida INTEGER NOT NULL,
          diferencia_vh INTEGER NOT NULL,
          observaciones TEXT,
          fecha_creacion TEXT NOT NULL,
          FOREIGN KEY (vh_id) REFERENCES vh_programados (vh_id),
          FOREIGN KEY (verificador_uid) REFERENCES verificadores (uid)
        )
      ''');

      // Tabla de productos segundo conteo
      await db.execute('''
        CREATE TABLE productos_segundo_conteo (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          segundo_conteo_id TEXT NOT NULL,
          sku TEXT NOT NULL,
          cantidad_programada INTEGER NOT NULL,
          cantidad_contada INTEGER NOT NULL,
          diferencia INTEGER NOT NULL,
          observaciones TEXT,
          fecha_creacion TEXT NOT NULL,
          FOREIGN KEY (segundo_conteo_id) REFERENCES segundo_conteos (segundo_conteo_id),
          FOREIGN KEY (sku) REFERENCES skus (sku)
        )
      ''');

      // Tabla de configuración
      await db.execute('''
        CREATE TABLE configuracion (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          clave TEXT UNIQUE NOT NULL,
          valor TEXT NOT NULL,
          descripcion TEXT,
          fecha_creacion TEXT NOT NULL,
          fecha_actualizacion TEXT NOT NULL
        )
      ''');

      // Tabla de auxiliares (datos de apoyo)
      await db.execute('''
        CREATE TABLE auxiliares (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tipo TEXT NOT NULL,
          codigo TEXT NOT NULL,
          descripcion TEXT NOT NULL,
          valor TEXT,
          activo INTEGER DEFAULT 1,
          fecha_creacion TEXT NOT NULL,
          fecha_actualizacion TEXT NOT NULL
        )
      ''');

      // Crear índices para mejorar el rendimiento
      await _createIndexes(db);

      print('✅ Tablas creadas exitosamente');
    } catch (e) {
      print('❌ Error creando tablas: $e');
      rethrow;
    }
  }

  /// Crear índices para mejorar el rendimiento
  static Future<void> _createIndexes(Database db) async {
    try {
      print('🔗 Creando índices...');

      // Índices para búsquedas frecuentes
      await db.execute('CREATE INDEX idx_vh_programados_fecha ON vh_programados (fecha)');
      await db.execute('CREATE INDEX idx_vh_programados_placa ON vh_programados (placa)');
      await db.execute('CREATE INDEX idx_conteos_fecha ON conteos (fecha)');
      await db.execute('CREATE INDEX idx_conteos_verificador ON conteos (verificador_uid)');
      await db.execute('CREATE INDEX idx_segundo_conteos_fecha ON segundo_conteos (fecha)');
      await db.execute('CREATE INDEX idx_segundo_conteos_verificador ON segundo_conteos (verificador_uid)');
      await db.execute('CREATE INDEX idx_productos_vh_vh_id ON productos_vh (vh_id)');
      await db.execute('CREATE INDEX idx_productos_conteo_conteo_id ON productos_conteo (conteo_id)');
      await db.execute('CREATE INDEX idx_productos_segundo_conteo_segundo_conteo_id ON productos_segundo_conteo (segundo_conteo_id)');

      print('✅ Índices creados exitosamente');
    } catch (e) {
      print('❌ Error creando índices: $e');
      rethrow;
    }
  }

  /// Actualizar la base de datos
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      print('🔄 Actualizando base de datos de versión $oldVersion a $newVersion');

      // Aquí se pueden agregar migraciones futuras
      if (oldVersion < 2) {
        // Ejemplo de migración para versión 2
        // await db.execute('ALTER TABLE tabla ADD COLUMN nueva_columna TEXT');
      }

      print('✅ Base de datos actualizada exitosamente');
    } catch (e) {
      print('❌ Error actualizando base de datos: $e');
      rethrow;
    }
  }

  /// Cerrar la base de datos
  static Future<void> close() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
        print('🔒 Base de datos cerrada');
      }
    } catch (e) {
      print('❌ Error cerrando base de datos: $e');
    }
  }

  /// Limpiar todas las tablas
  static Future<void> clearAllTables() async {
    try {
      final db = await database;
      
      print('🧹 Limpiando todas las tablas...');
      
      // Deshabilitar foreign keys temporalmente
      await db.execute('PRAGMA foreign_keys = OFF');
      
      // Limpiar todas las tablas
      final tables = [
        'productos_segundo_conteo',
        'segundo_conteos',
        'productos_conteo',
        'conteos',
        'productos_vh',
        'vh_programados',
        'skus',
        'flota',
        'verificadores',
        'auxiliares',
        'configuracion',
      ];
      
      for (String table in tables) {
        await db.execute('DELETE FROM $table');
      }
      
      // Rehabilitar foreign keys
      await db.execute('PRAGMA foreign_keys = ON');
      
      print('✅ Todas las tablas limpiadas exitosamente');
    } catch (e) {
      print('❌ Error limpiando tablas: $e');
      rethrow;
    }
  }

  /// Obtener estadísticas de la base de datos
  static Future<Map<String, int>> getTableCounts() async {
    try {
      final db = await database;
      final Map<String, int> counts = {};

      final tables = [
        'verificadores',
        'flota',
        'vh_programados',
        'productos_vh',
        'skus',
        'conteos',
        'productos_conteo',
        'segundo_conteos',
        'productos_segundo_conteo',
        'auxiliares',
        'configuracion',
      ];

      for (String table in tables) {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
        counts[table] = result.first['count'] as int;
      }

      return counts;
    } catch (e) {
      print('❌ Error obteniendo estadísticas de tablas: $e');
      return {};
    }
  }
}
