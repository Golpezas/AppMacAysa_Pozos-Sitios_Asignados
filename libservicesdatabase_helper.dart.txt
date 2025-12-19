import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('service_db.sqlite');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Copia la base de datos de los assets si no existe
    if (!await File(path).exists()) {
      await Directory(dirname(path)).create(recursive: true);
      final data = await rootBundle.load('assets/$filePath');
      final bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes, flush: true);
    }
    return await openDatabase(path, version: 1);
  }

  // --- MÉTODOS DE BÚSQUEDA Y PAGINACIÓN ACTUALIZADOS ---
  
  Future<List<Site>> getSites({String query = '', int page = 1, int perPage = 20}) async {
    final db = await database;
    final offset = (page - 1) * perPage;
    
    // 1. Convertir el query a minúsculas y añadir comodines.
    final lowerQuery = query.isNotEmpty ? '%${query.toLowerCase()}%' : null;
    
    final result = await db.query(
      'Sites',
      // 2. Usar LOWER() en las columnas para hacer la búsqueda insensible a mayúsculas.
      where: query.isNotEmpty 
          ? 'LOWER(name) LIKE ? OR LOWER(address) LIKE ?' 
          : null,
      whereArgs: query.isNotEmpty ? [lowerQuery, lowerQuery] : null,
      limit: perPage,
      offset: offset,
    );
    return result.map((json) => Site.fromMap(json)).toList();
  }

  Future<List<Well>> getWells({String query = '', int page = 1, int perPage = 20}) async {
    final db = await database;
    final offset = (page - 1) * perPage;
    
    // 1. Convertir el query a minúsculas y añadir comodines.
    final lowerQuery = query.isNotEmpty ? '%${query.toLowerCase()}%' : null;
    
    final result = await db.query(
      'Wells',
      // 2. Usar LOWER() en las columnas para hacer la búsqueda insensible a mayúsculas.
      where: query.isNotEmpty 
          ? 'LOWER(name) LIKE ? OR LOWER(address) LIKE ?' 
          : null,
      whereArgs: query.isNotEmpty ? [lowerQuery, lowerQuery] : null,
      limit: perPage,
      offset: offset,
    );
    return result.map((json) => Well.fromMap(json)).toList();
  }

  Future<int> getSitesCount({String query = ''}) async {
    final db = await database;
    
    // 1. Convertir el query a minúsculas y añadir comodines.
    final lowerQuery = query.isNotEmpty ? '%${query.toLowerCase()}%' : '';

    final result = await db.rawQuery(
      // 2. Usar LOWER() para el conteo de resultados filtrados.
      'SELECT COUNT(*) FROM Sites WHERE LOWER(name) LIKE ? OR LOWER(address) LIKE ?', 
      [lowerQuery, lowerQuery]
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getWellsCount({String query = ''}) async {
    final db = await database;
    
    // 1. Convertir el query a minúsculas y añadir comodines.
    final lowerQuery = query.isNotEmpty ? '%${query.toLowerCase()}%' : '';

    final result = await db.rawQuery(
      // 2. Usar LOWER() para el conteo de resultados filtrados.
      'SELECT COUNT(*) FROM Wells WHERE LOWER(name) LIKE ? OR LOWER(address) LIKE ?', 
      [lowerQuery, lowerQuery]
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // --- MÉTODOS EXISTENTES SIN CAMBIOS ---

  Future<MobileUnit?> getMobileUnit(int id) async {
    final db = await database;
    final result = await db.query(
      'MobileUnits',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? MobileUnit.fromMap(result.first) : null;
  }
}