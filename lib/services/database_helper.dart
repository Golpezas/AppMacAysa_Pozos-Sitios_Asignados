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

    if (!await File(path).exists()) {
      await Directory(dirname(path)).create(recursive: true);
      final data = await rootBundle.load('assets/$filePath');
      final bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes, flush: true);
    }
    return await openDatabase(path, version: 1);
  }

  Future<List<Site>> getSites({String query = '', int page = 1, int perPage = 20}) async {
    final db = await database;
    final offset = (page - 1) * perPage;
    final result = await db.query(
      'Sites',
      where: query.isNotEmpty ? 'name LIKE ? OR address LIKE ?' : null,
      whereArgs: query.isNotEmpty ? ['%$query%', '%$query%'] : null,
      limit: perPage,
      offset: offset,
    );
    return result.map((json) => Site.fromMap(json)).toList();
  }

  Future<List<Well>> getWells({String query = '', int page = 1, int perPage = 20}) async {
    final db = await database;
    final offset = (page - 1) * perPage;
    final result = await db.query(
      'Wells',
      where: query.isNotEmpty ? 'name LIKE ? OR address LIKE ?' : null,
      whereArgs: query.isNotEmpty ? ['%$query%', '%$query%'] : null,
      limit: perPage,
      offset: offset,
    );
    return result.map((json) => Well.fromMap(json)).toList();
  }

  Future<MobileUnit?> getMobileUnit(int id) async {
    final db = await database;
    final result = await db.query(
      'MobileUnits',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? MobileUnit.fromMap(result.first) : null;
  }

  Future<int> getSitesCount({String query = ''}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM Sites WHERE name LIKE ? OR address LIKE ?', 
      ['%$query%', '%$query%']
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getWellsCount({String query = ''}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM Wells WHERE name LIKE ? OR address LIKE ?', 
      ['%$query%', '%$query%']
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}