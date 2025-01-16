import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutterquiz/model/drug.dart';'; // Replace with your actual model file path

class DrugDatabase {
  static final DrugDatabase instance = DrugDatabase._init();
  static Database? _database;

  DrugDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('drugs.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE drugs (
        id INTEGER PRIMARY KEY,
        trade_name TEXT,
        generic_name TEXT,
        pharmacology TEXT,
        arabic_name TEXT,
        price REAL,
        company TEXT,
        description TEXT,
        route TEXT
      )
    ''');
  }

  Future<void> insertDrugs(List<Drug> drugs) async {
    final db = await instance.database;

    for (var drug in drugs) {
      await db.insert(
        'drugs',
        drug.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Drug>> fetchDrugsFromDB() async {
    final db = await instance.database;
    final result = await db.query('drugs');

    return result.map((json) => Drug.fromJson(json)).toList();
  }

  Future<void> close() async {
    final db = await _database;
    db?.close();
  }
}
